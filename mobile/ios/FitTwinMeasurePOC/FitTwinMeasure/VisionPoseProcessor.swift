//
//  VisionPoseProcessor.swift
//  FitTwinMeasure
//
//  Created by FitTwin Team on 11/9/25.
//

import Foundation
import Vision
import AVFoundation
import CoreGraphics

/// Processes body poses using Vision framework
@MainActor
class VisionPoseProcessor: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isBodyDetected: Bool = false
    @Published var currentPose: VNHumanBodyPoseObservation?
    @Published var estimatedDistance: Float = 0.0
    
    // MARK: - Private Properties
    
    private var bodyPoseRequest: VNDetectHumanBodyPoseRequest?
    
    // Average human height in meters (for distance estimation)
    private let averageHeight: Float = 1.70
    
    // MARK: - Initialization
    
    init() {
        print("👁️ VisionPoseProcessor initialized")
        setupVisionRequest()
    }
    
    // MARK: - Setup
    
    private func setupVisionRequest() {
        bodyPoseRequest = VNDetectHumanBodyPoseRequest()
        bodyPoseRequest?.revision = VNDetectHumanBodyPoseRequestRevision1
    }
    
    // MARK: - Processing
    
    /// Process a video frame to detect body pose
    func processFrame(_ pixelBuffer: CVPixelBuffer) {
        guard let request = bodyPoseRequest else { return }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([request])
            
            if let observation = request.results?.first {
                // Update pose
                currentPose = observation
                isBodyDetected = true
                
                // Estimate distance
                estimatedDistance = estimateDistance(from: observation, imageSize: CGSize(
                    width: CVPixelBufferGetWidth(pixelBuffer),
                    height: CVPixelBufferGetHeight(pixelBuffer)
                ))
                
            } else {
                isBodyDetected = false
                currentPose = nil
            }
            
        } catch {
            print("❌ Vision request error: \(error.localizedDescription)")
            isBodyDetected = false
            currentPose = nil
        }
    }
    
    // MARK: - Distance Estimation
    
    /// Estimate distance from body size in frame
    private func estimateDistance(from observation: VNHumanBodyPoseObservation, imageSize: CGSize) -> Float {
        do {
            // Get key points
            let allPoints = try observation.recognizedPoints(.all)
            
            // Get head and ankle points to calculate body height in frame
            guard let headPoint = allPoints[.nose],
                  let leftAnkle = allPoints[.leftAnkle],
                  let rightAnkle = allPoints[.rightAnkle],
                  headPoint.confidence > 0.5,
                  (leftAnkle.confidence > 0.5 || rightAnkle.confidence > 0.5) else {
                return 0.0
            }
            
            // Use the ankle with higher confidence
            let anklePoint = leftAnkle.confidence > rightAnkle.confidence ? leftAnkle : rightAnkle
            
            // Calculate body height in normalized coordinates (0-1)
            let bodyHeightNormalized = abs(headPoint.location.y - anklePoint.location.y)
            
            // Convert to pixels
            let bodyHeightPixels = bodyHeightNormalized * imageSize.height
            
            // Estimate distance using similar triangles
            // Assuming iPhone front camera focal length ~2.71mm, sensor height ~4.8mm
            let focalLength: Float = 2.71
            let sensorHeight: Float = 4.8
            
            let bodyProportion = Float(bodyHeightPixels / imageSize.height)
            
            // distance = (realHeight * focalLength) / (bodyProportion * sensorHeight)
            let distance = (averageHeight * focalLength) / (bodyProportion * sensorHeight)
            
            return distance
            
        } catch {
            print("❌ Error calculating distance: \(error.localizedDescription)")
            return 0.0
        }
    }
    
    // MARK: - Arm Position Validation
    
    /// Validate arm position for T-pose (45° arms)
    func validateArmPosition() -> (isValid: Bool, leftAngle: Double?, rightAngle: Double?) {
        guard let pose = currentPose else {
            return (false, nil, nil)
        }
        
        do {
            let allPoints = try pose.recognizedPoints(.all)
            
            // Get required points
            guard let leftShoulder = allPoints[.leftShoulder],
                  let rightShoulder = allPoints[.rightShoulder],
                  let leftElbow = allPoints[.leftElbow],
                  let rightElbow = allPoints[.rightElbow],
                  leftShoulder.confidence > 0.5,
                  rightShoulder.confidence > 0.5,
                  leftElbow.confidence > 0.5,
                  rightElbow.confidence > 0.5 else {
                return (false, nil, nil)
            }
            
            // Calculate arm angles
            let leftAngle = calculateArmAngle(
                shoulder: leftShoulder.location,
                elbow: leftElbow.location
            )
            
            let rightAngle = calculateArmAngle(
                shoulder: rightShoulder.location,
                elbow: rightElbow.location
            )
            
            // Validate: arms should be at ~45° (±10°)
            let targetAngle: Double = 45.0
            let tolerance: Double = 10.0
            
            let leftValid = abs(leftAngle - targetAngle) < tolerance
            let rightValid = abs(rightAngle - targetAngle) < tolerance
            
            return (leftValid && rightValid, leftAngle, rightAngle)
            
        } catch {
            print("❌ Error validating arm position: \(error.localizedDescription)")
            return (false, nil, nil)
        }
    }
    
    /// Calculate arm angle from horizontal
    private func calculateArmAngle(shoulder: CGPoint, elbow: CGPoint) -> Double {
        let dx = elbow.x - shoulder.x
        let dy = elbow.y - shoulder.y
        
        let angleRadians = atan2(dy, dx)
        let angleDegrees = angleRadians * 180.0 / .pi
        
        // Convert to angle from horizontal (0° = horizontal, 90° = vertical)
        return abs(angleDegrees)
    }
    
    // MARK: - Measurement Extraction
    
    /// Extract body measurements from pose
    func extractMeasurements() -> BodyMeasurements? {
        guard let pose = currentPose, estimatedDistance > 0 else {
            print("❌ Cannot extract measurements: no pose or distance")
            return nil
        }
        
        do {
            let allPoints = try pose.recognizedPoints(.all)
            
            // Calculate measurements
            let height = calculateHeight(from: allPoints)
            let shoulderWidth = calculateShoulderWidth(from: allPoints)
            let inseam = calculateInseam(from: allPoints)
            
            // Create measurements object
            return BodyMeasurements(
                height: height,
                shoulderWidth: shoulderWidth,
                chest: 0, // Estimated from 2D (TODO)
                waist: 0, // Estimated from 2D (TODO)
                hip: 0, // Estimated from 2D (TODO)
                inseam: inseam,
                outseam: 0, // TODO
                sleeveLength: 0, // TODO
                neck: 0,
                bicep: 0,
                forearm: 0,
                thigh: 0,
                calf: 0
            )
            
        } catch {
            print("❌ Error extracting measurements: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func calculateHeight(from points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> Float {
        guard let nose = points[.nose],
              let leftAnkle = points[.leftAnkle],
              let rightAnkle = points[.rightAnkle],
              nose.confidence > 0.5,
              (leftAnkle.confidence > 0.5 || rightAnkle.confidence > 0.5) else {
            return 0
        }
        
        let ankle = leftAnkle.confidence > rightAnkle.confidence ? leftAnkle : rightAnkle
        
        // Calculate height in normalized coordinates
        let heightNormalized = abs(nose.location.y - ankle.location.y)
        
        // Scale by estimated distance (rough approximation)
        // This is a simplified calculation - in production you'd use camera calibration
        let height = Float(heightNormalized) * estimatedDistance * 1.2 // Adjustment factor
        
        return height * 100 // Convert to cm
    }
    
    private func calculateShoulderWidth(from points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> Float {
        guard let leftShoulder = points[.leftShoulder],
              let rightShoulder = points[.rightShoulder],
              leftShoulder.confidence > 0.5,
              rightShoulder.confidence > 0.5 else {
            return 0
        }
        
        let dx = leftShoulder.location.x - rightShoulder.location.x
        let dy = leftShoulder.location.y - rightShoulder.location.y
        let distance = sqrt(dx * dx + dy * dy)
        
        // Scale by estimated distance
        let width = Float(distance) * estimatedDistance
        
        return width * 100 // Convert to cm
    }
    
    private func calculateInseam(from points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> Float {
        guard let leftHip = points[.leftHip],
              let rightHip = points[.rightHip],
              let leftAnkle = points[.leftAnkle],
              let rightAnkle = points[.rightAnkle],
              leftHip.confidence > 0.5,
              rightHip.confidence > 0.5,
              (leftAnkle.confidence > 0.5 || rightAnkle.confidence > 0.5) else {
            return 0
        }
        
        // Use center of hips
        let hipCenterY = (leftHip.location.y + rightHip.location.y) / 2.0
        
        // Use ankle with higher confidence
        let ankle = leftAnkle.confidence > rightAnkle.confidence ? leftAnkle : rightAnkle
        
        let inseamNormalized = abs(hipCenterY - ankle.location.y)
        
        // Scale by estimated distance
        let inseam = Float(inseamNormalized) * estimatedDistance
        
        return inseam * 100 // Convert to cm
    }
}
