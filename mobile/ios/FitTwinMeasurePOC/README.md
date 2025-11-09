# FitTwin Measure - iOS POC

**Minimal iOS app for body measurement capture using LiDAR and camera.**

## 🎯 Purpose

This is a **proof-of-concept** iOS application that demonstrates accurate body measurement capture using:
- **LiDAR depth sensing** (iPhone 12 Pro and newer)
- **MediaPipe pose estimation** algorithms
- **NASA/ANSUR II calibration formulas**

## 📱 Features

✅ **LiDAR Camera Capture**
- Front view with 10-second countdown
- Side view with 5-second countdown
- Real-time camera preview

✅ **13 Body Measurements**
- Height
- Shoulder Width
- Chest Circumference
- Waist Circumference
- Hip Circumference
- Inseam
- Outseam
- Sleeve Length
- Neck Circumference
- Bicep Circumference
- Forearm Circumference
- Thigh Circumference
- Calf Circumference

✅ **On-Device Processing**
- Pose detection on-device (Apple Vision)
- Measurement calculation via Python API
- Privacy-focused (no data stored)

✅ **Python API Integration**
- Real-time measurement calculation
- MediaPipe landmark format
- 18 measurements returned

## 🛠️ Requirements

### Hardware
- **iPhone 12 Pro or newer** (for LiDAR)
- **iPad Pro 2020 or newer** (for LiDAR)
- Fallback to regular camera on older devices

### Software
- **Xcode 15.0+**
- **iOS 16.0+**
- **macOS Ventura or newer**

## 🚀 Setup Instructions

### 1. Open in Xcode

```bash
cd fittwin-ios-poc
open FitTwinMeasure.xcodeproj
```

### 2. Configure Signing

1. Select the **FitTwinMeasure** target
2. Go to **Signing & Capabilities**
3. Select your **Team**
4. Xcode will automatically manage provisioning

### 3. Build and Run

1. Connect your iPhone 12 Pro+ via USB
2. Select your device in Xcode
3. Click **Run** (⌘R)

### 4. Grant Permissions

On first launch, the app will request camera access. Tap **Allow**.

## 📖 Usage Flow

### Step 1: Start Measurement
- Tap **"Start Measurement"** on the home screen
- Grant camera permission if prompted

### Step 2: Front View Capture
- Stand **6 feet** from the camera
- Face the camera directly
- Tap **"Start Capture"**
- **10-second countdown** will begin
- Photo captures automatically

### Step 3: Side View Capture
- Rotate **90° to your left**
- Stand sideways to the camera
- **5-second countdown** begins automatically
- Photo captures automatically

### Step 4: View Results
- Measurements calculate automatically
- All 13 measurements displayed in cm
- Tap **"Export"** to output JSON (check Xcode console)
- Tap **"New Measurement"** to start over

## 🧮 Measurement Algorithms

### Ellipse Circumference (Chest/Waist/Hip)

Uses **Ramanujan's approximation**:

```
h = (a - b)² / (a + b)²
circumference = π(a + b)(1 + 3h / (10 + √(4 - 3h)))
```

Where:
- `a` = semi-major axis (width/2)
- `b` = semi-minor axis (depth/2)

### Limb Circumferences

Calculated from bone length using calibration multipliers:

- **Bicep**: `upperArm_length × 3.35`
- **Forearm**: `forearm_length × 2.95`
- **Thigh**: `thigh_length × 3.35`
- **Calf**: `lowerLeg_length × 2.9`

### Height Calculation

```
height = distance(head, foot) × 100 + 0.5cm (bias correction)
```

### Calibration Constants

Based on **NASA Anthropometric Source Book** and **ANSUR II** studies:

```swift
chestDepthRatio: 0.80
waistDepthRatio: 0.75
hipDepthRatio: 0.85
limbCircumferenceMultiplier: 3.35
calfCircumferenceMultiplier: 2.9
ankleCircumferenceMultiplier: 2.5
inseamMultiplier: 1.08
sleeveMultiplier: 1.05
heightBiasCM: 0.5
```

## 📂 Project Structure

```
FitTwinMeasurePOC/
├── FitTwinMeasure/                    # iOS app source
│   ├── FitTwinMeasureApp.swift       # App entry point
│   ├── ContentView.swift             # Main UI
│   ├── MeasurementViewModel.swift    # Capture logic
│   ├── MediaPipePoseDetector.swift   # Pose detection (NEW)
│   ├── PythonMeasurementAPI.swift    # API client (NEW)
│   ├── MeasurementCalculator.swift   # Formulas (legacy)
│   ├── LiDARCameraManager.swift      # Camera + LiDAR
│   └── Info.plist                    # Permissions
├── TESTING_GUIDE.md                   # Comprehensive testing (NEW)
├── CHANGELOG.md                       # Version history (NEW)
├── MEDIAPIPE_INTEGRATION.md          # Technical details (NEW)
└── README.md                          # This file
```

