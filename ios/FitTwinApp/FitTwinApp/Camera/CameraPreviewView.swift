import SwiftUI
import AVFoundation

/// SwiftUI wrapper for AVCaptureVideoPreviewLayer
struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame when view size changes
        DispatchQueue.main.async {
            previewLayer.frame = uiView.bounds
        }
    }
}

/// Camera capture view with countdown and guidance
struct CameraCaptureView: View {
    @StateObject private var cameraManager = LiDARCameraManager()
    @Environment(\.dismiss) private var dismiss
    
    let captureMode: CaptureMode
    let onCapture: (UIImage, AVDepthData?) -> Void
    
    @State private var showingGuidance = true
    @State private var hasStartedCapture = false
    
    var body: some View {
        ZStack {
            // Camera preview
            if cameraManager.isSessionRunning {
                CameraPreviewView(previewLayer: cameraManager.getPreviewLayer())
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
            }
            
            // Guidance overlay
            VStack {
                Spacer()
                
                if showingGuidance {
                    guidanceView
                        .transition(.opacity)
                } else if cameraManager.isCountingDown {
                    countdownView
                        .transition(.scale)
                }
                
                Spacer()
                
                // Capture button
                if !hasStartedCapture {
                    Button(action: startCapture) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 4)
                                    .frame(width: 85, height: 85)
                            )
                    }
                    .padding(.bottom, 40)
                }
            }
            
            // Error overlay
            if let error = cameraManager.error {
                errorView(error: error)
            }
        }
        .task {
            do {
                try await cameraManager.setupSession()
                cameraManager.startSession()
            } catch {
                cameraManager.error = error as? CameraError ?? .captureError(error.localizedDescription)
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    // MARK: - Subviews
    
    private var guidanceView: some View {
        VStack(spacing: 16) {
            Text(captureMode.guidanceTitle)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(captureMode.guidanceText)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Body outline guide (simplified)
            bodyOutlineGuide
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.6))
        )
        .padding(.horizontal, 24)
    }
    
    private var bodyOutlineGuide: some View {
        ZStack {
            // Simple body outline
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 2, dash: [5]))
                .frame(width: 120, height: 300)
            
            // Head circle
            Circle()
                .stroke(Color.green, style: StrokeStyle(lineWidth: 2, dash: [5]))
                .frame(width: 40, height: 40)
                .offset(y: -140)
        }
    }
    
    private var countdownView: some View {
        VStack(spacing: 24) {
            Text("\(cameraManager.countdown)")
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 10)
            
            Text("Hold still...")
                .font(.title3)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 5)
        }
    }
    
    private func errorView(error: CameraError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Dismiss") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.8))
        )
        .padding(.horizontal, 24)
    }
    
    // MARK: - Actions
    
    private func startCapture() {
        withAnimation {
            showingGuidance = false
            hasStartedCapture = true
        }
        
        // Start countdown based on capture mode
        let countdownSeconds = captureMode == .front ? 10 : 5
        
        cameraManager.capturePhotoWithCountdown(seconds: countdownSeconds) { image, depthData in
            guard let image = image else { return }
            
            // Call completion handler
            onCapture(image, depthData)
            
            // Dismiss view
            dismiss()
        }
    }
}

// MARK: - Capture Mode

enum CaptureMode {
    case front
    case side
    
    var guidanceTitle: String {
        switch self {
        case .front:
            return "Front View"
        case .side:
            return "Side View"
        }
    }
    
    var guidanceText: String {
        switch self {
        case .front:
            return "Stand 6-8 feet from camera. Face forward with arms slightly away from body. Tap the button to start 10-second countdown."
        case .side:
            return "Turn 90° to your left. Stand with arms at your sides. Tap the button to start 5-second countdown."
        }
    }
}
