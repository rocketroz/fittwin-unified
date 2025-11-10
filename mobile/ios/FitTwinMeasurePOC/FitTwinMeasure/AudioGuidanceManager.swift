//
//  AudioGuidanceManager.swift
//  FitTwinMeasure
//
//  Created on November 9, 2025
//  Provides audio guidance and haptic feedback during body measurement capture
//

import AVFoundation
import CoreHaptics
import UIKit

/// Manages audio guidance and haptic feedback for measurement capture
@MainActor
class AudioGuidanceManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isEnabled: Bool = true
    @Published var volume: Float = 1.0
    @Published var currentPhase: CapturePhase = .setup
    
    // MARK: - Private Properties
    
    private let synthesizer = AVSpeechSynthesizer()
    private var hapticEngine: CHHapticEngine?
    private var lastSpokenText: String = ""
    private var lastSpokenTime: Date = .distantPast
    
    // Prevent duplicate announcements within 2 seconds
    private let minimumRepeatInterval: TimeInterval = 2.0
    
    // MARK: - Capture Phases
    
    enum CapturePhase {
        case setup          // Initial setup and clothing check
        case positioning    // Getting into correct pose
        case countdown      // 3-2-1 countdown
        case rotating       // During 360° rotation
        case processing     // After capture, processing data
        case complete       // Measurements ready
        case error          // Something went wrong
    }
    
    // MARK: - Initialization
    
    init() {
        setupAudioSession()
        setupHaptics()
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Haptics Setup
    
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Device doesn't support haptics")
            return
        }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Failed to setup haptic engine: \(error)")
        }
    }
    
    // MARK: - Speech Methods
    
    /// Speak text with optional haptic feedback
    func speak(_ text: String, withHaptic: Bool = false) {
        print("🔊 AudioManager.speak() called: \"(text)\"")
        print("   isEnabled: \(isEnabled), volume: \(volume)")
        
        guard isEnabled else {
            print("   ❌ Audio disabled")
            return
        }
        
        // Prevent duplicate announcements
        if text == lastSpokenText && Date().timeIntervalSince(lastSpokenTime) < minimumRepeatInterval {
            return
        }
        
        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // Slightly slower for clarity
        utterance.volume = volume
        
        print("   ✅ Calling synthesizer.speak()")
        synthesizer.speak(utterance)
        
        lastSpokenText = text
        lastSpokenTime = Date()
        
        if withHaptic {
            playHaptic(.success)
        }
    }
    
    /// Stop current speech
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    // MARK: - Phase-Specific Guidance
    
    // MARK: Setup Phase
    
    func announceSetup() {
        currentPhase = .setup
        speak("Welcome to FitTwin. Let's take your measurements.")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.announceClothingRequirements()
        }
    }
    
    func announceClothingRequirements() {
        speak("Please wear form-fitting clothing and remove all accessories.")
    }
    
    func announceDistanceRequirement() {
        speak("Stand 6 to 8 feet from your phone. Make sure your full body is visible on screen.")
    }
    
    // MARK: Positioning Phase
    
    func announcePositioning() {
        currentPhase = .positioning
        speak("Now, let's get you into position.")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.announceStance()
        }
    }
    
    func announceStance() {
        speak("Stand with feet shoulder-width apart.")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.announceArmPosition()
        }
    }
    
    func announceArmPosition() {
        speak("Extend your arms out to the sides at a 45-degree angle. Keep your palms facing down.")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            self.announceHeadPosition()
        }
    }
    
    func announceHeadPosition() {
        speak("Relax your shoulders and look straight ahead.")
    }
    
    func announceBodyDetected() {
        speak("Great! Hold this position.", withHaptic: true)
    }
    
    // MARK: Position Corrections
    
    func announceArmsTooLow() {
        speak("Raise your arms a bit higher.")
    }
    
    func announceArmsTooHigh() {
        speak("Lower your arms slightly.")
    }
    
    func announcePerfectPosition() {
        speak("Perfect position!", withHaptic: true)
    }
    
    func announceStepCloser() {
        speak("Please step a bit closer to the camera.")
    }
    
    func announceStepBack() {
        speak("Please step back a bit.")
    }
    
    func announceBodyNotVisible() {
        speak("I can't see your full body. Please adjust your position.")
    }
    
    // MARK: Countdown Phase
    
    func announceCountdown() {
        currentPhase = .countdown
        speak("Get ready. Starting in 3")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.speak("2")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            self.speak("1", withHaptic: true)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
            self.announceStartRotation()
        }
    }
    
    // MARK: Rotation Phase
    
    func announceStartRotation() {
        currentPhase = .rotating
        speak("Begin rotating slowly to your left.", withHaptic: true)
    }
    
    func announceRotationProgress(_ progress: Double) {
        switch progress {
        case 0.25:
            speak("Keep rotating. You're doing great.")
        case 0.50:
            speak("Halfway there. Maintain your arm position.")
        case 0.75:
            speak("Almost done. Keep your arms up.")
        default:
            break
        }
    }
    
    func announceRotationComplete() {
        speak("Perfect! You can relax now.", withHaptic: true)
    }
    
    func announceRotateFaster() {
        speak("Please rotate a bit faster.")
    }
    
    func announceRotateSlower() {
        speak("Please rotate more slowly.")
    }
    
    func announceKeepArmsSteady() {
        speak("Keep your arms steady.")
    }
    
    // MARK: Processing Phase
    
    func announceProcessing() {
        currentPhase = .processing
        speak("Processing your measurements. This will take a few seconds.")
    }
    
    // MARK: Completion Phase
    
    func announceSuccess() {
        currentPhase = .complete
        speak("Measurements complete!", withHaptic: true)
        playHaptic(.success)
    }
    
    func announceMeasurementResults(count: Int) {
        speak("We captured \(count) measurements. Tap to view your results.")
    }
    
    // MARK: Error Phase
    
    func announceError(_ message: String) {
        currentPhase = .error
        speak("Let's try that again. \(message)")
        playHaptic(.error)
    }
    
    func announceBodyLost() {
        speak("I lost track of your body. Please return to the starting position.")
    }
    
    func announceInsufficientData() {
        speak("I didn't capture enough data. Let's try again with a slower rotation.")
    }
    
    func announceLightingIssue() {
        speak("The lighting is too dim. Please move to a brighter area.")
    }
    
    // MARK: - Haptic Feedback
    
    enum HapticType {
        case success
        case warning
        case error
        case selection
        case impact
    }
    
    func playHaptic(_ type: HapticType) {
        guard let engine = hapticEngine else { return }
        
        var events: [CHHapticEvent] = []
        
        switch type {
        case .success:
            // Double tap pattern
            events = [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ], relativeTime: 0.1)
            ]
            
        case .warning:
            // Single medium tap
            events = [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ], relativeTime: 0)
            ]
            
        case .error:
            // Triple tap pattern
            events = [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ], relativeTime: 0.1),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ], relativeTime: 0.2)
            ]
            
        case .selection:
            // Light tap
            events = [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ], relativeTime: 0)
            ]
            
        case .impact:
            // Strong tap
            events = [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                ], relativeTime: 0)
            ]
        }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic: \(error)")
        }
    }
    
    // MARK: - Settings
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            stopSpeaking()
        }
    }
    
    func setVolume(_ newVolume: Float) {
        volume = max(0.0, min(1.0, newVolume))
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        stopSpeaking()
        hapticEngine?.stop()
    }
}

// MARK: - Convenience Extensions

extension AudioGuidanceManager {
    
    /// Quick announcement for common scenarios
    func announce(_ scenario: CommonScenario) {
        switch scenario {
        case .welcome:
            announceSetup()
        case .readyToCapture:
            announceBodyDetected()
        case .captureStarting:
            announceCountdown()
        case .captureInProgress:
            announceStartRotation()
        case .captureComplete:
            announceRotationComplete()
        case .processingData:
            announceProcessing()
        case .resultsReady:
            announceSuccess()
        }
    }
    
    enum CommonScenario {
        case welcome
        case readyToCapture
        case captureStarting
        case captureInProgress
        case captureComplete
        case processingData
        case resultsReady
    }
}

// MARK: - Accessibility Support

extension AudioGuidanceManager {
    
    /// Check if VoiceOver is running
    var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }
    
    /// Announce for accessibility (works with VoiceOver)
    func announceForAccessibility(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    /// Combined announcement (speech + VoiceOver)
    func announceUniversal(_ message: String, withHaptic: Bool = false) {
        if isVoiceOverRunning {
            announceForAccessibility(message)
        } else {
            speak(message, withHaptic: withHaptic)
        }
    }
}
