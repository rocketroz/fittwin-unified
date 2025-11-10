//
//  ARBodyCaptureView.swift
//  FitTwinMeasure
//
//  Created by Manus AI Agent on 2024-11-09.
//  SwiftUI view for ARKit body tracking capture
//

import SwiftUI
import ARKit
import RealityKit

@available(iOS 13.0, *)
struct ARBodyCaptureView: View {
    @StateObject private var trackingManager = ARBodyTrackingManager()
    @State private var captureState: CaptureState = .idle
    @State private var measurements: BodyMeasurements?
    @State private var errorMessage: String?
    
    enum CaptureState {
        case idle
        case preparing
        case capturing
        case processing
        case complete
    }
    
    var body: some View {
        ZStack {
            // AR View
            ARViewContainer(trackingManager: trackingManager)
                .edgesIgnoringSafeArea(.all)
            
            // Overlay UI
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
        }
        .onAppear {
            checkSupport()
        }
    }
    
    // MARK: - Top Status Bar
    
    private var topStatusBar: some View {
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
            
            // Capture progress
            if captureState == .capturing {
                VStack(spacing: 4) {
                    ProgressView(value: trackingManager.captureProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        .frame(width: 200)
                    
                    Text("\(Int(trackingManager.captureProgress * 100))% - Rotate slowly")
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
            
            // Tracking quality warning
            if let reason = trackingManager.trackingQuality {
                Text("⚠️ \(trackingQualityMessage(reason))")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
            }
        }
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
                        "Stand 6-8 feet from camera",
                        "Place phone on stand or tripod",
                        "Arms slightly away from body",
                        "Wear form-fitting clothing"
                    ]
                )
                
            case .preparing:
                instructionCard(
                    icon: "figure.walk",
                    title: "Get Ready",
                    steps: [
                        "Stand still and face the camera",
                        "Wait for body detection",
                        "Capture will start automatically"
                    ]
                )
                
            case .capturing:
                instructionCard(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Rotate 360°",
                    steps: [
                        "Rotate slowly to your left",
                        "Take 30 seconds for full rotation",
                        "Keep arms slightly away from body",
                        "Return to starting position"
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
                        Text("\(index + 1).")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
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
            // Cancel button
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
        case .idle, .preparing:
            return .green
        case .capturing:
            return .red
        case .processing:
            return .gray
        case .complete:
            return .blue
        }
    }
    
    private var buttonIcon: String {
        switch captureState {
        case .idle, .preparing:
            return "play.fill"
        case .capturing:
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
        case .preparing:
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
    
    // MARK: - Actions
    
    private func checkSupport() {
        if !ARBodyTrackingManager.isSupported() {
            errorMessage = "ARKit Body Tracking is not supported on this device. Requires iPhone 12 Pro or later."
        } else {
            trackingManager.startSession()
        }
    }
    
    private func mainAction() {
        switch captureState {
        case .idle:
            startCapture()
        case .capturing:
            stopCapture()
        case .complete:
            resetCapture()
        default:
            break
        }
    }
    
    private func startCapture() {
        guard trackingManager.isBodyDetected else {
            errorMessage = "Please ensure your full body is visible in the camera view."
            return
        }
        
        captureState = .preparing
        
        // Wait 3 seconds before starting
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            captureState = .capturing
            trackingManager.startCapture()
            
            // Auto-stop after 30 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                if captureState == .capturing {
                    stopCapture()
                }
            }
        }
    }
    
    private func stopCapture() {
        guard let captureResult = trackingManager.stopCapture() else {
            errorMessage = "Failed to capture data. Please try again."
            captureState = .idle
            return
        }
        
        captureState = .processing
        
        // Process measurements in background
        DispatchQueue.global(qos: .userInitiated).async {
            let measurements = ARKitMeasurementCalculator.calculateMeasurements(from: captureResult)
            
            DispatchQueue.main.async {
                self.measurements = measurements
                self.captureState = .complete
            }
        }
    }
    
    private func cancelCapture() {
        _ = trackingManager.stopCapture()
        captureState = .idle
    }
    
    private func resetCapture() {
        captureState = .idle
        measurements = nil
        trackingManager.startSession()
    }
    
    private func exportMeasurements(_ measurements: BodyMeasurements) {
        // Export as JSON
        let json: [String: Any] = [
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
            "calf_cm": measurements.calf_cm,
            "timestamp": Date().timeIntervalSince1970,
            "capture_method": "arkit_body_tracking"
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 Measurements JSON:")
            print(jsonString)
            
            // In production, save to file or send to API
            // For now, just print to console
        }
    }
    
    private func trackingQualityMessage(_ reason: ARCamera.TrackingState.Reason) -> String {
        switch reason {
        case .excessiveMotion:
            return "Move more slowly"
        case .insufficientFeatures:
            return "Point camera at more features"
        case .initializing:
            return "Initializing..."
        case .relocalizing:
            return "Relocalizing..."
        @unknown default:
            return "Tracking limited"
        }
    }
}

// MARK: - AR View Container

@available(iOS 13.0, *)
struct ARViewContainer: UIViewRepresentable {
    let trackingManager: ARBodyTrackingManager
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.session = trackingManager.arSession
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview

@available(iOS 13.0, *)
struct ARBodyCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        ARBodyCaptureView()
    }
}
