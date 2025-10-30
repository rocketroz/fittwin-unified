# FitTwin iOS LiDAR Integration Checklist

## Pre-Integration Checklist

- [ ] Backup current project to Git
- [ ] Verify Xcode version (14.0 or later recommended)
- [ ] Confirm target iOS version (15.0+ for best LiDAR support)
- [ ] Test backend API is running at http://192.168.4.208:8000
- [ ] Verify API key matches between iOS and backend

## File Integration Steps

### Phase 1: Add New Files (30 minutes)

#### 1.1 Create MediaPipe Group
- [ ] In Xcode, right-click `FitTwinApp` folder
- [ ] Select "New Group" → Name it "MediaPipe"
- [ ] Add `PoseDetector.swift` to MediaPipe group
- [ ] Add `MeasurementCalculator.swift` to MediaPipe group
- [ ] Verify files compile without errors

#### 1.2 Create Camera Group
- [ ] In Xcode, right-click `FitTwinApp` folder
- [ ] Select "New Group" → Name it "Camera"
- [ ] Add `LiDARCameraManager.swift` to Camera group
- [ ] Add `CameraPreviewView.swift` to Camera group
- [ ] Verify files compile without errors

### Phase 2: Update Existing Files (20 minutes)

#### 2.1 Backup Current Files
```bash
cd /Users/laura/Projects/fittwin-unified/FitTwinApp/CaptureFlow
cp CaptureFlowViewModel.swift CaptureFlowViewModel_Backup_$(date +%Y%m%d).swift
cp CaptureFlowView.swift CaptureFlowView_Backup_$(date +%Y%m%d).swift
```

- [ ] Backups created successfully

#### 2.2 Replace ViewModel
- [ ] Open `CaptureFlowViewModel.swift` in Xcode
- [ ] Replace entire contents with `CaptureFlowViewModel_Updated.swift`
- [ ] Update API endpoint if needed (line ~79)
- [ ] Update API key if needed (line ~80)
- [ ] Save and verify compilation

#### 2.3 Replace View
- [ ] Open `CaptureFlowView.swift` in Xcode
- [ ] Replace entire contents with `CaptureFlowView_Updated.swift`
- [ ] Save and verify compilation

### Phase 3: Update Project Configuration (10 minutes)

