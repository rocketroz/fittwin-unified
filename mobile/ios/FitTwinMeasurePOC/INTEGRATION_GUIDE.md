# Integration Guide: Enhanced ARBody Capture with Audio Guidance

**Date**: November 9, 2025  
**Status**: Ready for Testing  
**Target**: iOS 17+ with LiDAR (iPhone 12 Pro+)

---

## Overview

This guide explains how to integrate the new audio guidance and arm position validation features into the FitTwin measurement app.

---

## New Components

### 1. AudioGuidanceManager.swift

**Purpose**: Provides comprehensive voice guidance throughout the capture process.

**Key Features**:
- Phase-based announcements (setup → positioning → countdown → rotation → complete)
- Real-time position corrections ("Raise your arms", "Perfect position!")
- Core Haptics feedback for tactile confirmation
- VoiceOver accessibility support
- User-configurable volume and enable/disable

**Usage**:
```swift
@StateObject private var audioManager = AudioGuidanceManager()

// Announce phase transitions
audioManager.announceSetup()
audioManager.announcePositioning()
audioManager.announceCountdown()

// Provide feedback
audioManager.announceArmsTooLow()
audioManager.announcePerfectPosition()

// Cleanup
audioManager.cleanup()
```

### 2. ArmPositionValidator.swift

**Purpose**: Real-time validation of Modified T-Pose (45° arm angle).

**Key Features**:
- Calculates arm angles from ARKit skeleton (90+ joints)
- Validates against 45° target with ±10° tolerance
- Detects asymmetry between left and right arms
- Requires 10 consecutive valid frames for stability
- Provides visual feedback colors (green/yellow/orange)
- Tracks statistics and quality scoring

**Usage**:
```swift
let armValidator = ArmPositionValidator()

// Validate current skeleton
let result = armValidator.validate(skeleton: arSkeleton)

// Check if position is stable and valid
if armValidator.isStableAndValid {
    // Ready to start capture
}

// Get feedback for UI
let message = armValidator.getOverlayMessage(for: result)
let color = armValidator.getFeedbackColor(for: result)

// Get statistics after capture
let stats = armValidator.getStatistics()
print("Quality Score: \(stats.qualityScore)%")
```

### 3. ARBodyCaptureView_Enhanced.swift

**Purpose**: Complete capture flow with integrated audio and validation.

**New Capture States**:
1. **idle** - Initial state, waiting to start
2. **setup** - Clothing and distance checklist
3. **positioning** - Getting into Modified T-Pose
4. **ready** - Position validated, ready to capture
5. **countdown** - 3-2-1 countdown
6. **capturing** - 360° rotation in progress
7. **processing** - Calculating measurements
8. **complete** - Results ready

**Key Improvements**:
- Visual arm position overlay (color-coded feedback)
- Audio guidance at every step
- Haptic feedback for confirmations
- Quality score in results
- Settings panel (audio toggle, volume control)

---

## Integration Steps

### Step 1: Add New Files to Xcode Project

1. Open `FitTwinMeasurePOC.xcodeproj`
2. Right-click on `FitTwinMeasure` folder
3. Select "Add Files to FitTwinMeasurePOC..."
4. Add:
   - `AudioGuidanceManager.swift`
   - `ArmPositionValidator.swift`
   - `ARBodyCaptureView_Enhanced.swift`
5. Ensure "Copy items if needed" is checked
6. Target: FitTwinMeasure

### Step 2: Update Info.plist

Add audio session permissions:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Audio guidance helps you position correctly during body measurement capture.</string>

<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

### Step 3: Update ContentView.swift

Replace the old capture view with the enhanced version:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        if #available(iOS 13.0, *) {
            ARBodyCaptureView_Enhanced()  // ← Use enhanced version
        } else {
            Text("iOS 13.0 or later required")
        }
    }
}
```

### Step 4: Update ARBodyTrackingManager.swift

Add skeleton access for arm validation:

```swift
class ARBodyTrackingManager: NSObject, ObservableObject, ARSessionDelegate {
    // ... existing code ...
    
    // Add public access to current skeleton
    @Published var currentSkeleton: ARSkeleton3D?
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
            
