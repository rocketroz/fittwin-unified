
import Foundation
import CoreVideo
import MediaPipeTasksVision

protocol MediaPipeServiceDelegate: AnyObject {
    func didDetectLandmarks(_ landmarks: [NormalizedLandmark])
}

class MediaPipeService {
    private var poseLandmarker: PoseLandmarker?
    weak var delegate: MediaPipeServiceDelegate?

    init() {
        let options = PoseLandmarkerOptions()
        options.baseOptions.modelAssetPath = "pose_landmarker.task"
        options.runningMode = .video
        do {
            poseLandmarker = try PoseLandmarker(options: options)
        } catch {
            print("Failed to create PoseLandmarker: \(error)")
        }
    }

    func detect(frame: CVPixelBuffer) {
        let mpImage = MPImage(pixelBuffer: frame)
        do {
            let result = try poseLandmarker?.detect(videoFrame: mpImage, timestampInMilliseconds: Int(Date().timeIntervalSince1970 * 1000))
            if let landmarks = result?.landmarks.first {
                delegate?.didDetectLandmarks(landmarks)
            }
        } catch {
            print("Failed to detect landmarks: \(error)")
        }
    }
}
