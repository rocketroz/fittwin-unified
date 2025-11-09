# Solo Mode: Sensor-Based Phone Placement Design

**Date**: November 9, 2025  
**Status**: Detailed Design Specification  
**Goal**: Enable accurate solo body measurement using front camera with standardized phone placement

---

## Core Concept

**User places phone on ground or against wall** at a **validated angle** using device sensors (accelerometer/gyroscope) to ensure **consistent measurements** across all captures and all users.

---

## Why Sensor-Based Placement?

### Problem with Handheld
- ❌ Phone shakes during capture
- ❌ Angle varies between users
- ❌ Inconsistent reference frame
- ❌ Can't compare measurements across captures

### Solution: Fixed Placement with Angle Validation
- ✅ **Stable**: No shake, clear images
- ✅ **Consistent**: Same angle every time
- ✅ **Standardized**: All users use same setup
- ✅ **Accurate**: Known angle enables better depth estimation
- ✅ **Comparable**: Measurements can be compared across users

---

## Recommended Phone Placements

### Option 1: Ground Placement (Recommended)

**Setup**:
- Phone placed **flat on ground**
- Front camera facing **up** at user
- User stands **3-4 feet** away
- Phone angle: **0° (horizontal)**

**Advantages**:
- ✅ Most stable (gravity holds phone)
- ✅ Easy to position
- ✅ Full body visible
- ✅ Natural standing position

**Disadvantages**:
- ⚠️ Requires clean floor space
- ⚠️ Low angle may distort proportions slightly

**Best for**: Home use, indoor spaces

---

### Option 2: Wall/Shelf Placement

**Setup**:
- Phone propped **against wall** or on shelf
- Front camera facing **out** at user
- Phone angle: **30-45° from vertical**
- User stands **4-5 feet** away

**Advantages**:
- ✅ Chest-level perspective (most flattering)
- ✅ Minimal distortion
- ✅ Professional photo angle

**Disadvantages**:
- ⚠️ Requires support (books, stand, etc.)
- ⚠️ May need adjustment to get angle right

**Best for**: Users with shelves/stands available

---

### Option 3: Upright Placement (Alternative)

**Setup**:
- Phone **standing upright** (using case/stand)
- Front camera at **chest height**
- Phone angle: **90° (vertical)**
- User stands **5-6 feet** away

**Advantages**:
- ✅ Standard portrait orientation
- ✅ Familiar angle
- ✅ Minimal distortion

**Disadvantages**:
- ⚠️ Requires phone stand or case with kickstand
- ⚠️ Less stable than ground placement

**Best for**: Users with phone stands

---

## Sensor Validation

### CoreMotion API

**Use `CMMotionManager` to detect device orientation:**

```swift
import CoreMotion

class PhoneAngleValidator: ObservableObject {
    private let motionManager = CMMotionManager()
    
    @Published var currentPitch: Double = 0.0  // Forward/backward tilt
    @Published var currentRoll: Double = 0.0   // Left/right tilt
    @Published var isAngleCorrect: Bool = false
    
    enum PlacementMode {
        case ground      // 0° pitch, 0° roll
        case wall45      // 45° pitch, 0° roll
        case upright     // 90° pitch, 0° roll
    }
    
    var targetMode: PlacementMode = .ground
    
    func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion, let self = self else { return }
            
            // Convert radians to degrees
            let pitch = motion.attitude.pitch * 180 / .pi
            let roll = motion.attitude.roll * 180 / .pi
            
            self.currentPitch = pitch
            self.currentRoll = roll
            
            // Validate angle based on target mode
            self.isAngleCorrect = self.validateAngle(pitch: pitch, roll: roll)
        }
    }
    
    func validateAngle(pitch: Double, roll: Double) -> Bool {
        let tolerance = 5.0  // ±5 degrees
        
        switch targetMode {
        case .ground:
            // Phone flat on ground: pitch ≈ 0°, roll ≈ 0°
            return abs(pitch) < tolerance && abs(roll) < tolerance
            
        case .wall45:
            // Phone at 45° against wall: pitch ≈ 45°, roll ≈ 0°
            return abs(pitch - 45) < tolerance && abs(roll) < tolerance
            
        case .upright:
            // Phone standing upright: pitch ≈ 90°, roll ≈ 0°
            return abs(pitch - 90) < tolerance && abs(roll) < tolerance
        }
    }
    
    func getAdjustmentGuidance() -> String {
        let pitchDiff = currentPitch - targetPitch()
        let rollDiff = currentRoll
        
        if abs(pitchDiff) > 5 {
            if pitchDiff > 0 {
                return "Tilt phone backward \(Int(abs(pitchDiff)))°"
            } else {
                return "Tilt phone forward \(Int(abs(pitchDiff)))°"
            }
        }
        
        if abs(rollDiff) > 5 {
            if rollDiff > 0 {
                return "Rotate phone \(Int(abs(rollDiff)))° counterclockwise"
            } else {
                return "Rotate phone \(Int(abs(rollDiff)))° clockwise"
            }
        }
        
        return "Perfect angle! ✓"
    }
    
    private func targetPitch() -> Double {
        switch targetMode {
        case .ground: return 0
        case .wall45: return 45
        case .upright: return 90
        }
    }
}
```

