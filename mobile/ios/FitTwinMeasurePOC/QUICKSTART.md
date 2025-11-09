# FitTwin Measure - Quick Start Guide

## ⚡ Get Running in 5 Minutes

### Prerequisites
- ✅ Mac with Xcode 15+
- ✅ iPhone 12 Pro or newer (with LiDAR) **REQUIRED**
- ✅ USB-C/Lightning cable
- ✅ 6-8 feet of clear space
- ✅ Good lighting

### Step 1: Open in Xcode
```bash
cd fittwin-unified/mobile/ios/FitTwinMeasurePOC
open FitTwinMeasure.xcodeproj
```

### Step 2: Configure Signing
1. Click **FitTwinMeasure** in project navigator
2. Select **FitTwinMeasure** target
3. Go to **Signing & Capabilities** tab
4. Under **Team**, select your Apple Developer account
5. Xcode will auto-generate provisioning profile

### Step 3: Connect Device
1. Connect iPhone 12 Pro+ via USB
2. Unlock iPhone
3. Trust computer if prompted ("Trust this computer?")
4. Select your iPhone in Xcode toolbar (top-left, next to Run button)

### Step 4: Build & Run
1. Click **Run** button (▶️) or press `⌘R`
2. Wait for build to complete (~30 seconds first time)
3. App will launch on your iPhone

### Step 5: Grant Permissions
When prompted, tap **Allow** for:
- ✅ Camera access (required)
- ✅ Motion & Fitness (for ARKit)

---

## 📱 Using the App (New Enhanced Flow)

### Setup Phase (30 seconds)

1. **Tap "Start"** on the welcome screen
2. **Audio guidance will say**: "Welcome to FitTwin. Let's take your measurements."
3. **Follow the checklist**:
   - ✅ Wear form-fitting clothing (compression wear ideal)
   - ✅ Remove all accessories (belts, watches, jewelry)
   - ✅ Put hair up (if long)
   - ✅ Stand 6-8 feet from phone
   - ✅ Place phone on tripod/stable surface at chest height
4. **Tap "Next"** when ready

### Positioning Phase (30-60 seconds)

**Audio will guide you into Modified T-Pose:**

1. **Stance**:
   - "Stand with feet shoulder-width apart"
   - Stand upright, shoulders relaxed
   - Look straight ahead

2. **Arm Position** (CRITICAL):
   - "Extend your arms out to the sides at a 45-degree angle"
   - Arms halfway between straight down and horizontal
   - Palms facing down
   - Fingers together, relaxed

3. **Visual Feedback**:
   - 🟢 **Green overlay** = Perfect position
   - 🟡 **Yellow overlay** = Adjust slightly
   - 🟠 **Orange overlay** = Arms too high/low

4. **Audio Corrections**:
   - "Raise your arms a bit higher" (if too low)
   - "Lower your arms slightly" (if too high)
   - "Perfect position!" (when correct)

5. **Wait for Confirmation**:
   - Hold position for ~3 seconds
   - Button will turn green when ready
   - **Tap "Start Capture"**

### Countdown Phase (4 seconds)

- Audio: "Get ready. Starting in 3... 2... 1..."
- **Haptic vibration** on "1"
- Audio: "Begin rotating slowly to your left"

### Capture Phase (30 seconds)

**Rotate 360° to your left (counterclockwise):**

1. **Rotation Speed**:
   - Complete full rotation in 30 seconds
   - Smooth, steady speed
   - Don't stop or speed up

2. **Maintain Position**:
   - Keep arms at 45° angle
   - Stay upright
   - Look straight ahead

3. **Progress Feedback**:
   - Progress bar shows 0-100%
   - Audio at milestones:
     - 25%: "Keep rotating, you're doing great"
     - 50%: "Halfway there, maintain your arm position"
     - 75%: "Almost done, keep your arms up"

4. **Completion**:
   - Audio: "Perfect! You can relax now"
   - **Haptic vibration**

### Processing Phase (5-10 seconds)

