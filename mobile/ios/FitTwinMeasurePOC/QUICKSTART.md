# FitTwin Measure - Quick Start Guide

## ⚡ Get Running in 5 Minutes

### Prerequisites
- ✅ Mac with Xcode 15+
- ✅ iPhone 12 Pro or newer (with LiDAR)
- ✅ USB cable

### Step 1: Download & Extract
```bash
# Download fittwin-ios-poc.zip
unzip fittwin-ios-poc.zip
cd fittwin-ios-poc
```

### Step 2: Open in Xcode
```bash
open FitTwinMeasure.xcodeproj
```

### Step 3: Configure Signing
1. Click **FitTwinMeasure** in project navigator
2. Select **FitTwinMeasure** target
3. Go to **Signing & Capabilities** tab
4. Under **Team**, select your Apple Developer account
5. Xcode will auto-generate provisioning profile

### Step 4: Connect Device
1. Connect iPhone via USB
2. Unlock iPhone
3. Trust computer if prompted
4. Select your iPhone in Xcode toolbar (top-left)

### Step 5: Build & Run
1. Click **Run** button (▶️) or press `⌘R`
2. Wait for build to complete
3. App will launch on your iPhone

### Step 6: Grant Permission
- Tap **Allow** when camera permission is requested

### Step 7: Take Measurements
1. Tap **"Start Measurement"**
2. **Front View**:
   - Stand 6 feet from camera
   - Face camera directly
   - Tap **"Start Capture"**
   - Wait for 10-second countdown
3. **Side View**:
   - Rotate 90° to your left
   - Stand sideways
   - Wait for 5-second countdown (auto-starts)
4. **View Results**:
   - See all 13 measurements
   - Tap **"Export"** to print JSON to Xcode console

## 🎯 What You'll See

### Measurements Displayed
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

## 🔍 Viewing Exported Data

**In Xcode Console** (⌘⇧Y):
```json
{
  "height_cm": 175.2,
  "shoulder_width_cm": 45.8,
  "chest_cm": 96.4,
  "waist_natural_cm": 81.2,
  "hip_low_cm": 98.6,
  "inseam_cm": 78.3,
  "outseam_cm": 102.5,
  "sleeve_length_cm": 61.7,
  "neck_cm": 38.4,
  "bicep_cm": 31.2,
  "forearm_cm": 26.8,
  "thigh_cm": 56.3,
  "calf_cm": 36.1
}
```

## ⚠️ Troubleshooting

### "No connected devices"
- Ensure iPhone is connected via USB
- Unlock iPhone
- Trust computer in iOS popup

### "Signing requires a development team"
- Add Apple ID in Xcode → Preferences → Accounts
- Select your team in Signing & Capabilities

### "Camera permission denied"
- Go to iPhone Settings → FitTwin Measure → Camera → Enable

### "LiDAR not available"
- App requires iPhone 12 Pro or newer
- Falls back to regular camera on older devices

### Measurements seem off
- Stand exactly 6 feet from camera
- Ensure good lighting
- Wear form-fitting clothing
- Stand still during countdown

## 📊 Testing Checklist

- [ ] App launches successfully
- [ ] Camera permission granted
- [ ] Front view countdown (10 sec) works
- [ ] Front photo captured
- [ ] Rotation instruction appears
- [ ] Side view countdown (5 sec) works
- [ ] Side photo captured
- [ ] Measurements display
- [ ] Values are reasonable (see README.md for ranges)
- [ ] Export prints JSON to console
- [ ] Reset button works

## 🎓 Next Steps

1. **Read README.md** for detailed documentation
2. **Read ALGORITHMS.md** for technical details
3. **Test with multiple people** to validate accuracy
4. **Compare with manual measurements** (tape measure)
5. **Report issues** to development team

## 💡 Tips for Best Results

### Lighting
- ✅ Bright, even lighting
- ✅ Natural daylight preferred
- ❌ Avoid backlighting
- ❌ Avoid harsh shadows

### Clothing
- ✅ Form-fitting clothes
- ✅ Solid colors
- ❌ Baggy clothing
- ❌ Busy patterns

### Positioning
- ✅ Stand upright, relaxed
- ✅ Arms slightly away from body
- ✅ Feet shoulder-width apart
- ❌ Don't slouch
- ❌ Don't tense muscles

### Camera Setup
- ✅ Mount phone on tripod or stable surface
- ✅ Camera at chest height
- ✅ Exactly 6 feet (1.8m) distance
- ❌ Don't hold phone in hand
- ❌ Don't use selfie mode

## 📞 Support

For issues or questions:
1. Check **README.md** troubleshooting section
2. Review **ALGORITHMS.md** for technical details
3. Contact FitTwin development team

---

**Ready to measure? Let's go! 🚀**
