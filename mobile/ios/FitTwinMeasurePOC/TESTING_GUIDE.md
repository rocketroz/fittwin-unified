# FitTwin iOS Measurement POC - Testing Guide

**Version**: 1.0  
**Branch**: `feature/ios-measurement-poc`  
**Last Updated**: 2025-11-09  
**Status**: Ready for Testing

---

## 📋 Overview

This guide provides comprehensive instructions for testing the FitTwin iOS measurement POC, which captures body measurements using LiDAR and camera, processes them through pose detection, and sends them to the Python measurement API for calculation.

---

## 🎯 What This POC Does

### **Capture Flow**
1. **Front Photo**: 10-second countdown → Auto-capture with LiDAR
2. **Rotation Prompt**: "Rotate 90° left"
3. **Side Photo**: 5-second countdown → Auto-capture with LiDAR
4. **Pose Detection**: Extract 33 body landmarks using Apple Vision
5. **API Call**: Send landmarks to Python measurement service
6. **Results**: Display 13 body measurements

### **Measurements Returned**
1. Height (cm)
2. Shoulder Width (cm)
3. Chest Circumference (cm)
4. Waist Circumference (cm)
5. Hip Circumference (cm)
6. Inseam (cm)
7. Outseam (cm)
8. Sleeve Length (cm)
9. Neck Circumference (cm)
10. Bicep Circumference (cm)
11. Forearm Circumference (cm)
12. Thigh Circumference (cm)
13. Calf Circumference (cm)

---

## 🔧 Prerequisites

### **Hardware**
- ✅ iPhone 12 Pro or newer (LiDAR required)
- ✅ Mac with Xcode 15+
- ✅ iPhone and Mac on same WiFi network

### **Software**
- ✅ macOS Ventura or newer
- ✅ Xcode 15.0+
- ✅ iOS 16.0+ on iPhone
- ✅ Python 3.11+ (for measurement service)

### **Repository**
```bash
git clone https://github.com/rocketroz/fittwin-unified.git
cd fittwin-unified
git checkout feature/ios-measurement-poc
```

---

## 🚀 Setup Instructions

### **Step 1: Start Python Measurement Service**

```bash
# Navigate to measurement service
cd services/python/measurement

# Run dev server (creates venv, installs deps, starts server)
./scripts/dev_server.sh
```

**Expected Output**:
```
🚀 Starting FitTwin Platform Development Server...
✅ Starting FastAPI server on http://localhost:8000
📚 API docs available at http://localhost:8000/docs
```

**Verify API is running**:
```bash
curl http://localhost:8000/docs
# Should return HTML of API documentation
```

---

### **Step 2: Get Your Mac's IP Address**

```bash
# On macOS
ipconfig getifaddr en0

# Example output: 192.168.1.100
```

**Note**: This IP is needed for iPhone to access the Python service running on your Mac.

---

### **Step 3: Configure iOS App**

**Edit**: `mobile/ios/FitTwinMeasurePOC/FitTwinMeasure/MeasurementViewModel.swift`

**Find** (lines 11-14):
```swift
private let pythonAPI = PythonMeasurementAPI(
    baseURL: "https://your-api-url.com",  // TODO: Replace with actual URL
    apiKey: "your-api-key"  // TODO: Replace with actual key
)
```

**Replace with**:
```swift
private let pythonAPI = PythonMeasurementAPI(
    baseURL: "http://192.168.1.100:8000",  // Your Mac's IP from Step 2
    apiKey: "staging-secret-key"           // Default API key from config.py
)
```

**Save the file**.

---

### **Step 4: Open Xcode Project**

```bash
cd mobile/ios/FitTwinMeasurePOC
open FitTwinMeasure.xcodeproj
```

**In Xcode**:
1. Select your iPhone from device dropdown
2. Click **Run** (⌘R) or press the play button
3. Wait for build to complete

---

### **Step 5: Grant Permissions**

**On iPhone**:
1. App will request **Camera** permission → Tap **Allow**
2. App will request **LiDAR** access → Tap **Allow**

---

## 🧪 Test Scenarios

### **Test 1: Basic Measurement Capture**

**Objective**: Verify full capture flow works end-to-end

**Steps**:
1. Tap **"Start Measurement"** button
2. Stand 6-8 feet from iPhone
3. Ensure full body is visible in frame
4. Wait for 10-second countdown (front photo)
5. Follow on-screen prompt to rotate 90° left
6. Wait for 5-second countdown (side photo)
7. Wait for processing (pose detection + API call)
8. View results screen

