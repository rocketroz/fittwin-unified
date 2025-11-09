# Device Testing Instructions

**Date**: November 9, 2025  
**Status**: Ready for Testing  
**Changes**: Integrated audio guidance and arm position validation

---

## What Changed

### ✅ Fixed Issues

1. **Audio Guidance Now Active**
   - ContentView now uses `ARBodyCaptureView_Enhanced` (not the old view)
   - Voice coaching will play throughout capture process
   - Haptic feedback on key events

2. **Arm Position Validation Working**
   - ARBodyTrackingManager now exposes `currentSkeleton`
   - Real-time validation of Modified T-Pose (45° arm angle)
   - Color-coded visual feedback (green/yellow/orange overlay)

3. **Better Error Handling**
   - More descriptive error messages
   - Capture validation improved

---

## How to Test

### Step 1: Rebuild the App

In Xcode:
1. **Clean build folder**: Product → Clean Build Folder (⇧⌘K)
2. **Rebuild**: Product → Build (⌘B)
3. **Run on device**: Product → Run (⌘R)

### Step 2: Setup Your Space

**Camera Setup** (IMPORTANT):
- ✅ Place iPhone on **tripod or stable surface**
- ✅ **Back camera** (with LiDAR) facing you
- ✅ Phone at **chest height**
- ✅ **6-8 feet** away from where you'll stand
- ✅ Landscape orientation (horizontal)
- ❌ Do NOT hold phone in hand
- ❌ Do NOT use front/selfie camera (no LiDAR there)

**Why back camera?**
- LiDAR sensor is only on the back of iPhone 12 Pro+
- ARKit Body Tracking requires LiDAR for accuracy
- Front camera doesn't have LiDAR (can't do body tracking)

**Lighting**:
- Bright, even lighting
- Natural daylight preferred
- Avoid backlighting (window behind you)

**Clothing**:
- Form-fitting athletic wear (compression tights, sports bra)
- Remove all accessories (watch, belt, jewelry)
- Tie up long hair

### Step 3: Run the Capture

**What You Should Hear/See:**

1. **Launch** → Audio: "Welcome to FitTwin. Let's take your measurements."

2. **Tap "Start"** → Audio: "Please wear form-fitting clothing and remove all accessories."

3. **Tap "Next"** → Audio: "Stand 6 to 8 feet from your phone."

4. **Positioning Phase**:
   - Audio: "Stand with feet shoulder-width apart"
   - Audio: "Extend your arms out to the sides at a 45-degree angle"
   - Audio: "Keep your palms facing down"
   - **Visual feedback**: Screen overlay changes color
     - 🟢 Green = Perfect position
     - 🟡 Yellow = Adjust slightly  
     - 🟠 Orange = Arms too high/low
   - Audio corrections: "Raise your arms a bit higher" or "Lower your arms slightly"
   - Audio: "Perfect position!" (with vibration)
   - Button turns green when ready

5. **Tap "Start Capture"** → Countdown begins:
   - Audio: "Get ready. Starting in 3... 2... 1..."
   - **Vibration** on "1"
   - Audio: "Begin rotating slowly to your left"

6. **Rotate 360°** (30 seconds):
   - Rotate counterclockwise (to your left)
   - Keep arms at 45° angle
   - Smooth, steady speed
   - Audio at 25%: "Keep rotating, you're doing great"
   - Audio at 50%: "Halfway there, maintain your arm position"
   - Audio at 75%: "Almost done, keep your arms up"
   - Progress bar shows 0-100%

7. **Completion**:
   - Audio: "Perfect! You can relax now" (with vibration)
   - Audio: "Processing your measurements..."
   - Audio: "Measurements complete!" (with vibration)

8. **Results**:
   - 13 measurements displayed
   - Quality score (0-100%)
   - Tap "Export" to see JSON in Xcode console

---

## Troubleshooting

### "Failed to capture data" Error

**Possible causes:**
1. **Rotation too fast** → Slow down to 30 seconds for full 360°
2. **Body went out of frame** → Stay in same spot, don't walk forward/backward
3. **Arms dropped during rotation** → Keep arms at 45° throughout
4. **Lighting too dim** → Move to brighter area
5. **Not enough frames captured** → Check Xcode console for frame count

**How to check:**
- Open Xcode console (⌘⇧Y)
- Look for messages like:
  - "📸 Frame 1 captured at 1.5s"
  - "📸 Frame 2 captured at 3.0s"
  - etc.
- Should see ~20 frames captured
- If you see "❌ No frames captured" → body wasn't detected during rotation

### No Audio Playing

**Check:**
1. Device volume (not muted)
2. Silent mode switch (off)
3. Tap gear icon → check "Audio Guidance" is enabled
4. Restart app

### Arms Not Validating (Stuck in Orange)