#### 3.1 Update Info.plist
- [ ] Open `Info.plist` in Xcode
- [ ] Add camera usage description:
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>FitTwin needs camera access to capture your body measurements using LiDAR technology.</string>
  ```
- [ ] Verify existing `NSAppTransportSecurity` settings are present

#### 3.2 Verify Build Settings
- [ ] Target iOS Deployment: 15.0 or later
- [ ] Swift Language Version: Swift 5
- [ ] Camera usage permission in capabilities

### Phase 4: Build and Test (30 minutes)

#### 4.1 Clean Build
- [ ] Product → Clean Build Folder (⇧⌘K)
- [ ] Product → Build (⌘B)
- [ ] Resolve any compilation errors

#### 4.2 Simulator Testing
- [ ] Run on iOS Simulator
- [ ] Verify app launches without crashes
- [ ] Navigate to capture flow
- [ ] Verify camera permission prompt appears
- [ ] Note: LiDAR features will use fallback on simulator

#### 4.3 Physical Device Testing (iPhone 12 Pro or later)
- [ ] Connect iPhone with LiDAR
- [ ] Run app on device
- [ ] Grant camera permissions
- [ ] Test front view capture:
  - [ ] Guidance text displays correctly
  - [ ] 10-second countdown works
  - [ ] Photo captures successfully
  - [ ] Depth data is captured (check logs)
- [ ] Test side view capture:
  - [ ] Guidance text displays correctly
  - [ ] 5-second countdown works
  - [ ] Photo captures successfully
- [ ] Test processing:
  - [ ] Processing indicator appears
  - [ ] Landmarks detected successfully
  - [ ] Measurements calculated
  - [ ] Results display correctly
- [ ] Test backend integration:
  - [ ] API request sent successfully
  - [ ] Backend returns 200 OK
  - [ ] Check backend logs for validation

#### 4.4 Error Handling Testing
- [ ] Test with poor lighting
- [ ] Test with user too close/far
- [ ] Test with user partially out of frame
- [ ] Test with backend offline
- [ ] Verify error messages are clear
- [ ] Verify "Capture Again" button works

### Phase 5: Code Review (15 minutes)

#### 5.1 Code Quality
- [ ] No force unwraps (!) except where safe
- [ ] Proper error handling with try/catch
- [ ] Memory management (@MainActor usage)
- [ ] No retain cycles in closures

#### 5.2 User Experience
- [ ] Guidance text is clear and helpful
- [ ] Countdown is visible and easy to read
- [ ] Loading states are intuitive
- [ ] Error messages are actionable

#### 5.3 Performance
- [ ] Camera session starts/stops properly
- [ ] No memory leaks during capture
- [ ] Processing completes in <5 seconds
- [ ] UI remains responsive during processing

### Phase 6: Documentation (10 minutes)

- [ ] Read `ios_lidar_implementation_guide.md`
- [ ] Understand data flow architecture
- [ ] Review measurement formulas in `measurement_formulas.md`
- [ ] Bookmark troubleshooting section

## Post-Integration Verification

### Functional Testing
- [ ] Complete capture flow works end-to-end
- [ ] Measurements are reasonable (not obviously wrong)
- [ ] Backend receives and validates measurements
- [ ] User can retry after errors
- [ ] App doesn't crash on edge cases

### Integration Testing
- [ ] iOS app communicates with backend
- [ ] API authentication works
- [ ] Measurements stored in Supabase (check database)
- [ ] Logs show successful processing

### User Acceptance Testing
- [ ] Test with real user (not developer)
- [ ] Verify instructions are clear
- [ ] Check measurement accuracy with tape measure
- [ ] Collect feedback on UX

## Known Limitations

- [ ] Aware: LiDAR requires iPhone 12 Pro or later
- [ ] Aware: Measurements use fixed reference height (170cm)
- [ ] Aware: Circumferences are estimated from 2D projections
- [ ] Aware: Accuracy depends on proper pose and lighting

## Rollback Plan

If integration fails:

```bash
# Restore backup files
cd /Users/laura/Projects/fittwin-unified/FitTwinApp/CaptureFlow
cp CaptureFlowViewModel_Backup_YYYYMMDD.swift CaptureFlowViewModel.swift
cp CaptureFlowView_Backup_YYYYMMDD.swift CaptureFlowView.swift

# Remove new files from Xcode
# - Delete MediaPipe group
# - Delete Camera group

# Rebuild project
# Product → Clean Build Folder
# Product → Build
```

## Success Criteria

Integration is successful when:

✅ App builds without errors  
✅ Camera capture works on physical device  
✅ Pose detection extracts landmarks  
✅ Measurements are calculated  
✅ Backend API receives measurements  
✅ User can complete full capture flow  
✅ Error handling works gracefully  
✅ No crashes or memory leaks  

## Next Steps After Integration

1. **Calibration Testing**
   - Test with multiple users
   - Compare with manual tape measurements
   - Calculate accuracy percentages
   - Document typical error ranges

2. **User Testing**
   - Recruit beta testers
   - Collect UX feedback
   - Identify pain points
   - Iterate on guidance text

3. **Performance Optimization**
   - Profile memory usage
   - Optimize image processing
   - Reduce API payload size
   - Improve processing speed

4. **Feature Enhancements**
   - Add user height input
   - Implement pose quality checks
   - Add measurement history
   - Create 3D avatar visualization

## Support Resources

- **Implementation Guide:** `docs/ios_lidar_implementation_guide.md`
- **Measurement Formulas:** `docs/measurement_formulas.md`
- **GitHub Repository:** https://github.com/rocketroz/fittwin-unified
- **Backend API Docs:** http://192.168.4.208:8000/docs

## Completion Sign-off

- [ ] All checklist items completed
- [ ] Testing passed on physical device
- [ ] Backend integration verified
- [ ] Documentation reviewed
- [ ] Ready for user testing

**Completed by:** _______________  
**Date:** _______________  
**Notes:** _______________

---

**Version:** 1.0  
**Last Updated:** October 30, 2025