**Expected Results**:
- ✅ Camera preview shows full body
- ✅ Countdown displays correctly (10s → 0s, then 5s → 0s)
- ✅ Photos captured automatically
- ✅ Processing completes within 5-10 seconds
- ✅ Results show 13 measurements
- ✅ Measurements are reasonable (e.g., height 160-200cm)

**Log to Check** (Xcode Console):
```
🔍 Detecting pose in front image...
🔍 Detecting pose in side image...
✅ Pose detection complete
📤 Sending to Python API...
📤 API Request to /measurements/validate:
{"source_type":"mediapipe_ios",...}
📥 API Response (200):
{"valid":true,"measurements_cm":{...}}
✅ Received measurements from API
📊 Confidence: 0.92
```

---

### **Test 2: Accuracy Validation**

**Objective**: Compare app measurements to manual tape measurements

**Steps**:
1. Use tape measure to manually measure test subject:
   - Height
   - Chest circumference
   - Waist circumference
   - Hip circumference
   - Inseam
2. Run app measurement capture
3. Compare results

**Expected Results**:
- ✅ Height: ±2 cm accuracy
- ✅ Circumferences: ±3 cm accuracy
- ✅ Lengths: ±2 cm accuracy

**Record Results**:
| Measurement | Manual (cm) | App (cm) | Difference (cm) | Within Tolerance? |
|-------------|-------------|----------|-----------------|-------------------|
| Height | | | | |
| Chest | | | | |
| Waist | | | | |
| Hip | | | | |
| Inseam | | | | |

---

### **Test 3: Edge Cases**

#### **3a. Poor Lighting**
- Test in dim lighting
- **Expected**: Pose detection may fail or have low confidence

#### **3b. Partial Body Visible**
- Stand too close to camera
- **Expected**: Error message "No body detected"

#### **3c. Loose Clothing**
- Test with baggy clothes vs. fitted clothes
- **Expected**: Measurements may be less accurate with loose clothing

#### **3d. Multiple People in Frame**
- Have 2+ people in camera view
- **Expected**: May detect wrong person or fail

#### **3e. Network Failure**
- Turn off WiFi during processing
- **Expected**: Error message "Measurement failed: ..."

---

### **Test 4: Repeatability**

**Objective**: Verify consistent measurements across multiple captures

**Steps**:
1. Capture measurements 3 times without moving
2. Compare results

**Expected Results**:
- ✅ Height variance: ±1 cm
- ✅ Circumferences variance: ±2 cm
- ✅ Lengths variance: ±1 cm

**Record Results**:
| Measurement | Run 1 | Run 2 | Run 3 | Std Dev | Acceptable? |
|-------------|-------|-------|-------|---------|-------------|
| Height | | | | | |
| Chest | | | | | |
| Waist | | | | | |

---

### **Test 5: Different Body Types**

**Objective**: Test with various body shapes and sizes

**Test Subjects**:
- [ ] Tall person (>180cm)
- [ ] Short person (<160cm)
- [ ] Athletic build
- [ ] Plus-size
- [ ] Child (if appropriate)

**Expected Results**:
- ✅ All body types detected successfully
- ✅ Measurements scale appropriately

---

## 🐛 Troubleshooting

### **Issue: "Camera permission denied"**

**Solution**:
1. Go to iPhone **Settings** → **Privacy & Security** → **Camera**
2. Find **FitTwinMeasure** and toggle **ON**
3. Restart app

---

### **Issue: "No body detected"**

**Possible Causes**:
- Body not fully visible in frame
- Too close to camera
- Poor lighting

**Solution**:
- Stand 6-8 feet from camera
- Ensure full body visible (head to feet)
- Improve lighting
- Try again

---

### **Issue: "Measurement failed: Server error (500)"**

**Possible Causes**:
- Python service not running
- Wrong API URL or key
- Network connectivity issue

**Solution**:
1. Check Python service is running:
   ```bash
   curl http://localhost:8000/docs
   ```
2. Verify IP address in `MeasurementViewModel.swift`
3. Check iPhone and Mac are on same WiFi
4. Check Xcode console for detailed error

---

### **Issue: Build fails in Xcode**

**Possible Causes**:
- Missing Swift files
- Wrong iOS deployment target