            DispatchQueue.main.async {
                self.isBodyDetected = true
                self.currentSkeleton = bodyAnchor.skeleton  // ← Add this
                
                // ... rest of existing code ...
            }
        }
    }
}
```

### Step 5: Connect Arm Validation to ARSession

In `ARBodyCaptureView_Enhanced.swift`, update the `startArmValidation()` method:

```swift
private func startArmValidation() {
    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
        guard captureState == .positioning || captureState == .ready else {
            timer.invalidate()
            return
        }
        
        // Get current skeleton from tracking manager
        guard let skeleton = trackingManager.currentSkeleton else {
            return
        }
        
        // Validate arm position
        let result = armValidator.validate(skeleton: skeleton)
        armPositionResult = result
        
        // Provide audio feedback (throttled)
        if !result.isValid {
            // Only announce corrections every 3 seconds
            if Date().timeIntervalSince(lastFeedbackTime) > 3.0 {
                switch armValidator.validateAngles(
                    left: result.leftArmAngle,
                    right: result.rightArmAngle
                ) {
                case .armsTooLow:
                    audioManager.announceArmsTooLow()
                case .armsTooHigh:
                    audioManager.announceArmsTooHigh()
                case .armsAsymmetric:
                    audioManager.announceKeepArmsSteady()
                default:
                    break
                }
                lastFeedbackTime = Date()
            }
        }
        
        // Check if ready
        if armValidator.isStableAndValid && captureState == .positioning {
            timer.invalidate()
            confirmPosition()
        }
    }
}
```

---

## Testing Checklist

### Device Requirements
- [ ] iPhone 12 Pro or later (LiDAR required)
- [ ] iOS 17.0 or later
- [ ] Good lighting conditions
- [ ] 6-8 feet of clear space

### Pre-Capture Testing
- [ ] Audio guidance plays on app launch
- [ ] Body detection indicator turns green when in view
- [ ] Settings button opens audio controls
- [ ] Volume slider adjusts audio level
- [ ] Audio toggle mutes/unmutes guidance

### Positioning Testing
- [ ] Instructions display "Modified T-Pose"
- [ ] Arm position overlay shows color feedback:
  - Green when arms at 45° ±10°
  - Orange when arms too low or too high
  - Yellow when arms asymmetric
- [ ] Audio announces "Raise your arms" when too low
- [ ] Audio announces "Perfect position!" when correct
- [ ] Button becomes enabled after 10 consecutive valid frames

### Capture Testing
- [ ] Countdown plays "3... 2... 1... Begin rotating"
- [ ] Haptic feedback on "1"
- [ ] Progress bar shows 0-100%
- [ ] Audio announces at 25%, 50%, 75% milestones
- [ ] Rotation angle displays in real-time
- [ ] Cancel button stops capture

### Results Testing
- [ ] Processing screen shows spinner
- [ ] Audio announces "Measurements complete!"
- [ ] Results show all 13 measurements
- [ ] Quality score displays (0-100%)
- [ ] Export button generates JSON with metadata
- [ ] New Capture button resets to idle state

### Accessibility Testing
- [ ] VoiceOver reads all instructions
- [ ] VoiceOver announces phase transitions
- [ ] Haptic feedback works without audio
- [ ] High contrast mode supported
- [ ] Dynamic type scaling works

---

## Troubleshooting

### Audio Not Playing

**Problem**: No voice guidance heard.

**Solutions**:
1. Check device volume (not muted)
2. Check app audio settings (toggle enabled)
3. Verify Info.plist has audio permissions
4. Check AVAudioSession setup in AudioGuidanceManager

### Arm Validation Not Working

**Problem**: Overlay stays red/orange even when arms are correct.

**Solutions**:
1. Ensure ARBodyTrackingManager exposes `currentSkeleton`
2. Check lighting (ARKit needs good lighting for joint tracking)
3. Verify body is fully visible (no occlusion)
4. Check tolerance settings (may need to increase from ±10°)
5. Print debug info: `armValidator.getDebugInfo(for: result)`

### Position Never Becomes "Ready"

**Problem**: Stuck in positioning phase.

**Solutions**:
1. Reduce `requiredValidFrames` from 10 to 5 (in ArmPositionValidator)
2. Increase `angleTolerance` from 10° to 15°
3. Check if skeleton joints are being tracked (print joint names)
4. Ensure user is wearing form-fitting clothing (loose clothing confuses tracking)

### App Crashes on Launch

**Problem**: App crashes when opening AR view.

**Solutions**:
1. Check device has LiDAR (iPhone 12 Pro+)
2. Verify ARKit Body Tracking support check
3. Check for memory issues (reduce point cloud resolution)
4. Ensure all @StateObject initializations are correct

---

## Performance Optimization

### Audio Guidance

**Current**: Speaks every announcement immediately.

**Optimization**:
- Queue announcements to avoid overlap
- Skip announcements if previous one is still playing
- Use shorter phrases for faster feedback

**Implementation**:
```swift
// In AudioGuidanceManager
private var announcementQueue: [String] = []

func queueAnnouncement(_ text: String) {
    announcementQueue.append(text)
    processQueue()
}

private func processQueue() {
    guard !synthesizer.isSpeaking, !announcementQueue.isEmpty else {
        return
    }
    let next = announcementQueue.removeFirst()
    speak(next)
}
```

### Arm Validation

**Current**: Validates every 0.1 seconds (10 Hz).

**Optimization**:
- Reduce to 0.2 seconds (5 Hz) if performance is an issue
- Only validate when body is detected
- Cache angle calculations

**Implementation**:
```swift
// Reduce timer frequency
Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { ... }

