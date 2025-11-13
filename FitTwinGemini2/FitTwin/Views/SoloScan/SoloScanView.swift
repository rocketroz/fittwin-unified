import SwiftUI
import MediaPipeTasksVision

struct SoloScanView: View {
    @State private var userHeightCm: String = ""
    @State private var landmarks: [NormalizedLandmark] = []

    var body: some View {
        ZStack {
            CameraViewControllerRepresentable(landmarks: $landmarks)
                .edgesIgnoringSafeArea(.all)

            Canvas { context, size in
                for landmark in landmarks {
                    let point = CGPoint(x: CGFloat(landmark.x) * size.width, y: CGFloat(landmark.y) * size.height)
                    context.fill(Path(ellipseIn: CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)), with: .color(.red))
                }
            }

            VStack {
                Spacer()
                TextField("Enter your height in cm", text: $userHeightCm)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .padding()
            }
        }
    }
}