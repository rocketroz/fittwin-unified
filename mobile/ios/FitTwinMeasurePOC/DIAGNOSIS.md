# Device Testing Issues - Root Cause Analysis

**Date**: November 9, 2025  
**Reporter**: User testing on physical iPhone device  
**Status**: Root causes identified

---

## Issues Reported

1. ❌ **No audio instructions playing**
2. ❌ **Progress bar not updating during rotation**
3. ❌ **Error: "ABPKPersonIDTracker portrait image is not support"**

---

## Root Cause Analysis

### Issue #1: Portrait Orientation Lock

**Problem**: App is locked to portrait-only mode

**Evidence** (`Info.plist` lines 38-41):
```xml
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>  ← ONLY PORTRAIT
</array>
```

**Impact**:
- ARKit Body Tracking has **limited support** for portrait orientation
- Error message "ABPKPersonIDTracker portrait image is not support" confirms this
- Body tracking quality is degraded in portrait mode
- Rotation tracking doesn't work properly in portrait

**Apple Documentation**:
- ARBodyTrackingConfiguration uses "rear-facing camera"
- Works best in **landscape orientation**
- Portrait mode is supported but with limitations

**Solution**:
Add landscape orientations to Info.plist:
```xml
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```

---

### Issue #2: Audio Not Playing

**Possible Causes**:

1. **MainActor Isolation**
   - `AudioGuidanceManager` is marked `@MainActor`
   - But it's being called from various contexts
   - May cause timing issues

2. **Audio Session Not Active**
   - `setupAudioSession()` is called in `init()`
   - But might fail silently
   - Need to verify audio session is actually active

3. **View Lifecycle**
   - Audio might be triggered before view appears
   - Or after view disappears
   - Need `.onAppear` trigger

4. **Silent Mode / Volume**
   - Device might be in silent mode
   - Volume might be 0
   - Need to check device settings

**Investigation Needed**:
- Add debug print statements to verify audio methods are called
- Check if `AVSpeechSynthesizer.speak()` is actually executing
- Verify audio session state
- Test with device NOT in silent mode

---

### Issue #3: Progress Bar Not Updating

**Problem**: `captureProgress` not updating during rotation

**Code Analysis** (`ARBodyTrackingManager.swift` lines 186-189):
```swift
// Update progress
let elapsed = lastCaptureTime
captureProgress = min(elapsed / captureDuration, 1.0)
```

**Dependency Chain**:
1. Progress depends on `lastCaptureTime`
2. `lastCaptureTime` updated in `captureFrame()`
3. `captureFrame()` called from `session(_:didUpdate:)` delegate
4. Delegate only fires if body anchor is detected
5. **Body detection fails in portrait mode**

**Why It Fails**:
- Portrait orientation → Poor body tracking
- No body anchor → No frame capture
- No frame capture → No progress update
- Progress stays at 0%

**Solution**:
1. Fix orientation (enable landscape)
2. OR: Decouple progress from frame capture (use timer-based progress)

---

## Recommended Fixes

### Priority 1: Enable Landscape Orientation

**File**: `Info.plist`

**Change**:
```xml
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```

**Impact**: Allows ARKit Body Tracking to work properly

---

### Priority 2: Add Audio Debugging

**File**: `AudioGuidanceManager.swift`

**Add to `speak()` method**:
```swift
func speak(_ text: String, withHaptic: Bool = false) {
    print("🔊 AudioManager.speak() called: \"\(text)\"")
    print("   isEnabled: \(isEnabled)")
    print("   volume: \(volume)")
    
    guard isEnabled else {
        print("   ❌ Audio disabled")
        return
    }
    
    // ... rest of method
    
    print("   ✅ Calling synthesizer.speak()")
    synthesizer.speak(utterance)
}
```

**Impact**: Helps diagnose why audio isn't playing

---

### Priority 3: Add Fallback Progress Tracking

**File**: `ARBodyCaptureView_Enhanced.swift`