**Solution**:
1. Clean build folder: **Product** → **Clean Build Folder** (⇧⌘K)
2. Verify all 7 Swift files are in project:
   - FitTwinMeasureApp.swift
   - ContentView.swift
   - MeasurementViewModel.swift
   - MeasurementCalculator.swift
   - LiDARCameraManager.swift
   - MediaPipePoseDetector.swift
   - PythonMeasurementAPI.swift
3. Check deployment target is iOS 16.0+
4. Rebuild

---

### **Issue: Measurements seem inaccurate**

**Possible Causes**:
- Loose clothing
- Poor pose detection
- Calibration needed

**Solution**:
1. Wear fitted clothing
2. Ensure good lighting
3. Stand in proper pose (arms slightly away from body)
4. Check pose detection confidence in logs
5. If consistently off, calibration constants may need adjustment in Python service

---

## 📊 Test Results Template

### **Test Session Information**

**Date**: ___________  
**Tester**: ___________  
**iPhone Model**: ___________  
**iOS Version**: ___________  
**Test Subject**: ___________ (height, build)  
**Lighting Conditions**: ___________ (bright/normal/dim)  
**Clothing**: ___________ (fitted/loose)  

---

### **Test Results**

#### **Capture Flow**
- [ ] Camera permission granted
- [ ] Front capture (10s countdown) ✅ / ❌
- [ ] Rotation prompt displayed ✅ / ❌
- [ ] Side capture (5s countdown) ✅ / ❌
- [ ] Processing completed ✅ / ❌
- [ ] Results displayed ✅ / ❌

**Time to Complete**: _______ seconds

---

#### **Measurements**

| Measurement | Manual (cm) | App (cm) | Diff (cm) | % Error | Pass/Fail |
|-------------|-------------|----------|-----------|---------|-----------|
| Height | | | | | |
| Shoulder | | | | | |
| Chest | | | | | |
| Waist | | | | | |
| Hip | | | | | |
| Inseam | | | | | |
| Outseam | | | | | |
| Sleeve | | | | | |
| Neck | | | | | |
| Bicep | | | | | |
| Forearm | | | | | |
| Thigh | | | | | |
| Calf | | | | | |

**Overall Accuracy**: _______ %  
**Confidence Score** (from API): _______

---

#### **Issues Encountered**

1. Issue: ___________  
   Severity: High / Medium / Low  
   Resolved: Yes / No  
   Notes: ___________

2. Issue: ___________  
   Severity: High / Medium / Low  
   Resolved: Yes / No  
   Notes: ___________

---

#### **User Experience**

**Ease of Use** (1-5): _____  
**Clarity of Instructions** (1-5): _____  
**Speed** (1-5): _____  
**Overall Satisfaction** (1-5): _____

**Comments**:
___________

---

## 📝 Reporting Issues

When reporting issues, please include:

1. **Test session date/time**
2. **iPhone model and iOS version**
3. **Steps to reproduce**
4. **Expected vs. actual behavior**
5. **Xcode console logs** (copy relevant sections)
6. **Screenshots** (if applicable)
7. **Test subject characteristics** (height, build, clothing)

**Submit issues to**: [GitHub Issues](https://github.com/rocketroz/fittwin-unified/issues)

---

## 🎯 Success Criteria

### **Minimum Viable POC**
- [x] Captures front + side photos with LiDAR
- [x] Extracts 33 body landmarks
- [x] Sends to Python API
- [x] Returns 13 measurements
- [x] Displays results

### **Production Ready** (Future)
- [ ] Accuracy: ±2cm for height, ±3cm for circumferences
- [ ] Repeatability: <2cm variance across 3 runs
- [ ] Success rate: >90% for well-lit, properly framed captures
- [ ] Processing time: <10 seconds end-to-end
- [ ] Works with various body types and clothing

---

## 📚 Additional Resources

- **MEDIAPIPE_INTEGRATION.md** - Technical implementation details
- **ALGORITHMS.md** - Measurement calculation formulas
- **README.md** - Project overview and quick start
- **QUICKSTART.md** - 5-minute setup guide

---

## 🔄 Next Steps After Testing

1. **Record all test results** in CHANGELOG.md
2. **Report critical issues** on GitHub
3. **Suggest improvements** based on user experience
4. **Validate accuracy** against tape measurements
5. **Test with diverse subjects** (different body types)
6. **Iterate on calibration** if measurements consistently off

---

**Happy Testing!** 🚀
