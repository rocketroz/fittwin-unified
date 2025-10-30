import SwiftUI
import AVFoundation

/// Camera preview view with countdown timer and visual guides
struct CameraPreviewView: View {
    
    @ObservedObject var cameraManager: LiDARCameraManager
    let captureType: CaptureType
    let countdown: Int?
    let onCapture: () -> Void
    
    enum CaptureType {
        case front
        case side
        
        var instruction: String {
            switch self {
            case .front:
                return "Stand 6-8 feet from camera\nFace the camera directly\nArms slightly away from body"
            case .side:
                return "Turn 90° to your left\nStand in profile view\nKeep arms at your sides"
            }
        }
        
        var guidanceImage: String {
            switch self {
            case .front:
                return "person.fill"
            case .side:
                return "person.fill.turn.right"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Camera preview
            if let previewLayer = cameraManager.previewLayer {
                CameraPreview(previewLayer: previewLayer)
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
            }
            
            // Overlay guides
            VStack {
                Spacer()
                
                // Visual guide silhouette
                Image(systemName: captureType.guidanceImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 400)
                    .foregroundColor(.white.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.green.opacity(0.5), lineWidth: 3)
                            .frame(height: 420)
                    )
                
                Spacer()
                
                // Instructions
                VStack(spacing: 12) {
                    Text(captureType.instruction)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.7))
                        )
                    
                    // Countdown
                    if let countdown = countdown, countdown > 0 {
                        Text("\(countdown)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(24)
                            .background(
                                Circle()
                                    .fill(Color.green.opacity(0.8))
                            )
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Camera Preview UIView Wrapper

struct CameraPreview: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            previewLayer.frame = uiView.bounds
        }
    }
}

// MARK: - Preview

#Preview {
    CameraPreviewView(
        cameraManager: LiDARCameraManager(),
        captureType: .front,
        countdown: 5,
        onCapture: {}
    )
}