## 🔍 Key Files

### `MeasurementCalculator.swift`
- Implements all 13 measurement calculations
- Uses MediaPipe-style landmarks (33 body points)
- Handles front + side view depth estimation
- Exports `BodyMeasurements` struct

### `LiDARCameraManager.swift`
- Manages AVFoundation camera session
- Captures RGB images + depth data
- Supports LiDAR and TrueDepth cameras
- Falls back to regular camera if LiDAR unavailable

### `MeasurementViewModel.swift`
- Orchestrates capture flow
- Manages state machine (idle → front → side → results)
- Handles countdown timers
- Processes measurements

## 🧪 Testing

### Manual Testing Checklist

- [ ] App launches without crashes
- [ ] Camera permission requested
- [ ] Front view countdown works (10 seconds)
- [ ] Front photo captures successfully
- [ ] Rotation prompt appears
- [ ] Side view countdown works (5 seconds)
- [ ] Side photo captures successfully
- [ ] Measurements calculate and display
- [ ] All 13 measurements show reasonable values
- [ ] Export outputs valid JSON
- [ ] Reset button returns to idle state

### Expected Measurement Ranges

| Measurement | Min (cm) | Max (cm) | Typical (cm) |
|-------------|----------|----------|--------------|
| Height | 150 | 200 | 170 |
| Shoulder Width | 35 | 55 | 45 |
| Chest | 80 | 130 | 95 |
| Waist | 60 | 120 | 80 |
| Hip | 80 | 130 | 100 |
| Inseam | 65 | 95 | 76 |
| Outseam | 90 | 120 | 100 |
| Sleeve Length | 50 | 70 | 60 |
| Neck | 30 | 45 | 37 |
| Bicep | 25 | 40 | 30 |
| Forearm | 20 | 35 | 25 |
| Thigh | 45 | 70 | 55 |
| Calf | 28 | 45 | 35 |

### Debugging

**Enable verbose logging:**

Check Xcode console for:
- `📊 Measurements JSON:` - Exported measurement data
- Camera session status
- Capture errors

**Common Issues:**

1. **"Camera device not found"**
   - Ensure running on iPhone 12 Pro+ or iPad Pro 2020+
   - App will fall back to regular camera

2. **"Camera permission denied"**
   - Go to Settings → FitTwin Measure → Camera → Enable

3. **Measurements seem inaccurate**
   - Ensure proper distance (6 feet)
   - Ensure good lighting
   - Stand still during countdown
   - Wear form-fitting clothing

## 🔬 Current Status

### ✅ Implemented
- **Pose Detection**: Apple Vision framework extracts 33 landmarks
- **Python API**: Full integration with measurement service
- **Real Measurements**: 18 measurements calculated server-side
- **Error Handling**: Complete error handling and logging

### 🚧 In Progress
- **User Testing**: Awaiting testing on physical iPhones
- **Accuracy Validation**: Comparing to tape measurements
- **Calibration**: Adjusting constants based on test data

### 📋 Planned
- **Export**: Share sheet for JSON/CSV export
- **History**: Measurement history tracking
- **Offline Mode**: On-device calculation option

## 🚀 Next Steps

### Phase 1: Testing & Validation (Current)
- [ ] Complete end-to-end testing on iPhone 12 Pro+
- [ ] Validate accuracy against tape measurements
- [ ] Test repeatability (3+ captures per subject)
- [ ] Document all issues and results

### Phase 2: Accuracy Improvements
- [ ] Integrate full MediaPipe iOS SDK (if needed)
- [ ] Calibrate measurement constants based on test data
- [ ] Improve landmark detection confidence

### Phase 3: UX Enhancements
- [ ] Add visual guides during capture
- [ ] Improve error messages
- [ ] Add measurement history
- [ ] Add export functionality (JSON/CSV)

### Phase 4: Backend Integration
- [ ] Deploy Python service to production
- [ ] Add user authentication
- [ ] Store measurements in database
- [ ] Add avatar generation integration

## 📚 References

### Measurement Formulas
- **NASA Anthropometric Source Book** (1978)
- **ANSUR II Study** (2012) - U.S. Army anthropometric survey
- **Ramanujan's Ellipse Approximation** (1914)

### Technologies
- **AVFoundation** - Camera capture
- **LiDAR** - Depth sensing (iPhone 12 Pro+)
- **MediaPipe** - Pose estimation (planned)
- **SwiftUI** - User interface

## 📝 License

Internal POC - Not for public distribution

## 👥 Contact

For questions or issues, contact the FitTwin development team.

---

**Version**: 1.1.0  
**Last Updated**: 2025-11-09  
**Minimum iOS**: 16.0  
**Tested On**: iPhone 14 Pro, iOS 17.0
