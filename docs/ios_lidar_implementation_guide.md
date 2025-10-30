# iOS LiDAR & MediaPipe Implementation Guide

## Overview

This guide provides step-by-step instructions for integrating the new LiDAR capture and MediaPipe pose detection components into the existing FitTwin iOS app.

## What's Been Implemented

### 1. Core Components Created

#### **PoseDetector.swift** (`/MediaPipe/PoseDetector.swift`)
- Uses Apple's Vision framework as a MediaPipe-compatible alternative
- Extracts 33 body landmarks matching MediaPipe Pose format
- Integrates depth data from LiDAR to enhance 2D landmarks with Z-coordinates
- Provides confidence scores (visibility) for each landmark

#### **MeasurementCalculator.swift** (`/MediaPipe/MeasurementCalculator.swift`)
- Calculates 13 body measurements from landmarks
- Implements formulas from `docs/measurement_formulas.md`
- Supports both front-only and front+side view measurements
- Uses Ramanujan's ellipse approximation for circumferences

#### **LiDARCameraManager.swift** (`/Camera/LiDARCameraManager.swift`)
- Manages AVFoundation camera session with depth data capture
- Supports countdown timer (10s for front, 5s for side)
- Captures high-quality photos with LiDAR depth maps
- Handles camera permissions and device compatibility

#### **CameraPreviewView.swift** (`/Camera/CameraPreviewView.swift`)
- SwiftUI wrapper for camera preview layer
- Full-screen camera capture UI with guidance overlays
- Visual countdown display
- Body outline guides for proper positioning

#### **Updated ViewModels and Views**
- `CaptureFlowViewModel_Updated.swift`: Integrates all components into capture pipeline
- `CaptureFlowView_Updated.swift`: Updated UI with camera integration

## Integration Steps

### Step 1: Add Files to Xcode Project

1. Open `FitTwinApp.xcodeproj` in Xcode
2. Create new groups:
   - `MediaPipe` (for pose detection and measurement calculation)
   - `Camera` (for camera management and preview)
3. Add the following files to your project:

```
FitTwinApp/
├── MediaPipe/
│   ├── PoseDetector.swift
│   └── MeasurementCalculator.swift
├── Camera/
│   ├── LiDARCameraManager.swift
│   └── CameraPreviewView.swift
└── CaptureFlow/
    ├── CaptureFlowViewModel.swift (replace with _Updated version)
    └── CaptureFlowView.swift (replace with _Updated version)
```

### Step 2: Update Info.plist

Add camera usage description:

```xml
<key>NSCameraUsageDescription</key>
<string>FitTwin needs camera access to capture your body measurements using LiDAR technology.</string>
```

### Step 3: Replace Existing Files

1. **Backup current files:**
   ```bash
   cd /Users/laura/Projects/fittwin-unified/FitTwinApp/CaptureFlow
   cp CaptureFlowViewModel.swift CaptureFlowViewModel_Backup.swift
   cp CaptureFlowView.swift CaptureFlowView_Backup.swift
   ```

2. **Replace with updated versions:**
   - Replace `CaptureFlowViewModel.swift` with contents of `CaptureFlowViewModel_Updated.swift`
   - Replace `CaptureFlowView.swift` with contents of `CaptureFlowView_Updated.swift`

### Step 4: Update Backend API Endpoint (if needed)

In `CaptureFlowViewModel.swift`, verify the API endpoint matches your backend:

```swift
let endpoint = "http://192.168.4.208:8000/api/measurements/validate"
let apiKey = "7c4b71191d6026973900ac353d6d68ac5977836cc85710a04ccf3ba147db301e"
```

### Step 5: Build and Test

1. **Build the project:**
   ```bash
   # In Xcode: Product → Build (⌘B)
   ```

2. **Test on physical device:**
   - LiDAR requires iPhone 12 Pro or later
   - iOS Simulator will use fallback camera without depth data

3. **Test the capture flow:**
   - Launch app and navigate to capture flow
   - Tap "Start Capture"
   - Follow on-screen guidance for front view (10s countdown)
   - Turn left for side view (5s countdown)
   - Wait for processing and measurement display

## Architecture Overview

### Data Flow

```
User Interaction
    ↓
CaptureFlowView (UI)
    ↓
CaptureFlowViewModel (Orchestration)
    ↓
┌─────────────────┬──────────────────┬─────────────────┐
│                 │                  │                 │
LiDARCameraManager  PoseDetector  MeasurementCalculator
    ↓                   ↓                  ↓
Captured Images    Body Landmarks    Measurements
    ↓                   ↓                  ↓
    └───────────────────┴──────────────────┘
                        ↓
                Backend API (Validation)
```

### Component Responsibilities

| Component | Responsibility |
|-----------|---------------|
| **CaptureFlowView** | User interface, navigation, state display |
| **CaptureFlowViewModel** | Business logic, state management, API communication |
| **LiDARCameraManager** | Camera session, photo capture, depth data |
| **CameraPreviewView** | Camera preview UI, guidance overlays |
| **PoseDetector** | Landmark extraction using Vision framework |
| **MeasurementCalculator** | Measurement calculation from landmarks |

