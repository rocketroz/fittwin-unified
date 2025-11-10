//
//  ARBodyCaptureView_Enhanced.swift
//  FitTwinMeasure
//
//  Created on November 9, 2025
//  Enhanced SwiftUI view with audio guidance and arm position validation
//

import SwiftUI
import ARKit
import RealityKit

@available(iOS 13.0, *)
struct ARBodyCaptureView_Enhanced: View {
    @StateObject private var trackingManager = ARBodyTrackingManager()
    @StateObject private var audioManager = AudioGuidanceManager()
    @State private var armValidator = ArmPositionValidator()
    
    @State private var captureState: CaptureState = .idle
    @State private var measurements: BodyMeasurements?
    @State private var errorMessage: String?
    @State private var armPositionResult: ArmPositionValidator.ValidationResult?
    @State private var showSettings: Bool = false
    @State private var lastFeedbackTime: Date = .distantPast
    
    enum CaptureState {
        case idle
        case setup          // Clothing and distance check
        case positioning    // Getting into T-pose
        case ready          // Position validated, ready to start
        case countdown      // 3-2-1 countdown
        case capturing      // 360° rotation in progress
        case processing     // Calculating measurements
        case complete       // Results ready
    }
    
    var body: some View {
        ZStack {
            // AR View
            ARViewContainer(trackingManager: trackingManager)
                .edgesIgnoringSafeArea(.all)
            
            // Arm position overlay (visual feedback)
            if let result = armPositionResult, captureState == .positioning || captureState == .ready {
                armPositionOverlay(result: result)
            }
            
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
            print("🎬 ARBodyCaptureView_Enhanced appeared")
            checkSupport()
        }
        .onDisappear {
            print("👋 ARBodyCaptureView_Enhanced disappeared")
            trackingManager.stopSession()
            audioManager.cleanup()
        }
    }
    
    // MARK: - Top Status Bar
    
