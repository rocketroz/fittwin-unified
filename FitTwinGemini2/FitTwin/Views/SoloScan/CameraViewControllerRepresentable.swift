import SwiftUI
import UIKit
import MediaPipeTasksVision

struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var landmarks: [NormalizedLandmark]

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CameraViewControllerDelegate {
        var parent: CameraViewControllerRepresentable

        init(_ parent: CameraViewControllerRepresentable) {
            self.parent = parent
        }

        func didUpdateLandmarks(_ landmarks: [NormalizedLandmark]) {
            parent.landmarks = landmarks
        }
    }
}