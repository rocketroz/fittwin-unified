# Next Steps: Mac Integration Guide

## Overview

All changes have been successfully pushed to your GitHub repository at `https://github.com/rocketroz/fittwin-unified`. This guide provides step-by-step instructions for pulling these changes to your Mac and integrating them into your Xcode project.

## Quick Start (15 minutes)

### Step 1: Pull Changes from GitHub

Open Terminal on your Mac and run:

```bash
cd /Users/laura/Projects/fittwin-unified
git pull origin main
```

You should see output indicating the new files have been downloaded:
- `ios/FitTwinApp/FitTwinApp/MediaPipe/PoseDetector.swift`
- `ios/FitTwinApp/FitTwinApp/MediaPipe/MeasurementCalculator.swift`
- `ios/FitTwinApp/FitTwinApp/Camera/LiDARCameraManager.swift`
- `ios/FitTwinApp/FitTwinApp/Camera/CameraPreviewView.swift`
- `ios/FitTwinApp/FitTwinApp/CaptureFlow/CaptureFlowViewModel_Updated.swift`
- `ios/FitTwinApp/FitTwinApp/CaptureFlow/CaptureFlowView_Updated.swift`
- `docs/ios_lidar_implementation_guide.md`
- `docs/integration_checklist.md`
- `docs/measurement_formulas.md`
- `CHANGELOG.md`

### Step 2: Open Xcode Project

```bash
cd /Users/laura/Projects/fittwin-unified/FitTwinApp
open FitTwinApp.xcodeproj
```

### Step 3: Add New Files to Xcode

#### Create MediaPipe Group
1. In Xcode's Project Navigator, right-click on `FitTwinApp` folder
2. Select **New Group** → Name it `MediaPipe`
3. Right-click on the new `MediaPipe` group → **Add Files to "FitTwinApp"...**
4. Navigate to `/Users/laura/Projects/fittwin-unified/FitTwinApp/FitTwinApp/MediaPipe/`
5. Select both files:
   - `PoseDetector.swift`
   - `MeasurementCalculator.swift`
6. Ensure **"Copy items if needed"** is UNCHECKED (files are already in correct location)
7. Ensure **"Add to targets: FitTwinApp"** is CHECKED
8. Click **Add**

#### Create Camera Group
1. Right-click on `FitTwinApp` folder again
2. Select **New Group** → Name it `Camera`
3. Right-click on the new `Camera` group → **Add Files to "FitTwinApp"...**
4. Navigate to `/Users/laura/Projects/fittwin-unified/FitTwinApp/FitTwinApp/Camera/`
5. Select both files:
   - `LiDARCameraManager.swift`
   - `CameraPreviewView.swift`
6. Ensure **"Copy items if needed"** is UNCHECKED
7. Ensure **"Add to targets: FitTwinApp"** is CHECKED
8. Click **Add**

### Step 4: Replace Existing Files

#### Backup Current Files (Important!)
1. In Finder, navigate to `/Users/laura/Projects/fittwin-unified/FitTwinApp/CaptureFlow/`
2. Duplicate these files (⌘D):
   - `CaptureFlowViewModel.swift` → `CaptureFlowViewModel_Backup.swift`
   - `CaptureFlowView.swift` → `CaptureFlowView_Backup.swift`

#### Replace ViewModel
1. In Xcode, open `CaptureFlowViewModel.swift`
2. Open `CaptureFlowViewModel_Updated.swift` in another tab
3. Select all content in `_Updated` file (⌘A) and copy (⌘C)
4. Switch to `CaptureFlowViewModel.swift` tab
5. Select all (⌘A) and paste (⌘V)
6. Save (⌘S)

#### Replace View
1. In Xcode, open `CaptureFlowView.swift`
2. Open `CaptureFlowView_Updated.swift` in another tab
3. Select all content in `_Updated` file (⌘A) and copy (⌘C)
4. Switch to `CaptureFlowView.swift` tab
5. Select all (⌘A) and paste (⌘V)
6. Save (⌘S)

### Step 5: Update Info.plist

1. In Xcode Project Navigator, locate `Info.plist` under `Resources`
2. Right-click → **Open As** → **Source Code**
3. Add the following inside the `<dict>` tag:

```xml
<key>NSCameraUsageDescription</key>
<string>FitTwin needs camera access to capture your body measurements using LiDAR technology.</string>
```

4. Save (⌘S)

### Step 6: Build and Test

#### Clean Build
1. In Xcode menu: **Product** → **Clean Build Folder** (⇧⌘K)
2. Wait for cleaning to complete

#### Build Project
1. In Xcode menu: **Product** → **Build** (⌘B)
2. Check for compilation errors in the Issue Navigator
3. If errors appear, verify all files were added correctly

#### Test on Simulator (Quick Test)
1. Select an iPhone simulator (iPhone 14 Pro or later recommended)
2. Click **Run** (⌘R)
3. App should launch successfully
4. Navigate to capture flow
5. Note: LiDAR features will use fallback mode on simulator

#### Test on Physical Device (Full Test)
1. Connect iPhone 12 Pro or later via USB
2. Select your device in Xcode's device selector
3. Click **Run** (⌘R)
4. Grant camera permissions when prompted
5. Test the complete capture flow:
   - Tap "Start Capture"
   - Follow front view guidance (10s countdown)
   - Capture front photo
   - Follow side view guidance (5s countdown)
   - Capture side photo
   - Wait for processing
   - View measurement results

