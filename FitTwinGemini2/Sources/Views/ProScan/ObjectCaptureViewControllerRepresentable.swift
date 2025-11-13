
import SwiftUI
import UIKit

struct ObjectCaptureViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ObjectCaptureViewController {
        return ObjectCaptureViewController()
    }

    func updateUIViewController(_ uiViewController: ObjectCaptureViewController, context: Context) {}
}