**Add timer-based progress** (in addition to frame-based):
```swift
private func startCapture() {
    captureState = .capturing
    trackingManager.startCapture()
    audioManager.announceStartRotation()
    
    // Timer-based progress (fallback if frame capture fails)
    let startTime = Date()
    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
        guard captureState == .capturing else {
            timer.invalidate()
            return
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let timerProgress = min(elapsed / 30.0, 1.0)
        
        // Use max of frame-based and timer-based progress
        let frameProgress = trackingManager.captureProgress
        let displayProgress = max(frameProgress, timerProgress)
        
        // Update UI with displayProgress
        
        // Auto-stop at 100%
        if displayProgress >= 1.0 {
            timer.invalidate()
            stopCapture()
        }
    }
}
```

**Impact**: Progress bar updates even if frame capture fails

---

### Priority 4: Add .onAppear Audio Trigger

**File**: `ARBodyCaptureView_Enhanced.swift`

**Add to body**:
```swift
var body: some View {
    ZStack {
        // ... existing content
    }
    .onAppear {
        print("🎬 ARBodyCaptureView_Enhanced appeared")
        
        // Start AR session
        trackingManager.startSession()
        
        // Trigger welcome audio after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            audioManager.announceSetup()
        }
    }
    .onDisappear {
        print("👋 ARBodyCaptureView_Enhanced disappeared")
        trackingManager.stopSession()
        audioManager.stopSpeaking()
    }
}
```

**Impact**: Ensures audio plays when view is actually visible

---

## Testing Protocol

### Step 1: Enable Landscape

1. Update `Info.plist` with landscape orientations
2. Rebuild app
3. Rotate device to landscape
4. Check if "ABPKPersonIDTracker" error disappears

### Step 2: Test Audio

1. Ensure device is NOT in silent mode
2. Volume at 50%+
3. Launch app
4. Check Xcode console for "🔊 AudioManager.speak()" messages
5. If messages appear but no sound:
   - Check audio session state
   - Check AVSpeechSynthesizer status
6. If messages don't appear:
   - Audio methods not being called
   - Check view lifecycle

### Step 3: Test Progress

1. Start capture in landscape mode
2. Rotate slowly
3. Watch progress bar
4. Check Xcode console for "📸 Frame X captured" messages
5. If frames captured but progress not updating:
   - UI binding issue
6. If frames not captured:
   - Body tracking still failing
   - Check lighting and distance

---

## Expected Behavior After Fixes

### Landscape Mode
- ✅ No "ABPKPersonIDTracker" error
- ✅ Body tracking works reliably
- ✅ Frames captured every 1.5 seconds
- ✅ Progress bar updates 0-100%
- ✅ Rotation angle calculated correctly

### Audio
- ✅ Welcome message on launch
- ✅ Setup instructions
- ✅ Positioning guidance
- ✅ Countdown (3-2-1)
- ✅ Rotation milestones (25%, 50%, 75%)
- ✅ Completion announcement

### Progress Bar
- ✅ Updates smoothly from 0-100%
- ✅ Reflects actual rotation progress
- ✅ Auto-stops at 100%

---

## Additional Considerations

### User Experience

**With Landscape Orientation**:
- User places phone horizontally on tripod
- Screen is wider (better for full-body view)
- More natural for camera setup
- Matches professional body scanning apps

**Potential Issue**:
- UI might need adjustment for landscape layout
- Buttons and text might be misaligned
- Need to test UI in both orientations

**Solution**:
- Design UI to work in both portrait and landscape
- Or: Lock to landscape-only for AR capture view
- Keep portrait for main menu/results

---

## Next Steps

1. **Implement Priority 1 fix** (landscape orientation)
2. **Add debugging** (audio and progress logging)
3. **Test on device** with landscape orientation
4. **Report results** (does it fix the issues?)
5. **Implement remaining fixes** based on test results

---

## Questions for User

1. **Device orientation during testing**:
   - Was phone held vertically (portrait)?
   - Or horizontally (landscape)?

2. **Audio settings**:
   - Is device in silent mode?
   - What is volume level?
   - Any Bluetooth headphones connected?

3. **Console output**:
   - Do you see "📸 Frame X captured" messages?
   - Do you see "🔊 AudioManager.speak()" messages?
   - Any other error messages?

4. **Body detection**:
   - Does the body detection indicator turn green?
   - Or does it stay red/gray?

---

**Summary**: The root cause is likely **portrait orientation lock** causing ARKit Body Tracking to fail, which cascades into progress tracking failure. Audio issue needs further investigation with debug logging.
