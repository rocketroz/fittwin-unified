# Quick Start: Solo Mode Testing

**Status**: ✅ Ready to Test  
**Time to Test**: 5 minutes setup + 2 minutes per test

---

## Step 1: Update App Entry Point (30 seconds)

Open `FitTwinMeasureApp.swift` and change:

```swift
@main
struct FitTwinMeasureApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView_New()  // ← Change this line
        }
    }
}
```

---

## Step 2: Build and Run (2 minutes)

1. Clean build: **⇧⌘K**
2. Build: **⌘B**
3. Run on **physical device**: **⌘R**

⚠️ **MUST use physical device** - simulator doesn't have:
- CoreMotion sensors (for angle validation)
- Front camera
- Proper performance

---

## Step 3: Test Flow (2 minutes)

### 3.1 Mode Selection
- ✅ See "Solo Mode" (RECOMMENDED) and "Two Person Mode"
- ✅ Tap "Solo Mode"

### 3.2 Placement Selection
- ✅ See three options: Ground, Wall, Upright
- ✅ Tap "Ground Placement" (RECOMMENDED)

### 3.3 Angle Validation
- ✅ Place phone **flat on ground**
- ✅ Watch level indicator move
- ✅ See "Perfect angle! ✓" when flat
- ✅ Green checkmark appears
- ✅ Tap "Continue to Positioning"

### 3.4 Capture
- ✅ Step back **3-4 feet** from phone
- ✅ Body detection turns **green**
- ✅ Distance shows **~3-4 ft**
- ✅ Tap "Start Positioning"
- ✅ Extend arms to **45°** (T-pose)
- ✅ Tap "Start Capture"
- ✅ Countdown **3-2-1**
- ✅ Rotate slowly **360°** (30 seconds)
- ✅ Progress bar **0-100%**
- ✅ Auto-stops at completion

### 3.5 Results
- ✅ See measurements:
  - Height (cm)
  - Shoulder Width (cm)
  - Inseam (cm)
- ✅ Tap "Done"

---

## Expected Results

**If everything works**:
- ✅ Angle validation responds to phone tilt
- ✅ Body detection works (green indicator)
- ✅ Distance estimation shows reasonable value
- ✅ Measurements are within ±5 cm of tape measure

**If something fails**:
- Check Xcode console for error messages
- See troubleshooting section in SOLO_MODE_IMPLEMENTATION.md

---

## Quick Troubleshooting

### "No Body Detected" stays red
- Step back to 3-4 feet
- Ensure full body visible in frame
- Improve lighting

### Angle validation doesn't work
- Must use physical device (not simulator)
- Check console for CoreMotion errors

### Camera doesn't start
- Check camera permissions
- Restart app

---

## What to Test

**Priority 1** (Must work):
- [ ] Mode selection navigation
- [ ] Angle validation with sensors
- [ ] Body detection
- [ ] Camera preview

**Priority 2** (Should work):
- [ ] Distance estimation accuracy
- [ ] Measurement accuracy (compare to tape)
- [ ] UI responsiveness

**Priority 3** (Nice to have):
- [ ] Smooth animations
- [ ] Error handling
- [ ] Back navigation

---

## Report Findings

**What works**: ✅  
**What doesn't work**: ❌  
**Measurements vs tape measure**: ±X cm  
**Console errors**: (paste here)

---

**Time to test**: 2 minutes per run 🚀
