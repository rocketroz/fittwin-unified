# Phone Angle & Setup Research for Body Measurement

## Optimal Phone Angle

Based on photography and body measurement research:

### **Recommended Angle: 15-20 degrees from vertical**

**Why this angle:**
- Camera at hip/waist level when phone is on floor
- Captures full body from head to toe
- Minimizes distortion
- Matches professional photography standards
- Similar to what 3DLook/MTailor use

### Phone Placement

**Distance from wall:** 0 inches (leaning against wall)
**Distance from subject:** 6-8 feet
**Height:** On floor
**Angle:** 15-20° tilted back (top of phone away from wall)

### Visual Reference
```
Wall
|
|  <- Phone (15-20° tilt)
|/
|_____ Floor

User stands 6-8 feet away
```

## Clothing Recommendations

### Best Results:
1. **Form-fitting clothes** (not baggy)
2. **Solid colors** (avoid busy patterns)
3. **Contrast with background** (dark clothes + light wall, or vice versa)
4. **Minimal layers** (single layer preferred)

### Specific Recommendations:
- **Top**: Fitted t-shirt, tank top, or sports bra
- **Bottom**: Fitted shorts, leggings, or underwear
- **Avoid**: Loose clothing, jackets, dresses, baggy pants
- **Shoes**: Barefoot or thin-soled shoes

### Why Form-Fitting:
- AI needs to see body contours
- Baggy clothes hide body shape
- Accurate measurements require visible body outline

## Audio Narration Script

### Setup Phase:
1. "Welcome to FitTwin. Please turn up your volume for audio guidance."
2. "First, let's prepare. Wear form-fitting clothes like a fitted t-shirt and shorts."
3. "Find a plain wall with good lighting."
4. "Place your phone on the floor, leaning against the wall."
5. "Tilt the top of your phone back about 15 degrees."
6. "Great! Your phone angle is perfect."

### Capture Phase:
7. "Step back 6 to 8 feet from your phone."
8. "Stand with your arms slightly away from your body."
9. "Match the body outline on screen."
10. "Hold still... capturing in 3... 2... 1..."
11. "Perfect! Now rotate 90 degrees to your left."
12. "Match the side outline on screen."
13. "Hold still... capturing in 3... 2... 1..."
14. "Excellent! Processing your measurements..."

## Accelerometer Detection

### Phone Angle Detection:
- Use `CMMotionManager` to detect device orientation
- Target angle: 15-20° from vertical
- Show visual indicator:
  - ❌ Red: Wrong angle
  - ⚠️ Yellow: Close (10-14° or 21-25°)
  - ✅ Green: Perfect (15-20°)

### Implementation:
```swift
// Pseudo-code
let targetAngle = 17.5 // degrees (middle of 15-20 range)
let tolerance = 2.5 // ±2.5 degrees
let currentAngle = calculateAngleFromAccelerometer()

if abs(currentAngle - targetAngle) <= tolerance {
    showGreenIndicator()
    enableContinueButton()
} else {
    showRedIndicator()
    disableContinueButton()
}
```

## Distance Detection

### Optional Enhancement:
- Use ARKit to measure distance from phone to user
- Target: 6-8 feet (1.8-2.4 meters)
- Show on-screen indicator:
  - "Too close - step back"
  - "Perfect distance"
  - "Too far - step forward"