**Try:**
1. Arms at **45°** = halfway between straight down and horizontal
2. Both arms at **same height**
3. **Relax** shoulders (don't tense up)
4. Hold **steady** for 3 seconds
5. If still stuck, check Xcode console for validation messages

### Body Not Detected

**Check:**
1. Full body visible (head to feet)
2. 6-8 feet from camera
3. Good lighting (not too dim)
4. Not standing against blank wall (ARKit needs features)

---

## What to Look For

### ✅ Success Indicators

- [ ] Audio guidance plays at each phase
- [ ] Visual overlay changes color based on arm position
- [ ] Haptic vibrations on countdown and completion
- [ ] Progress bar updates smoothly 0-100%
- [ ] All 13 measurements display
- [ ] Quality score shows (hopefully >80%)
- [ ] Export prints JSON to console

### ⚠️ Issues to Report

- [ ] Audio doesn't play or cuts out
- [ ] Visual overlay stays red/orange even with correct position
- [ ] "Failed to capture data" error
- [ ] Measurements seem way off (>5 cm from tape measure)
- [ ] App crashes
- [ ] Quality score always low (<70%)

---

## Testing Checklist

### Pre-Capture
- [ ] App launches without crash
- [ ] Audio plays on launch
- [ ] Camera permission granted
- [ ] Body detection indicator turns green
- [ ] Settings button works

### Positioning
- [ ] Instructions show "Modified T-Pose"
- [ ] Visual overlay changes color
- [ ] Audio announces corrections
- [ ] Button enables after ~3 seconds of valid position

### Capture
- [ ] Countdown audio plays (3-2-1)
- [ ] Haptic vibration on "1"
- [ ] Progress bar updates
- [ ] Audio announces milestones (25%, 50%, 75%)
- [ ] Rotation completes without error

### Results
- [ ] Processing screen appears
- [ ] All 13 measurements display
- [ ] Quality score shows
- [ ] Values are reasonable (see expected ranges below)
- [ ] Export works (JSON in console)

---

## Expected Measurement Ranges

**Sanity check** (for average adult):

| Measurement | Typical Range | Your Value |
|-------------|---------------|------------|
| Height | 150-200 cm | ___ cm |
| Shoulder Width | 35-50 cm | ___ cm |
| Chest | 80-120 cm | ___ cm |
| Waist | 60-110 cm | ___ cm |
| Hip | 80-120 cm | ___ cm |
| Inseam | 65-90 cm | ___ cm |

If values are way outside these ranges, something went wrong.

---

## Xcode Console Messages

**What to look for in console (⌘⇧Y):**

### Good Signs ✅
```
🚀 Starting ARKit Body Tracking session...
✅ ARKit session started
✅ Body detected!
📹 Starting 360° capture...
📸 Frame 1 captured at 1.5s (progress: 5%)
📸 Frame 2 captured at 3.0s (progress: 10%)
...
📸 Frame 20 captured at 30.0s (progress: 100%)
✅ Capture complete!
⏹️ Stopping capture...
📊 Captured 20 frames
📊 Captured 15 depth maps
```

### Bad Signs ❌
```
❌ ARKit Body Tracking not supported on this device
❌ No frames captured
⚠️ Body lost!
❌ ARSession error: ...
```

---

## Validation Test

**Compare to tape measure:**

1. Measure yourself with tape measure (ground truth)
2. Capture with FitTwin app
3. Compare values
4. Calculate error: |App Value - Tape Measure Value|

**Expected accuracy:**
- Height: ±1 cm
- Chest/Waist/Hip: ±2-3 cm
- Inseam: ±2-3 cm
- Arm/Leg circumferences: ±3-4 cm

**If error is >5 cm**, report as issue with:
- Your tape measure value
- App's value
- Quality score
- Screenshots

---

## Next Steps After Testing

1. **If it works**: Report success! 🎉
   - Quality score achieved
   - Accuracy vs tape measure
   - Any UX feedback

2. **If issues**: Report with details:
   - Exact error message
   - Xcode console output (copy/paste)
   - Screenshots/video
   - Device model (iPhone 12 Pro, 13 Pro, etc.)
   - iOS version

---

## Quick Reference

**Arm Position (Modified T-Pose)**:
```
     \  |  /     ← Arms at 45° (halfway between down and horizontal)
      \ | /
       \|/
        O        ← Your body
       /|\
      / | \
```

**Rotation Direction**:
```
Start → Left (counterclockwise) → Back → Right → Front (complete)
  0°        90°                    180°    270°      360°
```

**Quality Score**:
- 90-100: Excellent ✅✅
- 80-89: Good ✅
- 70-79: Fair ⚠️
- <70: Recapture ❌

---

**Good luck with testing! 🚀**

**Remember**: Back camera (with LiDAR) on tripod, 6-8 feet away, form-fitting clothes, 45° arms, 30-second rotation!
