# Native Capture QA Checklist

Use this guide whenever we need to validate the Android ARCore bridge or the iOS LiDAR plugin inside the NativeScript labs. It keeps us honest about reusing the existing camera work and ensures the backend contract stays healthy.

## 0. Prerequisites

1. **Backend running**  
   ```bash
   cd services/python/measurement
   ./scripts/dev_server.sh  # or uvicorn backend.app.main:app --reload
   ```
2. **Environment**  
   - `NS_MEASUREMENTS_API_URL` (default `http://127.0.0.1:8000/api`)  
   - `NS_MEASUREMENTS_API_KEY` (matches `API_KEY` used by the FastAPI service)  
   - `NS_LAB_URL` / `NS_BRAND_URL` pointing at whichever AR lab you want to wrap.
3. **Device/emulator setup**  
   - Android Studio or Xcode installed.  
   - Physical device recommended for LiDAR (iPhone 12 Pro+) and ARCore validation.  
   - `adb reverse tcp:3000 tcp:3000` / `tcp:3001` / `tcp:3100` if testing on emulators against localhost.

## 1. Launch the labs

```bash
# Shopper
npm run ns:shopper:android   # or :ios

# Brand
npm run ns:brand:android     # or :ios
```

The “Native Capture” entry in each lab now calls the unified capture service.

## 2. Android flow

1. Open **Native Capture** in the shopper lab.
2. Tap **Start Capture**.
3. On a compatible device, verify:
   - Camera permission prompt appears once (handled by `ensureAndroidCameraPermission`).
   - Status transitions: `Capturing…` → `Submitting…` → backend result.
   - Submission summary displays the recommendation text returned by `/measurements/validate`.
4. On devices without ARCore, confirm the stub still submits (metadata shows `native://stub` URIs).
5. Tail the FastAPI logs – you should see the `captureId`/`platform=android` payload under `measurements_mediapipe`.

## 3. iOS flow

1. Build the restored Swift capture app via the NativeScript shell. Ensure `FitTwinLiDARBridge.swift` is included (Pods/Xcode target rebuild).
2. Tap **Start Capture** and follow the two-photo flow.  
   - Simulator uses fallback photos. Physical devices capture real LiDAR frames.
3. After capture:
   - Status shows “Submitting to measurement service…” then the backend summary.
   - Summary lists recommended size + confidence from `/measurements/validate`.
4. Confirm Info.plist contains `FITWIN_API_URL` if you override the default API host.

## 4. Regression checks

- Repeat the flow with the brand lab to ensure both apps pull from the same shared ViewModel.
- Disconnect the backend to verify the UI surfaces the server error message.
- Toggle `NS_MEASUREMENTS_API_KEY` to an invalid value and confirm 401s are surfaced cleanly.

## 5. Logging / follow-up

- Attach device logs (`adb logcat` / Xcode console) to any QA ticket so we can trace ARCore/LiDAR issues.
- If the backend rejects the payload, capture the exact JSON emitted from `frontend/nativescript/shared/capture/measurementClient.ts` for debugging.
- Keep `docs/mobile/capture_sources.md` updated whenever we discover additional Android/iOS/web capture artefacts worth reusing.
