import Foundation
import AVFoundation

/// Provides audio narration for guiding users through the measurement capture process
class AudioNarrator: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking: Bool = false
    @Published var hasPromptedVolume: Bool = false
    
    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    /// Speaks the given text with optional delay
    func speak(_ text: String, delay: TimeInterval = 0) {
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.speakNow(text)
            }
        } else {
            speakNow(text)
        }
    }
    
    private func speakNow(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // Slightly slower for clarity
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    /// Stop current speech
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    // MARK: - Predefined Narration Scripts
    
    func narrateVolumePrompt() {
        guard !hasPromptedVolume else { return }
        speak("Welcome to FitTwin. Please turn up your volume for audio guidance.")
        hasPromptedVolume = true
    }
    
    func narrateClothingInstructions() {
        speak("First, let's prepare. Wear form-fitting clothes like a fitted t-shirt and shorts or leggings. Avoid baggy clothing for best results.")
    }
    
    func narratePhonePlacement() {
        speak("Find a plain wall with good lighting. Place your phone on the floor, leaning against the wall. Tilt the top of your phone back about 15 to 20 degrees.")
    }
    
    func narratePhoneAngleCorrect() {
        speak("Great! Your phone angle is perfect.")
    }
    
    func narrateStepBack() {
        speak("Step back 6 to 8 feet from your phone.")
    }
    
    func narrateFrontPoseInstructions() {
        speak("Stand with your arms slightly away from your body. Match the body outline on screen.")
    }
    
    func narrateCountdown(seconds: Int) {
        speak("Hold still. Capturing in \(seconds)")
    }
    
    func narrateRotateInstruction() {
        speak("Perfect! Now rotate 90 degrees to your left.")
    }
    
    func narrateSidePoseInstructions() {
        speak("Match the side outline on screen. Keep your arms in the same position.")
    }
    
    func narrateProcessing() {
        speak("Excellent! Processing your measurements. This will take about 30 seconds.")
    }
    
    func narrateComplete() {
        speak("Success! Your digital twin is ready.")
    }
    
    func narrateError() {
        speak("Something went wrong. Please try again.")
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}