## Key Features

### 1. LiDAR Depth Capture
- Captures RGB images with depth maps
- Enhances 2D landmarks with real-world depth (Z-axis)
- Improves measurement accuracy for circumferences

### 2. Pose Detection
- Uses Apple Vision framework (native, no external dependencies)
- Detects 33 body landmarks compatible with MediaPipe format
- Provides confidence scores for quality assessment

### 3. Measurement Calculation
- **Primary measurements:** Height, chest, waist, hip, inseam
- **Additional measurements:** Shoulder width, sleeve length, neck, bicep, forearm, thigh, calf
- **Accuracy:** Based on validated anthropometric formulas

### 4. User Experience
- **Guided capture:** On-screen instructions and visual guides
- **Countdown timers:** 10s for front view, 5s for side view
- **Automatic progression:** Front → Side → Processing → Results
- **Error handling:** Clear error messages and retry options

## Testing Checklist

- [ ] Camera permission prompt appears on first launch
- [ ] Front view guidance displays correctly
- [ ] 10-second countdown works for front capture
- [ ] Side view guidance displays after front capture
- [ ] 5-second countdown works for side capture
- [ ] Processing indicator shows during landmark detection
- [ ] Measurements display after successful processing
- [ ] Backend API receives measurements (check logs)
- [ ] Error handling works for failed captures
- [ ] "Capture Again" button resets the flow

## Troubleshooting

### Issue: "LiDAR sensor not available"
**Solution:** Test on iPhone 12 Pro or later. Simulator will use fallback camera.

### Issue: "No person detected in image"
**Solution:** Ensure user is:
- Standing 6-8 feet from camera
- Fully visible in frame
- In well-lit environment
- Facing camera (front view) or turned 90° left (side view)

### Issue: Backend API returns 401 Unauthorized
**Solution:** Verify API key matches in:
- `CaptureFlowViewModel.swift` (iOS)
- `.env` file (Backend)

### Issue: Measurements seem inaccurate
**Solution:** 
- Verify user is standing at correct distance
- Check that depth data is being captured (requires LiDAR device)
- Consider implementing user height input for better scaling

## Performance Considerations

### Memory Management
- Images are captured at high quality (can be large)
- Depth data adds additional memory overhead
- Consider implementing image compression for API upload

### Processing Time
- Pose detection: ~0.5-1s per image
- Measurement calculation: <0.1s
- Backend validation: ~0.5-1s (network dependent)
- **Total:** ~2-3s from capture to results

### Battery Impact
- Camera session uses significant power
- Stop session when not in use (handled automatically)
- LiDAR adds minimal additional power consumption

## Future Enhancements

### Short-term
1. **User height input:** Allow users to provide actual height for better scaling
2. **Image compression:** Reduce file sizes before backend upload
3. **Offline mode:** Cache measurements locally before sync
4. **Progress indicators:** Show detailed processing steps

### Medium-term
1. **Pose quality checks:** Validate pose before capture (arms position, distance, etc.)
2. **Multi-language support:** Localize guidance text
3. **Accessibility:** VoiceOver support for guidance
4. **Tutorial mode:** First-time user walkthrough

### Long-term
1. **Machine learning refinement:** Train custom model on real measurement data
2. **Body type detection:** Adjust formulas based on detected body type
3. **3D avatar generation:** Create visual representation from measurements
4. **Garment recommendations:** Suggest sizes based on measurements

## API Integration Details

### Request Format

```json
{
  "measurements": {
    "height": 175.5,
    "shoulder_width": 45.2,
    "chest": 95.0,
    "waist": 80.0,
    "hip": 98.5,
    "inseam": 78.0,
    "outseam": 102.0,
    "sleeve_length": 60.5,
    "neck": 18.1,
    "bicep": 13.6,
    "forearm": 10.2,
    "thigh": 24.5,
    "calf": 10.2
  },
  "metadata": {
    "capture_method": "lidar",
    "has_depth_data": true,
    "has_side_view": true,
    "timestamp": "2025-10-30T12:34:56Z"
  }
}
```

### Response Format

```json
{
  "status": "success",
  "validation": {
    "is_valid": true,
    "accuracy_estimate": 95,
    "warnings": []
  },
  "measurements_id": "uuid-here"
}
```

## References

- [MediaPipe Pose Documentation](https://ai.google.dev/edge/mediapipe/solutions/vision/pose_landmarker)
- [Apple Vision Framework](https://developer.apple.com/documentation/vision)
- [AVFoundation Depth Data](https://developer.apple.com/documentation/avfoundation/avdepthdata)
- [Measurement Formulas](./measurement_formulas.md)

## Support

For questions or issues:
1. Check existing GitHub issues: https://github.com/rocketroz/fittwin-unified/issues
2. Review backend logs for API errors
3. Test with different lighting conditions and distances
4. Verify device compatibility (LiDAR requires iPhone 12 Pro+)

---

**Last Updated:** October 30, 2025  
**Version:** 1.0  
**Author:** FitTwin Development Team