---

## UI Design

### Phase 1: Placement Setup Screen

```
┌─────────────────────────────────┐
│  📱 Solo Mode - Phone Setup     │
│                                 │
│  Choose phone placement:        │
│                                 │
│  ┌───────────────────────────┐  │
│  │  📐 Ground Placement      │  │
│  │  RECOMMENDED              │  │
│  │                           │  │
│  │  [Illustration]           │  │
│  │  Phone flat on ground     │  │
│  │  Stand 3-4 feet away      │  │
│  │                           │  │
│  │  [Select]                 │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │  📚 Wall/Shelf Placement  │  │
│  │                           │  │
│  │  [Illustration]           │  │
│  │  Phone at 45° angle       │  │
│  │  Stand 4-5 feet away      │  │
│  │                           │  │
│  │  [Select]                 │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │  🎯 Upright Placement     │  │
│  │                           │  │
│  │  [Illustration]           │  │
│  │  Phone standing vertical  │  │
│  │  Stand 5-6 feet away      │  │
│  │                           │  │
│  │  [Select]                 │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

### Phase 2: Angle Validation Screen

```
┌─────────────────────────────────┐
│  📐 Adjust Phone Angle          │
│                                 │
│  ┌───────────────────────────┐  │
│  │                           │  │
│  │   [Live Camera Preview]   │  │
│  │                           │  │
│  │   • • • • • • • • • •     │  │  ← Level indicator
│  │         ▼                 │  │  ← Current angle marker
│  │                           │  │
│  └───────────────────────────┘  │
│                                 │
│  Current Angle: 12°             │
│  Target Angle: 0° (Ground)      │
│                                 │
│  ┌───────────────────────────┐  │
│  │  ⚠️ Tilt phone forward 12° │  │
│  └───────────────────────────┘  │
│                                 │
│  [Skip Validation] (not recommended) │
└─────────────────────────────────┘
```

**When angle is correct:**

```
┌─────────────────────────────────┐
│  ✅ Perfect Angle!              │
│                                 │
│  ┌───────────────────────────┐  │
│  │                           │  │
│  │   [Live Camera Preview]   │  │
│  │                           │  │
│  │   • • • • ✓ • • • • •     │  │  ← Green checkmark
│  │                           │  │
│  └───────────────────────────┘  │
│                                 │
│  Current Angle: 0°              │
│  Target Angle: 0° (Ground) ✓    │
│                                 │
│  ┌───────────────────────────┐  │
│  │  Phone is positioned        │  │
│  │  correctly. Keep it stable  │  │
│  │  and step back.             │  │
│  └───────────────────────────┘  │
│                                 │
│  [Continue to Positioning]      │
└─────────────────────────────────┘
```

### Phase 3: Distance Validation

```
┌─────────────────────────────────┐
│  📏 Check Your Distance         │
│                                 │
│  ┌───────────────────────────┐  │
│  │                           │  │
│  │   [Live Camera Preview]   │  │
│  │                           │  │
│  │   ┌─────────────────┐     │  │  ← Body outline guide
│  │   │                 │     │  │
│  │   │    👤 (you)     │     │  │
│  │   │                 │     │  │
│  │   └─────────────────┘     │  │
│  │                           │  │
│  └───────────────────────────┘  │
│                                 │
│  Distance: 2.5 feet             │
│  Target: 3-4 feet               │
│                                 │
│  ⚠️ Step back 1 foot            │
│                                 │
│  [Continue Anyway]              │
└─────────────────────────────────┘
```

**When distance is correct:**

```
┌─────────────────────────────────┐
│  ✅ Perfect Distance!           │
│                                 │
│  ┌───────────────────────────┐  │
│  │                           │  │
│  │   [Live Camera Preview]   │  │
│  │                           │  │
│  │   ┌─────────────────┐     │  │  ← Green outline
│  │   │                 │     │  │
│  │   │    👤 (you)     │     │  │
│  │   │                 │     │  │
│  │   └─────────────────┘     │  │
│  │                           │  │
│  └───────────────────────────┘  │
│                                 │
│  Distance: 3.5 feet ✓           │
│  Full body visible ✓            │
│                                 │
│  [Start Positioning]            │
└─────────────────────────────────┘
```

---

## Distance Estimation

### Using Vision Framework

**Estimate distance from body size in frame:**

```swift
import Vision