## Verification Checklist

After completing the steps above, verify:

- [ ] All new files appear in Xcode Project Navigator
- [ ] Project builds without errors (⌘B)
- [ ] App launches on simulator without crashing
- [ ] Camera permission prompt appears on first launch (physical device)
- [ ] Front capture works with 10-second countdown
- [ ] Side capture works with 5-second countdown
- [ ] Processing completes and shows measurements
- [ ] Backend API receives measurements (check terminal logs)

## Troubleshooting

### Build Errors

**Error: "Cannot find 'PoseDetector' in scope"**
- Solution: Ensure `PoseDetector.swift` is added to the FitTwinApp target
- Check: File Inspector → Target Membership → FitTwinApp should be checked

**Error: "Cannot find 'LiDARCameraManager' in scope"**
- Solution: Ensure `LiDARCameraManager.swift` is added to the FitTwinApp target
- Check: File Inspector → Target Membership → FitTwinApp should be checked

**Error: Multiple files with same name**
- Solution: Delete the `_Updated` files after copying their contents
- In Project Navigator, right-click → Delete → Move to Trash

### Runtime Errors

**"Camera access not authorized"**
- Solution: Check Info.plist has `NSCameraUsageDescription`
- Delete app from device and reinstall to trigger permission prompt

**"LiDAR sensor not available"**
- Expected on simulator and older devices
- App will use fallback camera without depth data
- For full testing, use iPhone 12 Pro or later

**"No person detected in image"**
- Ensure good lighting
- Stand 6-8 feet from camera
- Ensure full body is visible in frame

### Backend Connection Issues

**401 Unauthorized**
- Verify API key in `CaptureFlowViewModel.swift` matches backend `.env`
- Current API key: `7c4b71191d6026973900ac353d6d68ac5977836cc85710a04ccf3ba147db301e`

**Connection refused**
- Ensure backend is running: `uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload`
- Verify endpoint URL: `http://192.168.4.208:8000/api/measurements/validate`
- Check Mac's local IP hasn't changed

## Performance Expectations

When everything is working correctly, you should see:

- **Camera startup**: <1 second
- **Countdown display**: Real-time, smooth animation
- **Photo capture**: Instant
- **Pose detection**: 0.5-1 second per image
- **Measurement calculation**: <0.1 seconds
- **Backend validation**: 0.5-1 second
- **Total time**: ~2-3 seconds from capture to results

## Next Development Steps

After successful integration and testing:

1. **Accuracy Validation** (Week 1)
   - Test with multiple users
   - Compare with tape measure
   - Document accuracy percentages
   - Identify improvement areas

2. **User Experience Refinement** (Week 2)
   - Collect user feedback
   - Refine guidance text
   - Improve error messages
   - Add tutorial mode

3. **Feature Enhancements** (Weeks 3-4)
   - Add user height input
   - Implement pose quality checks
   - Add measurement history
   - Create export functionality

4. **Production Readiness** (Month 2)
   - Comprehensive testing
   - Performance optimization
   - Error tracking integration
   - App Store submission preparation

## Support Resources

### Documentation
- **Implementation Guide**: `docs/ios_lidar_implementation_guide.md`
- **Integration Checklist**: `docs/integration_checklist.md`
- **Measurement Formulas**: `docs/measurement_formulas.md`
- **Changelog**: `CHANGELOG.md`

### Code References
- **Apple Vision Framework**: https://developer.apple.com/documentation/vision
- **AVFoundation Depth**: https://developer.apple.com/documentation/avfoundation/avdepthdata
- **MediaPipe Pose**: https://ai.google.dev/edge/mediapipe/solutions/vision/pose_landmarker

### Getting Help
- Review troubleshooting section in `ios_lidar_implementation_guide.md`
- Check GitHub issues: https://github.com/rocketroz/fittwin-unified/issues
- Review backend logs for API errors
- Test with different lighting and distances

## Rollback Instructions

If you need to revert to the previous version:

```bash
cd /Users/laura/Projects/fittwin-unified/FitTwinApp/CaptureFlow

# Restore backups
cp CaptureFlowViewModel_Backup.swift CaptureFlowViewModel.swift
cp CaptureFlowView_Backup.swift CaptureFlowView.swift

# In Xcode:
# 1. Remove MediaPipe group (select → Delete → Remove References)
# 2. Remove Camera group (select → Delete → Remove References)
# 3. Product → Clean Build Folder
# 4. Product → Build
```

## Success Criteria

Integration is complete when:

✅ Project builds without errors  
✅ App runs on physical device  
✅ Camera captures front and side photos  
✅ Pose detection extracts landmarks  
✅ Measurements are calculated and displayed  
✅ Backend API receives and validates measurements  
✅ No crashes or memory leaks during testing  

## Estimated Time

- **Pull and setup**: 5 minutes
- **Add files to Xcode**: 10 minutes
- **Update Info.plist**: 2 minutes
- **Build and test**: 10 minutes
- **Full device testing**: 15 minutes

**Total**: ~40 minutes for complete integration and testing

---

**Ready to begin?** Start with Step 1 and work through each step carefully. The integration checklist provides even more detailed guidance if needed.

**Questions?** Review the implementation guide or check the troubleshooting sections.

**Good luck!** 🚀
