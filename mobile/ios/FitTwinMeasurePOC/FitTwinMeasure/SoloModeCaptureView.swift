//
//  SoloModeCaptureView.swift
//  FitTwinMeasure
//
//  Created by FitTwin Team on 11/9/25.
//

import SwiftUI
import AVFoundation

struct SoloModeCaptureView: View {
    let placementMode: PlacementMode
    @StateObject private var poseProcessor = VisionPoseProcessor()
    @StateObject private var cameraManager = SoloCameraManager()
    @State private var captureState: CaptureState = .idle
    @State private var measurements: BodyMeasurements?
    @State private var errorMessage: String?
    @State private var captureProgress: Float = 0.0
    let onBack: () -> Void
    let onComplete: (BodyMeasurements) -> Void
    
    enum CaptureState {
        case idle
        case positioning
        case ready
        case countdown
        case capturing
        case processing
        case complete
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Camera preview
            CameraPreviewView(session: cameraManager.captureSession)
                .edgesIgnoringSafeArea(.all)
            
            // UI Overlay
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
            print("🎬 SoloModeCaptureView appeared")
            startCamera()
        }
        .onDisappear {
            print("👋 SoloModeCaptureView disappeared")
            stopCamera()
        }
    }
    
    // MARK: - Top Status Bar
    
    private var topStatusBar: some View {
        HStack {
            VStack(spacing: 8) {
                // Body detection status
                HStack {
                    Circle()
                        .fill(poseProcessor.isBodyDetected ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    
                    Text(poseProcessor.isBodyDetected ? "Body Detected" : "No Body Detected")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(8)
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
                
                // Distance status
                if poseProcessor.estimatedDistance > 0 {
                    HStack {
                        Image(systemName: "ruler")
                            .foregroundColor(.white)
                        
                        Text(String(format: "%.1f ft", poseProcessor.estimatedDistance * 3.28))
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                }
            }
            
            Spacer()
            
            // Back button
            Button(action: onBack) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Instructions View
    
    private var instructionsView: some View {
        VStack(spacing: 15) {
            Text(instructionText)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(Color.black.opacity(0.7))
                .cornerRadius(15)
            
            if captureState == .capturing {
                // Progress bar
                VStack(spacing: 10) {
                    ProgressView(value: captureProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        .frame(width: 200)
                    
                    Text("\(Int(captureProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(15)
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
            }
        }
    }
    
    private var instructionText: String {
        switch captureState {
        case .idle:
            return "Stand in front of camera"
        case .positioning:
            return "Extend arms to 45° (T-pose)"
        case .ready:
            return "Hold position - Ready to capture!"
        case .countdown:
            return "Starting in 3... 2... 1..."
        case .capturing:
            return "Rotate slowly 360°"
        case .processing:
            return "Processing measurements..."
        case .complete:
            return "Complete!"
        }
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 15) {
            if captureState == .idle || captureState == .positioning {
                Button(action: mainAction) {
                    Text(captureState == .idle ? "Start Positioning" : "Start Capture")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(poseProcessor.isBodyDetected ? Color.green : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!poseProcessor.isBodyDetected)
            } else if captureState == .capturing {
                Button(action: stopCapture) {
                    Text("Stop Capture")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Results View
    
    private func resultsView(measurements: BodyMeasurements) -> some View {
        ZStack {
            Color.black.opacity(0.9)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("✅ Measurements Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                ScrollView {
                    VStack(spacing: 15) {
                        measurementRow("Height", value: measurements.height, unit: "cm")
                        measurementRow("Shoulder Width", value: measurements.shoulderWidth, unit: "cm")
                        measurementRow("Inseam", value: measurements.inseam, unit: "cm")
                    }
                    .padding()
                }
                
                Button(action: {
                    onComplete(measurements)
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
    
    private func measurementRow(_ name: String, value: Float, unit: String) -> some View {
        HStack {
            Text(name)
                .foregroundColor(.white)
            Spacer()
            Text("\(String(format: "%.1f", value)) \(unit)")
                .foregroundColor(.green)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        ZStack {
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button(action: {
                    errorMessage = nil
                    captureState = .idle
                }) {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func startCamera() {
        print("📷 Starting front camera...")
        cameraManager.startSession()
        
        // Start processing frames
        cameraManager.onFrameCaptured = { pixelBuffer in
            poseProcessor.processFrame(pixelBuffer)
        }
    }
    
    private func stopCamera() {
        print("📷 Stopping camera...")
        cameraManager.stopSession()
    }
    
    private func mainAction() {
        switch captureState {
        case .idle:
            captureState = .positioning
        case .positioning:
            startCountdown()
        default:
            break
        }
    }
    
    private func startCountdown() {
        captureState = .countdown
        
        // TODO: Add countdown audio/visual
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            startCapture()
        }
    }
    
    private func startCapture() {
        print("📹 Starting capture...")
        captureState = .capturing
        captureProgress = 0.0
        
        // Simulate progress (in real implementation, track rotation)
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            guard captureState == .capturing else {
                timer.invalidate()
                return
            }
            
            captureProgress += 0.033  // ~30 seconds total
            
            if captureProgress >= 1.0 {
                timer.invalidate()
                stopCapture()
            }
        }
    }
    
    private func stopCapture() {
        print("⏹️ Stopping capture...")
        captureState = .processing
        
        // Extract measurements
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let extractedMeasurements = poseProcessor.extractMeasurements() {
                measurements = extractedMeasurements
                captureState = .complete
            } else {
                errorMessage = "Failed to extract measurements. Please try again."
                captureState = .idle
            }
        }
    }
}

// MARK: - Camera Manager

@MainActor
class SoloCameraManager: NSObject, ObservableObject {
    let captureSession = AVCaptureSession()
    private var videoOutput: AVCaptureVideoDataOutput?
    var onFrameCaptured: ((CVPixelBuffer) -> Void)?
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession.sessionPreset = .high
        
        // Use front camera
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("❌ Front camera not available")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            // Setup video output
            videoOutput = AVCaptureVideoDataOutput()
            videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            
            if let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            print("✅ Front camera setup complete")
            
        } catch {
            print("❌ Camera setup error: \(error.localizedDescription)")
        }
    }
    
    func startSession() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
}

extension SoloCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        Task { @MainActor in
            onFrameCaptured?(pixelBuffer)
        }
    }
}

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.previewLayer = previewLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

struct SoloModeCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        SoloModeCaptureView(
            placementMode: .ground,
            onBack: {},
            onComplete: { _ in }
        )
    }
}
