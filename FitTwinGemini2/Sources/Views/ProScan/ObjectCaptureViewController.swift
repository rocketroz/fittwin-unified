
import UIKit
import RealityKit

@available(iOS 17.0, *)
class ObjectCaptureViewController: UIViewController {
    private var objectCaptureSession: ObjectCaptureSession?
    private var sessionTask: Task<Void, Error>?

    override func viewDidLoad() {
        super.viewDidLoad()
        startObjectCapture()
    }

    private func startObjectCapture() {
        guard ObjectCaptureSession.isSupported else {
            print("Object Capture is not supported on this device.")
            return
        }

        var configuration = ObjectCaptureSession.Configuration()
        // Configure as needed

        let session = ObjectCaptureSession(configuration: configuration)
        self.objectCaptureSession = session

        let view = ObjectCaptureView(session: session)
        self.view = view

        sessionTask = Task {
            do {
                let checkpointURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("checkpoint.usdz")
                for try await event in session.events {
                    switch event {
                    case .stateChanged(let state):
                        print("Session state changed to: \(state)")
                        if case .completed = state {
                            // Handle completion, e.g., by getting the model URL
                            // let modelURL = ...
                            // proMeasurementService.calculateFullMeasurements(from: modelURL)
                        }
                    default:
                        break
                    }
                }
            } catch {
                print("Object Capture session failed: \(error)")
            }
        }
    }
}