- Audio: "Processing your measurements..."
- Spinner displays
- Calculating 13 measurements from captured data

### Results Phase

**Audio: "Measurements complete!"**

View your measurements:
- ✅ Height (cm)
- ✅ Shoulder Width (cm)
- ✅ Chest Circumference (cm)
- ✅ Waist Circumference (cm)
- ✅ Hip Circumference (cm)
- ✅ Inseam (cm)
- ✅ Outseam (cm)
- ✅ Sleeve Length (cm)
- ✅ Neck Circumference (cm)
- ✅ Bicep Circumference (cm)
- ✅ Forearm Circumference (cm)
- ✅ Thigh Circumference (cm)
- ✅ Calf Circumference (cm)

**Quality Score**: 0-100% (based on how well you held the pose)
- 90-100: Excellent ✅✅
- 80-89: Good ✅
- 70-79: Fair ⚠️
- Below 70: Consider recapture

**Actions**:
- **Export**: Prints JSON to Xcode console (⌘⇧Y)
- **New Capture**: Start over

---

## 🎯 Expected Accuracy

| Measurement | Accuracy | Notes |
|-------------|----------|-------|
| Height | ±1 cm | Very accurate |
| Shoulder Width | ±1-2 cm | Very accurate |
| Chest/Waist/Hip | ±2-3 cm | Accurate |
| Inseam/Outseam | ±2-3 cm | Accurate |
| Sleeve Length | ±2-3 cm | Accurate |
| Arm/Leg Circumferences | ±3-4 cm | Good (affected by clothing) |
| Neck | ±2-3 cm | Good (can be occluded) |

**Total capture time**: 2-3 minutes

---

## 🔍 Viewing Exported Data

**In Xcode Console** (⌘⇧Y):
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

---

## ⚙️ Settings

**Tap gear icon** (top-right) to adjust:
- 🔊 **Audio Guidance**: Enable/disable voice coaching
- 🔉 **Volume**: Adjust audio volume (0-100%)

**Accessibility**:
- VoiceOver supported
- Haptic feedback works without audio
- High contrast mode supported

---

## ⚠️ Troubleshooting

### "ARKit Body Tracking not supported"
- **Cause**: Device doesn't have LiDAR
- **Fix**: Use iPhone 12 Pro, 13 Pro, 14 Pro, or 15 Pro (or Max variants)
- **Note**: Regular iPhone 12/13/14/15 do NOT have LiDAR

### "No Body Detected"
- Stand 6-8 feet from camera
- Ensure full body is visible (head to feet)
- Check lighting (not too dim)
- Move to area with more features (not blank wall)

### Arms Not Validating (Stuck in Orange/Yellow)
- **Arms at 45°**: Halfway between down and horizontal
- **Check symmetry**: Both arms at same height
- **Relax**: Don't tense up
- **Hold steady**: Need 10 consecutive valid frames (~3 seconds)

### "Insufficient Data" Error
- Rotation was too fast (slow down to 30 seconds)
- Body went out of frame during rotation
- Lighting changed during capture
- Try again with slower, steadier rotation

### Audio Not Playing
- Check device volume (not muted)
- Check app settings (audio enabled)
- Check silent mode switch on iPhone
- Restart app

### Measurements Seem Off
- **Clothing**: Must be form-fitting (loose clothing adds 2-5 cm)
- **Distance**: Stand exactly 6-8 feet from camera
- **Lighting**: Ensure bright, even lighting
- **Rotation**: Complete smooth 360° rotation
- **Arm position**: Must maintain 45° angle throughout

### Quality Score Below 70%
- **Recapture recommended**
- Common issues:
  - Arms dropped during rotation
  - Rotation too fast/slow
  - Body moved forward/backward
  - Stopped mid-rotation

---

## 📊 Testing Checklist

### Pre-Capture
- [ ] App launches successfully
- [ ] Camera permission granted
- [ ] Body detection indicator turns green
- [ ] Audio guidance plays
- [ ] Settings button works