class DistanceEstimator {
    
    // Average human height in meters
    private let averageHeight: Float = 1.70
    
    // iPhone front camera specs (approximate)
    private let focalLength: Float = 2.71  // mm
    private let sensorHeight: Float = 4.8  // mm
    
    func estimateDistance(bodyHeight: CGFloat, imageHeight: CGFloat) -> Float {
        // Calculate the proportion of the image occupied by the body
        let bodyProportion = Float(bodyHeight / imageHeight)
        
        // Estimate distance using similar triangles
        // distance = (realHeight * focalLength) / (bodyHeight * sensorHeight)
        let distance = (averageHeight * focalLength) / (bodyProportion * sensorHeight)
        
        return distance  // in meters
    }
    
    func validateDistance(_ distance: Float, for placement: PlacementMode) -> Bool {
        switch placement {
        case .ground:
            // 3-4 feet = 0.9-1.2 meters
            return distance >= 0.9 && distance <= 1.2
            
        case .wall45:
            // 4-5 feet = 1.2-1.5 meters
            return distance >= 1.2 && distance <= 1.5
            
        case .upright:
            // 5-6 feet = 1.5-1.8 meters
            return distance >= 1.5 && distance <= 1.8
        }
    }
}
```

---

## Complete Solo Mode Flow

### Step-by-Step User Experience

```
1. Launch App
   ↓
2. Select "Solo Mode"
   ↓
3. Choose Placement Method
   - Ground (recommended)
   - Wall/Shelf
   - Upright
   ↓
4. See Placement Instructions
   - Illustration showing setup
   - "Place phone flat on ground"
   - "Make sure area is clear"
   ↓
5. Place Phone
   - User places phone
   - Taps "Check Angle"
   ↓
6. Angle Validation (Live)
   - Camera preview shows
   - Sensor reads angle
   - Real-time feedback:
     * "Tilt forward 10°"
     * "Perfect angle! ✓"
   - Green indicator when correct
   ↓
7. Lock Angle
   - "Keep phone stable"
   - "Step back to 3-4 feet"
   ↓
8. Distance Validation (Live)
   - Vision detects body
   - Estimates distance
   - Shows body outline guide
   - Feedback:
     * "Step back 1 foot"
     * "Perfect distance! ✓"
   ↓
9. Positioning Phase
   - User sees themselves
   - Visual T-pose guide overlay
   - "Extend arms to 45°"
   - Green when positioned correctly
   ↓
10. Ready to Capture
    - "Hold position"
    - Tap "Start" or auto-start
    ↓
11. Countdown (3-2-1)
    - Visual countdown
    - Optional audio
    ↓
12. Capture (30 seconds)
    - "Rotate slowly to your left"
    - Progress bar 0-360°
    - Can see themselves rotating
    ↓
