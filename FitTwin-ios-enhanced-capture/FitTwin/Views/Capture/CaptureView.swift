import SwiftUI
import AVFoundation

struct CaptureView: View {
    let viewType: ViewType
    let userHeight: Double
    let onComplete: ([Landmark], UIImage) -> Void
    
    @StateObject private var cameraManager = FrontCameraManager()
    @StateObject private var poseDetector = PoseDetectionService()
    @State private var captureState: CaptureState = .ready
    @State private var countdown: Int = 0
    @State private var capturedLandmarks: [Landmark] = []
    @State private var capturedImage: UIImage?
    
    enum ViewType {
        case front
        case side
        
        var title: String {
            switch self {
            case .front: return "Front View"
            case .side: return "Side View"
            }
        }
        
        var instruction: String {
            switch self {
            case .front: return "Face the camera with arms slightly away from body"
            case .side: return "Turn 90° to your right. Show your profile."
            }
        }
        
        var countdownSeconds: Int {
            switch self {
            case .front: return 10
            case .side: return 5
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Camera preview (full screen)
            CameraPreviewView(session: cameraManager.session)
                .ignoresSafeArea()
            
            // AR Overlay
            if captureState == .ready {
                BodyOutlineOverlay()
                    .stroke(Color.teal, lineWidth: 2)
                    .opacity(0.6)
            }
            
            // Pose landmarks overlay (for debugging/guidance)
            if !poseDetector.currentLandmarks.isEmpty {
                LandmarksOverlay(landmarks: poseDetector.currentLandmarks)
            }
            
            // UI Overlay
            VStack {
                // Top bar
                HStack {
                    Text(viewType.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                    Spacer()
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.6), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                Spacer()
                
                // Center - Countdown or instruction
                if case .countingDown(let count) = captureState {
                    Text("\(count)")
                        .font(.system(size: 120, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 8)
                } else if captureState == .ready {
                    VStack(spacing: 16) {
                        Text(viewType.instruction)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(12)
                            .shadow(radius: 4)
                        
                        if poseDetector.currentLandmarks.isEmpty {
                            Text("⚠️ Body not detected")
                                .font(.system(size: 16))
                                .foregroundColor(.yellow)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                        } else {
                            Text("✓ Body detected - Hold still")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                        }
                    }
                } else if captureState == .capturing {
                    Text("Capturing...")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                }
                
                Spacer()
                
                // Bottom - Start button
                if captureState == .ready {
                    Button(action: startCapture) {
                        Text("Start Capture")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(poseDetector.currentLandmarks.isEmpty ? Color.gray : Color.teal)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                    .disabled(poseDetector.currentLandmarks.isEmpty)
                }
            }
        }
        .onAppear {
            setupCamera()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    private func setupCamera() {
        cameraManager.checkPermissions { granted in
            if granted {
                cameraManager.startSession()
                
                // Setup pose detector
                do {
                    try poseDetector.setup()
                } catch {
                    print("Failed to setup pose detector: \(error)")
                }
                
                // Start processing frames
                startFrameProcessing()
            }
        }
    }
    
    private func startFrameProcessing() {
        // Process frames at 10 FPS for pose detection
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            guard captureState == .ready || captureState == .capturing else {
                timer.invalidate()
                return
            }
            
            if let frame = cameraManager.currentFrame {
                poseDetector.detectPose(in: frame, timestamp: Int(Date().timeIntervalSince1970 * 1000))
            }
        }
    }
    
    private func startCapture() {
        guard !poseDetector.currentLandmarks.isEmpty else { return }
        
        // Start countdown
        countdown = viewType.countdownSeconds
        captureState = .countingDown(countdown)
        
        // Speak countdown
        AudioNarrator.shared.speak("Starting in \(countdown) seconds. Hold still.")
        
        // Countdown timer
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            countdown -= 1
            
            if countdown > 0 {
                captureState = .countingDown(countdown)
                if countdown <= 3 {
                    AudioNarrator.shared.speak("\(countdown)")
                }
            } else {
                timer.invalidate()
                performCapture()
            }
        }
    }
    
    private func performCapture() {
        captureState = .capturing
        AudioNarrator.shared.speak("Capturing now")
        
        // Capture current frame and landmarks
        if let frame = cameraManager.currentFrame {
            capturedImage = frame
            capturedLandmarks = poseDetector.currentLandmarks
            
            // Wait a moment then complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                captureState = .complete
                if let image = capturedImage {
                    onComplete(capturedLandmarks, image)
                }
            }
        }
    }
}

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.previewLayer = previewLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = context.coordinator.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - Body Outline Overlay

struct BodyOutlineOverlay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Draw a simple body outline guide
        let centerX = rect.midX
        let topY = rect.height * 0.15
        let bottomY = rect.height * 0.85
        let width = rect.width * 0.4
        
        // Head
        path.addEllipse(in: CGRect(x: centerX - 30, y: topY, width: 60, height: 80))
        
        // Body
        path.move(to: CGPoint(x: centerX, y: topY + 80))
        path.addLine(to: CGPoint(x: centerX, y: bottomY - 200))
        
        // Arms
        path.move(to: CGPoint(x: centerX, y: topY + 120))
        path.addLine(to: CGPoint(x: centerX - width/2, y: topY + 250))
        
        path.move(to: CGPoint(x: centerX, y: topY + 120))
        path.addLine(to: CGPoint(x: centerX + width/2, y: topY + 250))
        
        // Legs
        path.move(to: CGPoint(x: centerX, y: bottomY - 200))
        path.addLine(to: CGPoint(x: centerX - 40, y: bottomY))
        
        path.move(to: CGPoint(x: centerX, y: bottomY - 200))
        path.addLine(to: CGPoint(x: centerX + 40, y: bottomY))
        
        return path
    }
}

// MARK: - Landmarks Overlay

struct LandmarksOverlay: View {
    let landmarks: [Landmark]
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(landmarks.indices, id: \.self) { index in
                let landmark = landmarks[index]
                if landmark.isValid {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .position(
                            x: CGFloat(landmark.x) * geometry.size.width,
                            y: CGFloat(landmark.y) * geometry.size.height
                        )
                }
            }
        }
    }
}

#Preview {
    CaptureView(viewType: .front, userHeight: 170.0) { landmarks, image in
        print("Captured \(landmarks.count) landmarks")
    }
}
