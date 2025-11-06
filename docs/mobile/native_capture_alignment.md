# Native Capture Alignment Plan

Goal: Bring the historical NativeScript Android camera spike and the CrewAI SwiftUI LiDAR capture work back into a unified cross-platform flow while keeping the NativeScript labs as the authoritative UX surface.

## Current Ingredients
- **NativeScript labs (shopper/brand)** – WebView containers with environment diagnostics; no first-class native capture today.
- **Android spike (pre-merge)** – Previously implemented camera capture with `android.hardware.Camera` → frame upload. Not currently wired into navigation (lives only in historic branches).
- **SwiftUI LiDAR app** – Fully functional depth-aware capture flow (`CameraSessionController`, `LiDARMeasurementCalculator`, `FitTwinAPI`).
- **FastAPI measurement service** – MediaPipe-based validation + recommendation endpoints (`POST /measurements/validate`, `/recommend`) plus provenance schema.

## Alignment Strategy
1. **Resurface Android capture inside NativeScript**
   - Recreate the camera module under `frontend/nativescript/shared/camera/android`.
   - Wrap CameraX + ML Kit (or ARCore Depth API) via NativeScript plugin; fall back to the legacy `android.hardware.Camera` spike while the new module bakes.
   - Expose unified TypeScript interface: `captureMeasurements(): Promise<CaptureResult>`.
2. **Wrap SwiftUI logic as NativeScript plugin**
   - Isolate reusable Swift classes (`LiDARCameraManager`, `CameraSessionController`, measurement calculator).
   - Build NativeScript iOS plugin (`@fittwin/camera-ios`) that surfaces the same interface as the Android module.
   - Keep the existing SwiftUI app as a playground/sample for QA.
3. **Update NativeScript labs**
   - Add a “Native Capture” entry point in both shopper and brand labs.
   - Invoke the platform plugin and post the resulting payload to the FastAPI measurement service.
   - Provide fallback toggles to stay on the WebView flow when native capture unavailable.
4. **Measurement payload parity**
   - Standardise JSON schema (body metrics, capture metadata) and document it in `services/python/measurement/backend/app/schemas`.
   - Ensure both plugins emit identical payloads.
5. **Testing & Observability**
   - Unit-test plugin interfaces with mocked camera outputs.
   - Extend NativeScript e2e suite to cover native capture stub.
   - Instrument analytics events (capture started/completed, errors).

## Immediate Tasks
- [ ] Recover or rewrite the Android NativeScript camera module (prefer CameraX) and integrate with labs.
- [ ] Package Swift capture components as a NativeScript plugin with TypeScript declarations.
- [ ] Define shared `CaptureResult` TypeScript type and FastAPI schema.
- [ ] Create lab UI for selecting native capture vs web capture.
- [ ] Update docs (`docs/mobile/android_camera.md`, `ios_capture_status.md`) with install/build instructions.

This plan keeps NativeScript as the authoritative UI, leverages the Swift LiDAR expertise, and sets the stage for a modern Android camera path without losing existing work.


### Restored artifacts (2025-11-06)
- Android ARCore bridge (`frontend/nativescript/shared/capture/android/arcoreBridge.ts`) now registers with the shared capture service, exposing ARCore bursts as `CaptureResult` metadata.
- Historic Kotlin/JS bridge (`nativeBridge.android.ts`) is referenced directly via this module so labs no longer depend on WebView injection.
- iOS Swift capture controllers (`CameraSessionController.swift`, `CapturedPhoto.swift`, `DeviceRequirementChecker.swift`, `FitTwinAPI.swift`, `LiDARMeasurementCalculator.swift`) and the NativeScript bridge (`mobile/platforms/ios/FitTwinLiDARBridge.swift`) are back in-tree.
- Shared capture service emits the documented measurement payload (captureId, platform, device model, depth flag) for backend validation.
- See `docs/mobile/capture_sources.md` for the cross-repo index so we avoid duplicating web or native work, and `docs/mobile/native_capture_qa.md` for the day-to-day validation steps.