13. Processing
    - "Analyzing poses..."
    - Progress indicator
    ↓
14. Results
    - 13 measurements
    - Quality score
    - Export/Share options
```

**Total Time**: ~90 seconds (vs 3 minutes for Two Person Mode)

---

## Advantages of This Approach

### 1. Consistency
- ✅ Same angle across all users
- ✅ Measurements are comparable
- ✅ Can track changes over time

### 2. Accuracy
- ✅ Known angle enables depth estimation
- ✅ Stable phone = clear images
- ✅ Standardized reference frame

### 3. User Experience
- ✅ User can see themselves (like a mirror)
- ✅ Visual feedback is intuitive
- ✅ No helper needed
- ✅ Faster than Two Person Mode

### 4. Accessibility
- ✅ Works on all iPhones (iOS 14+)
- ✅ No LiDAR required
- ✅ No tripod required (uses ground/wall)

---

## Implementation Checklist

### Phase 1: Sensor Integration
- [ ] Implement `CMMotionManager` for angle detection
- [ ] Create `PhoneAngleValidator` class
- [ ] Add real-time angle feedback UI
- [ ] Test on different surfaces (floor, shelf, etc.)

### Phase 2: Placement UI
- [ ] Design placement selection screen
- [ ] Create illustrations for each placement type
- [ ] Implement angle validation screen
- [ ] Add level indicator visualization

### Phase 3: Distance Validation
- [ ] Implement Vision body detection
- [ ] Calculate distance from body size
- [ ] Add distance feedback UI
- [ ] Create body outline guide overlay

### Phase 4: Capture Flow
- [ ] Integrate with Vision pose detection
- [ ] Add T-pose visual guide
- [ ] Implement 360° rotation tracking
- [ ] Calculate measurements from poses

### Phase 5: Testing
- [ ] Test all three placement modes
- [ ] Validate angle accuracy
- [ ] Validate distance estimation
- [ ] Compare measurements to tape measure

---

## Expected Accuracy

### With Proper Placement
- **Height**: ±2-3 cm ✅
- **Shoulder Width**: ±2-3 cm ✅
- **Inseam**: ±3-4 cm ✅
- **Arm Length**: ±3-4 cm ✅
- **Circumferences**: ±4-6 cm ⚠️ (estimated from 2D)

### Factors Affecting Accuracy
- ✅ **Angle validation**: Ensures consistent reference
- ✅ **Distance validation**: Ensures proper scale
- ✅ **Stable placement**: Reduces blur
- ⚠️ **Clothing**: Must be form-fitting
- ⚠️ **Lighting**: Must be adequate

---

## Comparison: Solo vs Two Person Mode

| Feature | Solo Mode (Sensor) | Two Person Mode |
|---------|-------------------|-----------------|
| **Phone Placement** | Ground/wall (validated) | Handheld/tripod |
| **Angle Validation** | Yes (sensors) | No |
| **User Sees Screen** | Yes ✅ | No ❌ |
| **Setup Complexity** | Low (place phone) | Medium (position helper) |
| **Stability** | Very High (on ground) | Medium (handheld) |
| **Consistency** | Very High (validated angle) | Medium (varies by helper) |
| **Accuracy** | ±3-5 cm | ±1-2 cm |
| **Time** | 90 seconds | 3 minutes |

---

## Next Steps

1. **Implement angle validation** using CoreMotion
2. **Create placement UI** with illustrations
3. **Test sensor accuracy** on different surfaces
4. **Integrate with Vision** pose detection
5. **Validate with real measurements**

---

## Conclusion

**Sensor-based phone placement** provides:
- ✅ **Standardization**: All users capture at same angle
- ✅ **Consistency**: Measurements are comparable
- ✅ **Accuracy**: Known angle enables better estimation
- ✅ **Simplicity**: Just place phone and go
- ✅ **Stability**: No shake, clear images

This approach combines the **ease of Solo Mode** with the **consistency of professional setups**, providing a **best-of-both-worlds solution** for solo body measurement capture.

---

**Ready to implement!** 🚀
