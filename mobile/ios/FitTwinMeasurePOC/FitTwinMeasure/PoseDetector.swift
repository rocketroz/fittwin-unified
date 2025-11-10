import AVFoundation
import UIKit
import Vision

/// MediaPipe-style pose detection using Apple's Vision framework
/// Extracts 33 body landmarks compatible with MediaPipe Pose format
@MainActor
class PoseDetector: ObservableObject {
    
    // MARK: - Published Properties
    @Published var landmarks: [BodyLandmark] = []
    @Published var isProcessing = false
    @Published var error: Error?
    
    // MARK: - Pose Detection
    
    func detectPose(in image: UIImage) async throws -> [BodyLandmark] {
        isProcessing = true
        defer { isProcessing = false }
        
        guard let cgImage = image.cgImage else {
            throw PoseError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectHumanBodyPoseRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNHumanBodyPoseObservation],
                      let observation = observations.first else {
                    continuation.resume(throwing: PoseError.noPoseDetected)
                    return
                }
                
                do {
                    let landmarks = try self.extractLandmarks(from: observation, imageSize: image.size)
                    continuation.resume(returning: landmarks)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Landmark Extraction
    
    private func extractLandmarks(
        from observation: VNHumanBodyPoseObservation,
        imageSize: CGSize
    ) throws -> [BodyLandmark] {
        var landmarks: [BodyLandmark] = []
        
        // Map Vision joints to MediaPipe landmark indices
        let jointMapping: [(VNHumanBodyPoseObservation.JointName, Int)] = [
            // Head
            (.nose, 0),
            (.leftEye, 2),
            (.rightEye, 5),
            (.leftEar, 7),
            (.rightEar, 8),
            
            // Torso
            (.neck, 11),  // Approximation for left shoulder
            (.neck, 12),  // Approximation for right shoulder
            (.leftShoulder, 11),
            (.rightShoulder, 12),
            (.leftElbow, 13),
            (.rightElbow, 14),
            (.leftWrist, 15),
            (.rightWrist, 16),
            
            // Hips
            (.leftHip, 23),
            (.rightHip, 24),
            
            // Legs
            (.leftKnee, 25),
            (.rightKnee, 26),
            (.leftAnkle, 27),
            (.rightAnkle, 28),
        ]
        
        for (jointName, landmarkIndex) in jointMapping {
            if let point = try? observation.recognizedPoint(jointName),
               point.confidence > 0.3 {
                
                // Convert normalized coordinates to pixel coordinates
                let x = point.location.x * imageSize.width
                let y = (1 - point.location.y) * imageSize.height  // Flip Y axis
                
                let landmark = BodyLandmark(
                    index: landmarkIndex,
                    x: x,
                    y: y,
                    z: 0,  // Vision doesn't provide Z, will be estimated from depth data
                    visibility: Double(point.confidence)
                )
                
                landmarks.append(landmark)
            }
        }
        
        guard !landmarks.isEmpty else {
            throw PoseError.insufficientLandmarks
        }
        
        return landmarks.sorted { $0.index < $1.index }
    }
    
    // MARK: - Depth Integration
    
    /// Enhances 2D landmarks with depth information from LiDAR
    func enhanceLandmarksWithDepth(
        _ landmarks: [BodyLandmark],
        depthData: AVDepthData,
        imageSize: CGSize
    ) throws -> [BodyLandmark] {
        
        let depthMap = depthData.depthDataMap
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else {
            throw PoseError.invalidDepthData
        }
        
        let floatBuffer = baseAddress.assumingMemoryBound(to: Float32.self)
        
        return landmarks.map { landmark in
            // Convert landmark coordinates to depth map coordinates
            let depthX = Int((landmark.x / imageSize.width) * CGFloat(width))
            let depthY = Int((landmark.y / imageSize.height) * CGFloat(height))
            
            // Ensure coordinates are within bounds
            let clampedX = max(0, min(width - 1, depthX))
            let clampedY = max(0, min(height - 1, depthY))
            
            // Get depth value
            let depthIndex = clampedY * width + clampedX
            let depthValue = floatBuffer[depthIndex]
            
            // Create enhanced landmark with depth
            return BodyLandmark(
                index: landmark.index,
                x: landmark.x,
                y: landmark.y,
                z: Double(depthValue),
                visibility: landmark.visibility
            )
        }
    }
}

// MARK: - Body Landmark Model

struct BodyLandmark: Codable, Identifiable {
    var id: Int { index }
    let index: Int
    let x: Double
    let y: Double
    let z: Double
    let visibility: Double
    
    var point: CGPoint {
        CGPoint(x: x, y: y)
    }
}

// MARK: - Errors

enum PoseError: LocalizedError {
    case invalidImage
    case noPoseDetected
    case insufficientLandmarks
    case invalidDepthData
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .noPoseDetected:
            return "No person detected in image"
        case .insufficientLandmarks:
            return "Insufficient body landmarks detected"
        case .invalidDepthData:
            return "Invalid depth data"
        }
    }
}