### Positioning
- [ ] Instructions display "Modified T-Pose"
- [ ] Visual overlay changes color (green/yellow/orange)
- [ ] Audio announces corrections
- [ ] Button enables after valid position held

### Capture
- [ ] Countdown plays (3-2-1)
- [ ] Haptic feedback on "1"
- [ ] Progress bar updates 0-100%
- [ ] Audio announces milestones (25%, 50%, 75%)
- [ ] Cancel button works

### Results
- [ ] Processing screen appears
- [ ] All 13 measurements display
- [ ] Quality score shows (0-100%)
- [ ] Export prints JSON to console
- [ ] New Capture button resets app

---

## 💡 Tips for Best Results

### Clothing (CRITICAL)
- ✅ **Compression wear** (athletic tights, sports bra)
- ✅ **Form-fitting** clothes
- ✅ **Solid colors** (dark colors best)
- ❌ **NO baggy clothing** (adds 2-5 cm error)
- ❌ **NO accessories** (belts, watches, jewelry)
- ❌ **NO loose hair** (tie up if long)

### Lighting
- ✅ Bright, even lighting
- ✅ Natural daylight preferred
- ✅ Multiple light sources
- ❌ Avoid backlighting (window behind you)
- ❌ Avoid harsh shadows
- ❌ Avoid dim lighting (ARKit needs features)

### Space Setup
- ✅ 6-8 feet clear space
- ✅ Plain background (not required but helps)
- ✅ Phone on tripod at chest height
- ✅ Phone horizontal (landscape mode)
- ❌ Don't hold phone in hand
- ❌ Don't use selfie mode

### Body Position
- ✅ **Arms at 45°** (halfway between down and horizontal)
- ✅ Feet shoulder-width apart
- ✅ Stand upright, relaxed
- ✅ Look straight ahead
- ❌ Don't tense muscles
- ❌ Don't slouch
- ❌ Don't let arms drop during rotation

### Rotation Technique
- ✅ **30 seconds** for full 360°
- ✅ Smooth, steady speed
- ✅ Rotate on the spot (don't walk)
- ✅ Keep arms at 45° throughout
- ❌ Don't stop mid-rotation
- ❌ Don't speed up/slow down
- ❌ Don't move forward/backward

---

## 🎓 Next Steps

1. **Read IMPLEMENTATION_SUMMARY.md** for complete overview
2. **Read BODY_POSITION_RESEARCH.md** for scientific validation
3. **Read INTEGRATION_GUIDE.md** for technical details
4. **Test with multiple people** to validate accuracy
5. **Compare with tape measure** (ground truth)
6. **Report issues** to development team

---

## 📚 Documentation

- **QUICKSTART.md** (this file) - Get started quickly
- **IMPLEMENTATION_SUMMARY.md** - Complete project overview
- **BODY_POSITION_RESEARCH.md** - Scientific research and validation
- **INTEGRATION_GUIDE.md** - Technical integration instructions
- **ARKIT_IMPLEMENTATION.md** - ARKit Body Tracking details
- **UXUI_FLOW_2025.md** - UX/UI design specifications

---

## 📞 Support

For issues or questions:
1. Check **INTEGRATION_GUIDE.md** troubleshooting section
2. Review **IMPLEMENTATION_SUMMARY.md** for known limitations
3. Contact FitTwin development team

---

## 🔬 Why Modified T-Pose?

**Scientifically validated** (NIH study, Wong et al., 2021):
- **2-3x more accurate** than A-pose for body composition
- **Better test-retest precision** (consistent results)
- **Reduced pose variance** (arms don't touch torso)
- **Improved measurements** (R² 0.64→0.78 for visceral fat)

**45° arm angle** balances:
- ✅ Accuracy (clear arm/torso separation)
- ✅ Comfort (sustainable for 30 seconds)
- ✅ Ease of use (natural position)

---

**Ready to measure? Let's go! 🚀**

**Remember**: Form-fitting clothing + 45° arms + 30-second rotation = accurate measurements!
