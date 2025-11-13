import Foundation
import UIKit
import MediaPipeTasksVision
import Combine

/// Service for detecting body pose using MediaPipe
@MainActor
class PoseDetectionService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentLandmarks: [Landmark] = []
    @Published var isProcessing = false
    @Published var error: PoseDetectionError?
    
    // MARK: - Private Properties
    private var poseLandmarker: PoseLandmarker?
    private let processingQueue = DispatchQueue(label: "com.fittwin.pose.processing")
    
    // MARK: - Configuration
    private let modelPath: String
    private let minDetectionConfidence: Float = 0.5
    private let minTrackingConfidence: Float = 0.5
    private let minPresenceConfidence: Float = 0.5
    
    // MARK: - Initialization
    
    init(modelPath: String = "pose_landmarker") {
        self.modelPath = modelPath
    }
    
    // MARK: - Setup
    
    func setup() throws {
        guard let modelPath = Bundle.main.path(forResource: modelPath, ofType: "task") else {
            throw PoseDetectionError.modelNotFound
        }
        
        let options = PoseLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .liveStream
        options.minPoseDetectionConfidence = minDetectionConfidence
        options.minPosePresenceConfidence = minPresenceConfidence
        options.minTrackingConfidence = minTrackingConfidence
        options.numPoses = 1 // Detect only one person
        options.poseLandmarkerLiveStreamDelegate = self
        
        do {
            poseLandmarker = try PoseLandmarker(options: options)
        } catch {
            throw PoseDetectionError.initializationFailed(error)
        }
    }
    
    // MARK: - Detection
    
    func detectPose(in image: UIImage, timestamp: Int) {
        guard let poseLandmarker = poseLandmarker else {
            error = .notInitialized
            return
        }
        
        guard let mpImage = try? MPImage(uiImage: image) else {
            error = .invalidImage
            return
        }
        
        isProcessing = true
        
        processingQueue.async { [weak self] in
            do {
                try poseLandmarker.detectAsync(image: mpImage, timestampInMilliseconds: timestamp)
            } catch {
                Task { @MainActor in
                    self?.error = .detectionFailed(error)
                    self?.isProcessing = false
                }
            }
        }
    }
    
    func detectPoseSync(in image: UIImage) -> [Landmark]? {
        guard let poseLandmarker = poseLandmarker else {
            return nil
        }
        
        guard let mpImage = try? MPImage(uiImage: image) else {
            return nil
        }
        
        do {
            let result = try poseLandmarker.detect(image: mpImage)
            return parseLandmarks(from: result)
        } catch {
            self.error = .detectionFailed(error)
            return nil
        }
    }
    
    // MARK: - Parsing
    
    private func parseLandmarks(from result: PoseLandmarkerResult) -> [Landmark] {
        guard let poseLandmarks = result.landmarks.first else {
            return []
        }
        
        return poseLandmarks.enumerated().map { index, landmark in
            Landmark(
                index: index,
                x: Double(landmark.x),
                y: Double(landmark.y),
                z: Double(landmark.z ?? 0),
                visibility: Double(landmark.visibility ?? 0),
                presence: Double(landmark.presence ?? 0)
            )
        }
    }
}

// MARK: - PoseLandmarkerLiveStreamDelegate

extension PoseDetectionService: PoseLandmarkerLiveStreamDelegate {
    
    nonisolated func poseLandmarker(
        _ poseLandmarker: PoseLandmarker,
        didFinishDetection result: PoseLandmarkerResult?,
        timestampInMilliseconds: Int,
        error: Error?
    ) {
        Task { @MainActor in
            self.isProcessing = false
            
            if let error = error {
                self.error = .detectionFailed(error)
                return
            }
            
            guard let result = result else {
                self.currentLandmarks = []
                return
            }
            
            self.currentLandmarks = parseLandmarks(from: result)
        }
    }
}

// MARK: - Errors

enum PoseDetectionError: LocalizedError {
    case modelNotFound
    case initializationFailed(Error)
    case notInitialized
    case invalidImage
    case detectionFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Pose detection model not found in app bundle"
        case .initializationFailed(let error):
            return "Failed to initialize pose detector: \(error.localizedDescription)"
        case .notInitialized:
            return "Pose detector not initialized. Call setup() first."
        case .invalidImage:
            return "Invalid image format for pose detection"
        case .detectionFailed(let error):
            return "Pose detection failed: \(error.localizedDescription)"
        }
    }
}
