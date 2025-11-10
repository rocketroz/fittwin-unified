//
//  TwoPersonCaptureView.swift
//  FitTwinMeasure
//
//  Two Person Mode: Helper holds phone, subject rotates 360°
//  Uses ARKit Body Tracking (back camera + LiDAR) for best accuracy
//  Audio guidance coaches the subject through the process
//

import SwiftUI
import ARKit
import RealityKit

@available(iOS 13.0, *)
struct TwoPersonCaptureView: View {
    @StateObject private var trackingManager = ARBodyTrackingManager()
    @StateObject private var audioManager = AudioGuidanceManager()
    
    @State private var captureState: CaptureState = .idle
    @State private var measurements: BodyMeasurements?
    @State private var errorMessage: String?
    @State private var rotationProgress: Double = 0.0
    @State private var showSettings: Bool = false
    
    enum CaptureState {
        case idle
        case setup          // Initial setup and distance check
        case positioning    // Subject getting into T-pose
        case countdown      // 3-2-1 countdown
        case capturing      // 360° rotation in progress
        case processing     // Calculating measurements
        case complete       // Results ready
    }
    
    var body: some View {
        ZStack {
            // AR View (back camera)
            ARViewContainer(trackingManager: trackingManager)
                .edgesIgnoringSafeArea(.all)
            
            // Main UI
            VStack {
                // Top status bar
                topStatusBar
                
                Spacer()
                
                // Instructions
                if captureState != .complete {
                    instructionsView
                }
                
                Spacer()
                
                // Bottom controls
                bottomControls
            }
            .padding()
            
            // Results overlay
            if captureState == .complete, let measurements = measurements {
                resultsView(measurements: measurements)
            }
            
            // Error overlay
            if let errorMessage = errorMessage {
                errorView(message: errorMessage)
            }
            
            // Settings overlay
            if showSettings {
                settingsView
            }
        }
        .onAppear {
            checkSupport()
        }
        .onDisappear {
            trackingManager.stopSession()
            audioManager.cleanup()
        }
    }
    
    // MARK: - Top Status Bar
    
