# Measurement Payload Schema

Both NativeScript (Android/iOS) and the Swift capture app should emit the same JSON payload when submitting measurements to the FastAPI service (`POST /measurements/validate` / `recommend`).

```json
{
  "captureId": "uuid",
  "source": "native-camera|web|manual",
  "timestamp": "2025-11-06T12:34:56.000Z",
  "metrics": {
    "height_cm": 172,
    "weight_kg": 68,
    "waist_natural_cm": 74,
    "hip_low_cm": 96,
    "chest_cm": 94
  },
  "photos": [
    { "uri": "file:///path/front.jpg", "view": "front" }
  ],
  "depth": {
    "uri": "file:///path/depth.d"
  },
  "device": {
    "platform": "ios|android",
    "model": "iPhone16,2",
    "appVersion": "1.0.0"
  }
}
```

The FastAPI service (`services/python/measurement/backend/app/schemas/measurements.py`) remains the single source of truth. Update this document and the schema together whenever fields change.


## Native Payload Fields

Native Android/iOS capture wrappers now emit:

- `captureId`: deterministic burst or timestamp identifier
- `timestamp`: Unix epoch milliseconds when capture completed
- `platform`: `android` or `ios`
- `source`: always `native-camera` (web fallback continues to send `web`)
- `deviceModel` / `osVersion`: values from the NativeScript runtime (`Device.model`, `Device.osVersion`)
- `depthAvailable`: boolean flag for iOS LiDAR depth; Android bridge reports inferred depth via ARCore
- `burst`: Android ARCore burst payload (landmarks, depth estimates) for downstream ML debugging

Both platforms populate `photos` with `{ uri, view }` pairs, using NativeScript-accessible URIs (file paths or native:// stubs) that upstream workers translate before upload.

