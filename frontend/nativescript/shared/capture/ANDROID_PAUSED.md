# Android Implementation - Paused

## Status: ⏸️ PAUSED

The Android measurement capture implementation has been **temporarily paused** to focus on iOS POC development and testing.

## What's Missing

### Required Implementation

**File**: `android/arcoreBridge.ts` (does not exist)

**Required Functions**:
```typescript
export function isArCoreSupported(): boolean;
export function ensureAndroidCameraPermission(): Promise<boolean>;
export function captureBurst(type: 'torso' | 'full'): Promise<MeasurementBurstPayload>;

export interface MeasurementBurstPayload {
  burstId: string;
  type: string;
  capturedAt: number;
  samples: Array<{
    rgbPlaceholder: string;
    distanceMeters?: number;
  }>;
}
```

### Implementation Approach

1. **ARCore Session Management**
   - Initialize ARCore session
   - Check device capabilities (ToF sensor support)
   - Handle session lifecycle

2. **Depth Capture**
   - Use ARCore Depth API
   - Capture depth maps from ToF sensor
   - Process point clouds

3. **Pose Estimation**
   - Integrate MediaPipe Pose or ML Kit
   - Extract 33 body landmarks
   - Calculate measurements from landmarks

4. **Measurement Calculation**
   - Reuse existing `MeasurementCalculator` logic
   - Adapt for Android coordinate system
   - Apply same calibration constants

## Current File Status

- ✅ `android.ts` → Renamed to `android.ts.paused`
- ❌ `android/arcoreBridge.ts` → Does not exist (needs creation)

## When to Resume

Resume Android implementation after:
1. ✅ iOS POC is tested and validated
2. ✅ Measurement algorithms are proven accurate
3. ✅ User feedback is incorporated
4. ✅ iOS is production-ready

## Estimated Effort

**Timeline**: 1-2 weeks  
**Complexity**: Medium-High

**Tasks**:
- [ ] Create `android/arcoreBridge.ts` module
- [ ] Implement ARCore session management
- [ ] Integrate depth capture API
- [ ] Add pose estimation (MediaPipe/ML Kit)
- [ ] Adapt measurement calculations
- [ ] Write unit tests
- [ ] Test on multiple Android devices (Pixel, Samsung, OnePlus)

## Reference Devices

**Recommended for Testing**:
- Google Pixel 4+ (ToF sensor)
- Samsung Galaxy S20+ (ToF sensor)
- OnePlus 8 Pro+ (ToF sensor)
- Any device with ARCore support

## Notes

- The iOS implementation serves as the reference architecture
- Android bridge should follow the same patterns as `ios/bridge.ts`
- Measurement algorithms are platform-agnostic (reusable)

---

**Last Updated**: 2025-11-08  
**Status**: Paused pending iOS validation