    private var topStatusBar: some View {
        HStack {
            // Body detection status
            HStack {
                Circle()
                    .fill(trackingManager.isBodyDetected ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(trackingManager.isBodyDetected ? "Body Detected" : "No Body")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding(8)
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)
            
            Spacer()
            
            // Settings button
            Button(action: { showSettings.toggle() }) {
                Image(systemName: "gear")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Instructions View
    
    private var instructionsView: some View {
        VStack(spacing: 16) {
            Text(stateTitle)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(stateInstructions)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Progress bar during capture
            if captureState == .capturing {
                VStack(spacing: 8) {
                    ProgressView(value: rotationProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        .frame(height: 8)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    
                    Text("\(Int(rotationProgress * 100))% Complete")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 32)
            }
        }
        .padding(24)
        .background(Color.black.opacity(0.7))
        .cornerRadius(16)
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        HStack(spacing: 20) {
            // Cancel button
            if captureState != .idle && captureState != .complete {
                Button(action: cancelCapture) {
                    Text("Cancel")
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(25)
                }
            }
            
            // Main action button
            Button(action: mainAction) {
                Text(mainButtonTitle)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(mainButtonColor)
                    .cornerRadius(25)
            }
            .disabled(!mainButtonEnabled)
        }
    }
    
    // MARK: - Results View
    
    private func resultsView(measurements: BodyMeasurements) -> some View {
        VStack(spacing: 20) {
            Text("Measurements Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    measurementRow("Height", "\(Int(measurements.height)) cm")
                    measurementRow("Shoulder Width", "\(Int(measurements.shoulderWidth)) cm")
                    measurementRow("Chest", "\(Int(measurements.chest)) cm")
                    measurementRow("Waist", "\(Int(measurements.waist)) cm")
                    measurementRow("Hip", "\(Int(measurements.hip)) cm")
                    measurementRow("Inseam", "\(Int(measurements.inseam)) cm")
                    measurementRow("Arm Length", "\(Int(measurements.armLength)) cm")
                }
                .padding()
            }
            
            HStack(spacing: 16) {
                Button("Export") {
                    exportMeasurements()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("New Capture") {
                    resetCapture()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding(32)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
    
    private func measurementRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.body)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text(message)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Button("Dismiss") {
                errorMessage = nil
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding(32)
        .background(Color.black.opacity(0.9))
        .cornerRadius(20)
    }
    
    // MARK: - Settings View
    
    private var settingsView: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.bold)
            
            Toggle("Audio Guidance", isOn: $audioManager.isEnabled)
            
            HStack {
                Text("Volume")
                Slider(value: $audioManager.volume, in: 0...1)
            }
            
            Button("Close") {
                showSettings = false
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding(32)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
    
    // MARK: - State Management
    
    private var stateTitle: String {
        switch captureState {
        case .idle: return "Two Person Mode"
        case .setup: return "Setup"
        case .positioning: return "Get Into Position"
        case .countdown: return "Get Ready!"
        case .capturing: return "Capturing..."
        case .processing: return "Processing..."
        case .complete: return "Complete!"
        }
    }
    
    private var stateInstructions: String {
        switch captureState {
        case .idle:
            return "Helper: Hold the phone steady\nSubject: Stand 6-8 feet away"
        case .setup:
            return "Remove bulky clothing and accessories\nStand on a clear, flat surface"
        case .positioning:
            return "Raise arms to 45° (halfway between down and horizontal)\nHold steady and look forward"
        case .countdown:
            return "Hold your position..."
        case .capturing:
            return "Slowly rotate 360° while keeping arms raised\nTake about 30 seconds for full rotation"
        case .processing:
            return "Analyzing body measurements..."
        case .complete:
            return "Your measurements are ready!"
        }
    }
    
    private var mainButtonTitle: String {
        switch captureState {
        case .idle: return "Start Setup"
        case .setup: return "I'm Ready"
        case .positioning: return "Start Countdown"
        case .countdown: return "Starting..."
        case .capturing: return "Capturing..."
        case .processing: return "Processing..."
        case .complete: return "Done"
        }
    }
    
    private var mainButtonColor: Color {
        mainButtonEnabled ? Color.green : Color.gray
    }
    
    private var mainButtonEnabled: Bool {
        switch captureState {
        case .idle: return true
        case .setup: return true
        case .positioning: return trackingManager.isBodyDetected
        case .countdown, .capturing, .processing: return false
        case .complete: return true
        }
    }
    
    // MARK: - Actions
    
    private func mainAction() {
        switch captureState {
        case .idle:
            startSetup()
        case .setup:
            startPositioning()
        case .positioning:
            startCountdown()
        case .complete:
            resetCapture()
        default:
            break
        }
    }
    
    private func checkSupport() {
        guard ARBodyTrackingConfiguration.isSupported else {
            errorMessage = "ARKit Body Tracking is not supported on this device. Requires iPhone 12 Pro or newer."
            return
        }
        
        audioManager.speak("Welcome to Two Person Mode. Helper, hold the phone steady. Subject, stand six to eight feet away.")
        captureState = .idle
    }
    
    private func startSetup() {
        captureState = .setup
        audioManager.speak("Please remove bulky clothing and accessories. Stand on a clear, flat surface. Tap I'm Ready when done.")
        trackingManager.startSession()
    }
    
    private func startPositioning() {
        captureState = .positioning
        audioManager.speak("Raise your arms to 45 degrees, halfway between down and horizontal. Hold steady and look forward.")
    }
    
    private func startCountdown() {
        captureState = .countdown
        audioManager.speak("Get ready. Three. Two. One.")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            startCapture()
        }
    }
    
    private func startCapture() {
        captureState = .capturing
        rotationProgress = 0.0
        trackingManager.startCapture()
        audioManager.speak("Start rotating slowly. Take about 30 seconds for a full circle.")
        
        // Simulate progress (in real implementation, track actual rotation)
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if captureState == .capturing {
                rotationProgress += 0.0167 // 30 seconds = 60 updates
                
                // Audio milestones
                if rotationProgress >= 0.25 && rotationProgress < 0.27 {
                    audioManager.speak("Quarter way done. Keep going.")
                } else if rotationProgress >= 0.50 && rotationProgress < 0.52 {
                    audioManager.speak("Halfway there. You're doing great.")
                } else if rotationProgress >= 0.75 && rotationProgress < 0.77 {
                    audioManager.speak("Almost done. Keep rotating.")
                }
                
                if rotationProgress >= 1.0 {
                    timer.invalidate()
                    stopCapture()
                }
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func stopCapture() {
        trackingManager.stopCapture()
        captureState = .processing
        audioManager.speak("Perfect! Processing your measurements.")
        
        // Process measurements
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if let result = trackingManager.measurements {
                measurements = result
                captureState = .complete
                audioManager.speak("Your measurements are ready!")
            } else {
                errorMessage = "Failed to capture measurements. Please try again."
                captureState = .idle
            }
        }
    }
    
    private func cancelCapture() {
        trackingManager.stopCapture()
        audioManager.speak("Capture cancelled.")
        resetCapture()
    }
    
    private func resetCapture() {
        captureState = .idle
        measurements = nil
        errorMessage = nil
        rotationProgress = 0.0
        trackingManager.stopSession()
    }
    
    private func exportMeasurements() {
        guard let measurements = measurements else { return }
        
        let jsonData = try? JSONEncoder().encode(measurements)
        if let jsonString = jsonData.flatMap({ String(data: $0, encoding: .utf8) }) {
            print("📊 Measurements JSON:\n\(jsonString)")
            // TODO: Implement actual export (share sheet, API upload, etc.)
        }
    }
}

// MARK: - AR View Container

struct ARViewContainer: UIViewRepresentable {
    let trackingManager: ARBodyTrackingManager
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        trackingManager.arSession = arView.session
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

// MARK: - Preview

struct TwoPersonCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        TwoPersonCaptureView()
    }
}
