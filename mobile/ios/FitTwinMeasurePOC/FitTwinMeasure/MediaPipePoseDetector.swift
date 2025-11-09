import Foundation
import UIKit
import Vision

/// MediaPipe-compatible pose detector using Apple's Vision framework
/// Extracts 33 body landmarks compatible with MediaPipe Pose format
@MainActor
class MediaPipePoseDetector {
    
    // MARK: - Landmark Structure
    
    struct Landmark {
        let index: Int
        let x: Double      // Normalized [0, 1]
        let y: Double      // Normalized [0, 1]
        let z: Double      // Depth (normalized)
        let visibility: Double  // Confidence [0, 1]
    }
    
    struct PoseResult {
        let landmarks: [Landmark]
        let imageWidth: Int
        let imageHeight: Int
        let timestamp: Date
    }
    
    // MARK: - Detection
    
    func detectPose(in image: UIImage) async throws -> PoseResult {
        guard let cgImage = image.cgImage else {
            throw PoseError.invalidImage
        }
        
        // Create Vision request
        let request = VNDetectHumanBodyPoseRequest()
        request.revision = VNDetectHumanBodyPoseRequestRevision1
        
        // Perform detection
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        
        guard let observation = request.results?.first else {
            throw PoseError.noBodyDetected
        }
        
        // Extract landmarks
        let landmarks = try extractMediaPipeLandmarks(
            from: observation,
            imageWidth: Int(image.size.width),
            imageHeight: Int(image.size.height)
        )
        
        return PoseResult(
            landmarks: landmarks,
            imageWidth: Int(image.size.width),
            imageHeight: Int(image.size.height),
            timestamp: Date()
        )
    }
    
    // MARK: - Landmark Extraction
    
    private func extractMediaPipeLandmarks(
        from observation: VNHumanBodyPoseObservation,
        imageWidth: Int,
        imageHeight: Int
    ) throws -> [Landmark] {
        
        // Get all recognized points
        guard let recognizedPoints = try? observation.recognizedPoints(.all) else {
            throw PoseError.landmarkExtractionFailed
        }
        
        // MediaPipe Pose has 33 landmarks, Vision has 17 joints
        // We'll map Vision joints to MediaPipe indices and fill missing ones
        
        var landmarks: [Landmark] = []
        
        // MediaPipe landmark indices:
        // 0: nose
        // 1-10: face (eyes, ears, mouth) - Vision doesn't have these, use estimates
        // 11-12: shoulders
        // 13-14: elbows
        // 15-16: wrists
        // 17-22: hands (Vision doesn't have detailed hand landmarks)
        // 23-24: hips
        // 25-26: knees
        // 27-28: ankles
        // 29-32: feet
        
        // Helper to get point or nil
        func getPoint(_ jointName: VNHumanBodyPoseObservation.JointName) -> VNRecognizedPoint? {
            return recognizedPoints[jointName]
        }
        
        // Helper to create landmark
        func makeLandmark(index: Int, point: VNRecognizedPoint?) -> Landmark {
            if let point = point, point.confidence > 0.3 {
                return Landmark(
                    index: index,
                    x: Double(point.location.x),
                    y: 1.0 - Double(point.location.y),  // Flip Y (Vision uses bottom-left origin)
                    z: 0.0,  // Vision doesn't provide depth
                    visibility: Double(point.confidence)
                )
            } else {
                // Return invisible landmark at origin
                return Landmark(index: index, x: 0.5, y: 0.5, z: 0.0, visibility: 0.0)
            }
        }
        
        // 0: Nose (use neck as proxy since Vision doesn't have nose)
        landmarks.append(makeLandmark(index: 0, point: getPoint(.nose)))
        
        // 1-10: Face landmarks (not available in Vision, use estimates)
        for i in 1...10 {
            let nosePoint = getPoint(.nose)
            if let nose = nosePoint, nose.confidence > 0.3 {
                // Estimate face landmarks around nose position
                let offset = Double(i - 5) * 0.02  // Spread around nose
                landmarks.append(Landmark(
                    index: i,
                    x: Double(nose.location.x) + offset,
                    y: 1.0 - Double(nose.location.y),
                    z: 0.0,
                    visibility: Double(nose.confidence) * 0.5
                ))
            } else {
                landmarks.append(Landmark(index: i, x: 0.5, y: 0.2, z: 0.0, visibility: 0.0))
            }
        }
        
        // 11: Left shoulder
        landmarks.append(makeLandmark(index: 11, point: getPoint(.leftShoulder)))
        
        // 12: Right shoulder
        landmarks.append(makeLandmark(index: 12, point: getPoint(.rightShoulder)))
        
        // 13: Left elbow
        landmarks.append(makeLandmark(index: 13, point: getPoint(.leftElbow)))
        
        // 14: Right elbow
        landmarks.append(makeLandmark(index: 14, point: getPoint(.rightElbow)))
        
        // 15: Left wrist
        landmarks.append(makeLandmark(index: 15, point: getPoint(.leftWrist)))
        
        // 16: Right wrist
        landmarks.append(makeLandmark(index: 16, point: getPoint(.rightWrist)))
        
        // 17-22: Hand landmarks (not available, use wrist position)
        for i in 17...22 {
            let wristPoint = (i % 2 == 1) ? getPoint(.leftWrist) : getPoint(.rightWrist)
            landmarks.append(makeLandmark(index: i, point: wristPoint))
        }
        
        // 23: Left hip
        landmarks.append(makeLandmark(index: 23, point: getPoint(.leftHip)))
        
        // 24: Right hip
        landmarks.append(makeLandmark(index: 24, point: getPoint(.rightHip)))
        
        // 25: Left knee
        landmarks.append(makeLandmark(index: 25, point: getPoint(.leftKnee)))
        
        // 26: Right knee
        landmarks.append(makeLandmark(index: 26, point: getPoint(.rightKnee)))
        
        // 27: Left ankle
        landmarks.append(makeLandmark(index: 27, point: getPoint(.leftAnkle)))
        
        // 28: Right ankle
        landmarks.append(makeLandmark(index: 28, point: getPoint(.rightAnkle)))
        
        // 29-32: Foot landmarks (not available, use ankle position)
        for i in 29...32 {
            let anklePoint = (i % 2 == 1) ? getPoint(.leftAnkle) : getPoint(.rightAnkle)
            landmarks.append(makeLandmark(index: i, point: anklePoint))
        }
        
        return landmarks
    }
}

// MARK: - Errors

enum PoseError: LocalizedError {
    case invalidImage
    case noBodyDetected
    case landmarkExtractionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .noBodyDetected:
            return "No body detected in image. Please ensure full body is visible."
        case .landmarkExtractionFailed:
            return "Failed to extract body landmarks"
        }
    }
}