    private var topStatusBar: some View {
        HStack {
            VStack(spacing: 8) {
                // Body detection status
                HStack {
                    Circle()
                        .fill(trackingManager.isBodyDetected ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    
                    Text(trackingManager.isBodyDetected ? "Body Detected" : "No Body Detected")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(8)
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
                
                // Arm position status (during positioning)
                if captureState == .positioning || captureState == .ready {
                    if let result = armPositionResult {
                        HStack {
                            Circle()
                                .fill(result.isValid ? Color.green : Color.orange)
                                .frame(width: 12, height: 12)
                            
                            Text(armValidator.getOverlayMessage(for: result))
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                    }
                }
                
                // Capture progress
                if captureState == .capturing {
                    VStack(spacing: 4) {
                        ProgressView(value: trackingManager.captureProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            .frame(width: 200)
                        
                        Text("\(Int(trackingManager.captureProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Text("Rotation: \(Int(trackingManager.currentRotationAngle))°")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                }
            }
            
            Spacer()
            
            // Settings button
            Button(action: { showSettings.toggle() }) {
                Image(systemName: "gear")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Arm Position Overlay
    
    private func armPositionOverlay(result: ArmPositionValidator.ValidationResult) -> some View {
        let color = armValidator.getFeedbackColor(for: result)
        
        return Rectangle()
            .fill(Color(red: Double(color.red),
                       green: Double(color.green),
                       blue: Double(color.blue))
                .opacity(Double(color.alpha)))
            .edgesIgnoringSafeArea(.all)
            .allowsHitTesting(false)
    }
    
    // MARK: - Instructions
    
    private var instructionsView: some View {
        VStack(spacing: 12) {
            switch captureState {
            case .idle:
                instructionCard(
                    icon: "figure.stand",
                    title: "Ready to Capture",
                    steps: [
                        "Tap Start to begin setup",
                        "Follow voice instructions",
                        "Total time: 2-3 minutes"
                    ]
                )
                
            case .setup:
                instructionCard(
                    icon: "checkmark.circle",
                    title: "Setup Checklist",
                    steps: [
                        "✓ Wear form-fitting clothing",
                        "✓ Remove all accessories",
                        "✓ Stand 6-8 feet from camera",
                        "✓ Ensure full body is visible"
                    ]
                )
                
            case .positioning:
                instructionCard(
                    icon: "figure.arms.open",
                    title: "Modified T-Pose",
                    steps: [
                        "Feet shoulder-width apart",
                        "Arms at 45° from body",
                        "Palms facing down",
                        "Look straight ahead"
                    ]
                )
                
            case .ready:
                instructionCard(
                    icon: "checkmark.circle.fill",
                    title: "Perfect Position!",
                    steps: [
                        "Hold this position",
                        "Capture will start soon",
                        "Stay relaxed"
                    ]
                )
                
            case .countdown:
                VStack(spacing: 16) {
                    Text("Get Ready!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Starting in...")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(24)
                .background(Color.black.opacity(0.8))
                .cornerRadius(16)
                
            case .capturing:
                instructionCard(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Rotate 360°",
                    steps: [
                        "Rotate slowly to your left",
                        "Take 30 seconds for full rotation",
                        "Keep arms at 45° angle",
                        "Maintain steady speed"
                    ]
                )
                
            case .processing:
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("Processing measurements...")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("This may take a few seconds")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(24)
                .background(Color.black.opacity(0.8))
                .cornerRadius(16)
                
            case .complete:
                EmptyView()
            }
        }
    }
    
    private func instructionCard(icon: String, title: String, steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        if !step.hasPrefix("✓") {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        Text(step)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
        .frame(maxWidth: 300)
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        HStack(spacing: 20) {
            // Cancel button (during capture)
            if captureState == .capturing {
                Button(action: cancelCapture) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                }
            }
            
            // Main action button
            Button(action: mainAction) {
                ZStack {
                    Circle()
                        .fill(buttonColor)
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: buttonIcon)
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
            }
            .disabled(!canPerformAction)
            .opacity(canPerformAction ? 1.0 : 0.5)
        }
        .padding(.bottom, 20)
    }
    
    private var buttonColor: Color {
        switch captureState {
        case .idle:
            return .green
        case .setup, .positioning:
            return .blue
        case .ready:
            return .green
        case .countdown, .capturing:
            return .red
        case .processing:
            return .gray
        case .complete:
            return .blue
        }
    }
    
    private var buttonIcon: String {
        switch captureState {
        case .idle:
            return "play.fill"
        case .setup:
            return "arrow.right"
        case .positioning:
            return "figure.arms.open"
        case .ready:
            return "checkmark"
        case .countdown, .capturing:
            return "stop.fill"
        case .processing:
            return "hourglass"
        case .complete:
            return "arrow.clockwise"
        }
    }
    
    private var canPerformAction: Bool {
        switch captureState {
        case .idle:
            return trackingManager.isBodyDetected
        case .setup:
            return true
        case .positioning:
            return armValidator.isStableAndValid
        case .ready:
            return true
        case .countdown:
            return false
        case .capturing:
            return true
        case .processing:
            return false
        case .complete:
            return true
        }
    }
    
    // MARK: - Results View
    
    private func resultsView(measurements: BodyMeasurements) -> some View {
        VStack(spacing: 20) {
            Text("✅ Measurements Complete")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Quality score
            if let stats = armValidator.getStatistics() as ArmPositionValidator.ValidationStatistics? {
                HStack {
                    Text("Capture Quality:")
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(String(format: "%.0f%%", stats.qualityScore))
                        .fontWeight(.bold)
                        .foregroundColor(qualityColor(stats.qualityScore))
                }
                .font(.caption)
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            
            ScrollView {
                VStack(spacing: 12) {
                    measurementRow("Height", value: measurements.height_cm)
                    measurementRow("Shoulder Width", value: measurements.shoulder_width_cm)
                    measurementRow("Chest", value: measurements.chest_cm)
                    measurementRow("Waist", value: measurements.waist_natural_cm)
                    measurementRow("Hip", value: measurements.hip_low_cm)
                    measurementRow("Inseam", value: measurements.inseam_cm)
                    measurementRow("Outseam", value: measurements.outseam_cm)
                    measurementRow("Sleeve Length", value: measurements.sleeve_length_cm)
                    measurementRow("Neck", value: measurements.neck_cm)
                    measurementRow("Bicep", value: measurements.bicep_cm)
                    measurementRow("Forearm", value: measurements.forearm_cm)
                    measurementRow("Thigh", value: measurements.thigh_cm)
                    measurementRow("Calf", value: measurements.calf_cm)
                }
            }
            .frame(maxHeight: 400)
            
            HStack(spacing: 16) {
                Button("Export") {
                    exportMeasurements(measurements)
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("New Capture") {
                    resetCapture()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(24)
        .background(Color.black.opacity(0.9))
        .cornerRadius(20)
        .frame(maxWidth: 350)
    }
    
    private func measurementRow(_ name: String, value: Double) -> some View {
        HStack {
            Text(name)
                .foregroundColor(.white)
            Spacer()
            Text(String(format: "%.1f cm", value))
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func qualityColor(_ score: Float) -> Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .yellow
        } else {
            return .orange
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(message)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Dismiss") {
                errorMessage = nil
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(24)
        .background(Color.black.opacity(0.9))
        .cornerRadius(20)
        .frame(maxWidth: 300)
    }
    
    // MARK: - Settings View
    
    private var settingsView: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Audio toggle
            Toggle("Audio Guidance", isOn: $audioManager.isEnabled)
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            
            // Volume slider
            if audioManager.isEnabled {
                VStack(alignment: .leading) {
                    Text("Volume")
                        .foregroundColor(.white)
                    
                    Slider(value: $audioManager.volume, in: 0...1)
                        .accentColor(.blue)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button("Close") {
                showSettings = false
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(24)
        .background(Color.black.opacity(0.9))
        .cornerRadius(20)
        .frame(maxWidth: 300)
    }
    
    // MARK: - Actions
    
    private func checkSupport() {
        print("⚙️ Checking ARKit Body Tracking support...")
        
        if !ARBodyTrackingManager.isSupported() {
            print("❌ ARKit Body Tracking NOT supported")
            errorMessage = "ARKit Body Tracking is not supported on this device. Requires iPhone 12 Pro or later."
        } else {
            print("✅ ARKit Body Tracking supported")
            print("🚀 Starting AR session...")
            trackingManager.startSession()
            
            print("🔊 Announcing setup...")
            audioManager.announceSetup()
        }
    }
    
    private func mainAction() {
        switch captureState {
        case .idle:
            startSetup()
        case .setup:
            startPositioning()
        case .positioning:
            if armValidator.isStableAndValid {
                confirmPosition()
            }
        case .ready:
            startCountdown()
        case .capturing:
            stopCapture()
        case .complete:
            resetCapture()
        default:
            break
        }
    }
    
    private func startSetup() {
        captureState = .setup
        audioManager.announceClothingRequirements()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            audioManager.announceDistanceRequirement()
        }
    }
    
    private func startPositioning() {
        guard trackingManager.isBodyDetected else {
            errorMessage = "Please ensure your full body is visible in the camera view."
            audioManager.announceBodyNotVisible()
            return
        }
        
        captureState = .positioning
        audioManager.announcePositioning()
        
        // Start arm position validation loop
        startArmValidation()
    }
    
    private func startArmValidation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            guard captureState == .positioning || captureState == .ready else {
                timer.invalidate()
                return
            }
            
            // Get current skeleton from tracking manager
            guard let skeleton = trackingManager.currentSkeleton else {
                return
            }
            
            // Validate arm position
            let result = armValidator.validate(skeleton: skeleton)
            armPositionResult = result
            
            // Provide audio feedback (throttled to every 3 seconds)
            if !result.isValid {
                if Date().timeIntervalSince(lastFeedbackTime) > 3.0 {
                    audioManager.speak(result.feedback)
                    lastFeedbackTime = Date()
                }
            }
            
            // Check if ready
            if armValidator.isStableAndValid && captureState == .positioning {
                timer.invalidate()
                confirmPosition()
            }
        }
    }
    
    private func confirmPosition() {
        captureState = .ready
        audioManager.announcePerfectPosition()
    }
    
    private func startCountdown() {
        captureState = .countdown
        audioManager.announceCountdown()
        
        // Start capture after countdown
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            startCapture()
        }
    }
    
    private func startCapture() {
        print("📹 Starting capture...")
        captureState = .capturing
        trackingManager.startCapture()
        audioManager.announceStartRotation()
        
        // Timer-based progress fallback (ensures movement even if frames drop)
        let startTime = Date()
        var lastProgress: Double = 0
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            guard captureState == .capturing else {
                timer.invalidate()
                return
            }
            
            // Get frame-based progress from tracking manager
            let frameProgress = trackingManager.captureProgress
            
            // Calculate timer-based progress as fallback
            let elapsed = Date().timeIntervalSince(startTime)
            let timerProgress = min(elapsed / 30.0, 1.0)
            
            // Use the maximum of both (ensures progress always moves forward)
            let progress = max(frameProgress, timerProgress)
            
            print("📈 Progress: frame=\(Int(frameProgress * 100))%, timer=\(Int(timerProgress * 100))%, display=\(Int(progress * 100))%")
            
            // Announce milestones
            if lastProgress < 0.25 && progress >= 0.25 {
                print("🎯 25% milestone")
                audioManager.announceRotationProgress(0.25)
            } else if lastProgress < 0.50 && progress >= 0.50 {
                print("🎯 50% milestone")
                audioManager.announceRotationProgress(0.50)
            } else if lastProgress < 0.75 && progress >= 0.75 {
                print("🎯 75% milestone")
                audioManager.announceRotationProgress(0.75)
            }
            
            lastProgress = progress
        }
        
        // Auto-stop after 30 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
            if captureState == .capturing {
                stopCapture()
            }
        }
    }
    
    private func stopCapture() {
        print("⏹️ Stopping capture...")
        
        guard let captureResult = trackingManager.stopCapture() else {
            print("❌ Failed to capture data - no frames")
            errorMessage = "Failed to capture data. Please try again."
            audioManager.announceInsufficientData()
            captureState = .idle
            return
        }
        
        captureState = .processing
        audioManager.announceRotationComplete()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            audioManager.announceProcessing()
        }
        
        // Process measurements in background
        DispatchQueue.global(qos: .userInitiated).async {
            let measurements = ARKitMeasurementCalculator.calculateMeasurements(from: captureResult)
            
            DispatchQueue.main.async {
                self.measurements = measurements
                self.captureState = .complete
                self.audioManager.announceSuccess()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.audioManager.announceMeasurementResults(count: 13)
                }
            }
        }
    }
    
    private func cancelCapture() {
        _ = trackingManager.stopCapture()
        audioManager.stopSpeaking()
        captureState = .idle
    }
    
    private func resetCapture() {
        captureState = .idle
        measurements = nil
        armPositionResult = nil
        armValidator.reset()
        trackingManager.startSession()
        audioManager.announceSetup()
    }
    
    private func exportMeasurements(_ measurements: BodyMeasurements) {
        let stats = armValidator.getStatistics()
        
        let json: [String: Any] = [
            "measurements": [
                "height_cm": measurements.height_cm,
                "shoulder_width_cm": measurements.shoulder_width_cm,
                "chest_cm": measurements.chest_cm,
                "waist_natural_cm": measurements.waist_natural_cm,
                "hip_low_cm": measurements.hip_low_cm,
                "inseam_cm": measurements.inseam_cm,
                "outseam_cm": measurements.outseam_cm,
                "sleeve_length_cm": measurements.sleeve_length_cm,
                "neck_cm": measurements.neck_cm,
                "bicep_cm": measurements.bicep_cm,
                "forearm_cm": measurements.forearm_cm,
                "thigh_cm": measurements.thigh_cm,
                "calf_cm": measurements.calf_cm
            ],
            "metadata": [
                "timestamp": Date().timeIntervalSince1970,
                "capture_method": "arkit_body_tracking_modified_t_pose",
                "quality_score": stats.qualityScore,
                "valid_frames_percentage": stats.validPercentage,
                "average_arm_angle_left": stats.averageLeftAngle,
                "average_arm_angle_right": stats.averageRightAngle
            ]
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 Measurements JSON:")
            print(jsonString)
            
            // In production: save to file or send to API
        }
    }
}

// MARK: - Preview

@available(iOS 13.0, *)
struct ARBodyCaptureView_Enhanced_Previews: PreviewProvider {
    static var previews: some View {
        ARBodyCaptureView_Enhanced()
    }
}