// Add caching
private var cachedAngles: (left: Float, right: Float, timestamp: Date)?

func validate(skeleton: ARSkeleton3D) -> ValidationResult {
    // Use cached values if less than 100ms old
    if let cached = cachedAngles,
       Date().timeIntervalSince(cached.timestamp) < 0.1 {
        // Return cached result
    }
    // ... calculate new angles ...
}
```

---

## Future Enhancements

### Short-term (v1.1)

1. **Tutorial Video**
   - Show example of correct Modified T-Pose
   - Demonstrate 360° rotation speed
   - Add to onboarding flow

2. **Practice Mode**
   - Let users practice positioning without capturing
   - Show real-time arm angle numbers
   - No measurement calculation

3. **AR Guide Overlay**
   - Show 3D skeleton target position
   - Overlay target arm angles
   - Visual guide for rotation direction

### Long-term (v2.0)

1. **AI Pose Correction**
   - Auto-adjust measurements for minor pose errors
   - Machine learning model trained on pose variations
   - Reduce need for perfect positioning

2. **Multiple Pose Options**
   - T-pose (90° arms)
   - Modified T-pose (45° arms) ← current
   - A-pose (20° arms)
   - Relaxed natural pose

3. **Adaptive Guidance**
   - Learn user's common mistakes
   - Provide personalized tips
   - Adjust tolerance based on user's ability

4. **Accessibility Improvements**
   - Support for users who can't hold T-pose
   - Seated capture mode
   - Assisted capture with helper

---

## API Documentation

### AudioGuidanceManager

#### Properties
```swift
@Published var isEnabled: Bool          // Enable/disable audio
@Published var volume: Float            // Volume 0.0-1.0
@Published var currentPhase: CapturePhase  // Current capture phase
```

#### Methods
```swift
func speak(_ text: String, withHaptic: Bool = false)
func stopSpeaking()
func announceSetup()
func announcePositioning()
func announceCountdown()
func announceRotationProgress(_ progress: Float)
func announceSuccess()
func playHaptic(_ type: HapticType)
```

### ArmPositionValidator

#### Properties
```swift
var isStableAndValid: Bool  // Position held for required duration
```

#### Methods
```swift
func validate(skeleton: ARSkeleton3D) -> ValidationResult
func getAverageAngle(over seconds: TimeInterval) -> Float?
func getStatistics() -> ValidationStatistics
func getFeedbackColor(for result: ValidationResult) -> (r, g, b, a)
func getOverlayMessage(for result: ValidationResult) -> String
func reset()
```

#### Types
```swift
struct ValidationResult {
    let timestamp: Date
    let isValid: Bool
    let leftArmAngle: Float
    let rightArmAngle: Float
    let feedback: String
}

struct ValidationStatistics {
    let totalFrames: Int
    let validFrames: Int
    let validPercentage: Float
    let averageLeftAngle: Float
    let averageRightAngle: Float
    let qualityScore: Float  // 0-100
}
```

---

## Measurement Export Format

### JSON Structure

```json
{
  "measurements": {
    "height_cm": 175.2,
    "shoulder_width_cm": 42.1,
    "chest_cm": 98.5,
    "waist_natural_cm": 82.3,
    "hip_low_cm": 95.7,
    "inseam_cm": 78.9,
    "outseam_cm": 102.4,
    "sleeve_length_cm": 61.2,
    "neck_cm": 38.5,
    "bicep_cm": 32.1,
    "forearm_cm": 27.8,
    "thigh_cm": 56.3,
    "calf_cm": 37.2
  },
  "metadata": {
    "timestamp": 1699564800.0,
    "capture_method": "arkit_body_tracking_modified_t_pose",
    "quality_score": 87.5,
    "valid_frames_percentage": 92.3,
    "average_arm_angle_left": 46.2,
    "average_arm_angle_right": 44.8
  }
}
```

### Quality Score Interpretation

| Score | Quality | Action |
|-------|---------|--------|
| 90-100 | Excellent ✅✅ | Use measurements confidently |
| 80-89 | Good ✅ | Acceptable for most use cases |
| 70-79 | Fair ⚠️ | Consider recapture for critical measurements |
| 60-69 | Poor ⚠️⚠️ | Recapture recommended |
| 0-59 | Very Poor ❌ | Recapture required |

---

## Support

For issues or questions:
1. Check BODY_POSITION_RESEARCH.md for positioning guidelines
2. Review ARKIT_IMPLEMENTATION.md for technical details
3. See UXUI_FLOW_2025.md for UX best practices
4. Contact: [Your support channel]

---

**Last Updated**: November 9, 2025  
**Version**: 1.0  
**Status**: Ready for Device Testing
