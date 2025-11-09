//
//  ArmPositionValidator.swift
//  FitTwinMeasure
//
//  Created on November 9, 2025
//  Validates arm position for Modified T-Pose (45° from body)
//

import ARKit
import simd

/// Validates arm position during capture to ensure Modified T-Pose compliance
class ArmPositionValidator {
    
    // MARK: - Constants
    
    /// Target arm angle from body (45° = Modified T-Pose)
    private let targetArmAngle: Float = 45.0
    
    /// Acceptable tolerance (±10°)
    private let angleTolerance: Float = 10.0
    
    /// Minimum confidence for joint detection
    private let minimumConfidence: Float = 0.7
    
    /// Number of consecutive valid frames required
    private let requiredValidFrames: Int = 10
    
    // MARK: - State Tracking
    
    private var consecutiveValidFrames: Int = 0
    private var lastValidationTime: Date = .distantPast
    private var validationHistory: [ValidationResult] = []
    
    // MARK: - Validation Result
    
    struct ValidationResult {
        let timestamp: Date
        let isValid: Bool
        let leftArmAngle: Float
        let rightArmAngle: Float
        let feedback: String
        
        var averageAngle: Float {
            (leftArmAngle + rightArmAngle) / 2.0
        }
    }
    
    enum ValidationStatus {
        case valid
        case armsTooLow
        case armsTooHigh
        case armsAsymmetric
        case lowConfidence
        case noBodyDetected
        
        var feedbackMessage: String {
            switch self {
            case .valid:
                return "Perfect position!"
            case .armsTooLow:
                return "Raise your arms a bit higher"
            case .armsTooHigh:
                return "Lower your arms slightly"
            case .armsAsymmetric:
                return "Keep both arms at the same height"
            case .lowConfidence:
                return "Move to better lighting"
            case .noBodyDetected:
                return "Step into view"
            }
        }
    }
    
    // MARK: - Main Validation Method
    
    /// Validate arm position from ARKit skeleton
    func validate(skeleton: ARSkeleton3D) -> ValidationResult {
        let timestamp = Date()
        
        // Get required joints
        guard let leftShoulder = getJoint(.leftShoulder, from: skeleton),
              let leftHand = getJoint(.leftHand, from: skeleton),
              let rightShoulder = getJoint(.rightShoulder, from: skeleton),
              let rightHand = getJoint(.rightHand, from: skeleton),
              let spine = getJoint(.spine, from: skeleton) else {
            return ValidationResult(
                timestamp: timestamp,
                isValid: false,
                leftArmAngle: 0,
                rightArmAngle: 0,
                feedback: ValidationStatus.noBodyDetected.feedbackMessage
            )
        }
        
        // Check confidence
        guard leftShoulder.confidence > minimumConfidence,
              leftHand.confidence > minimumConfidence,
              rightShoulder.confidence > minimumConfidence,
              rightHand.confidence > minimumConfidence else {
            return ValidationResult(
                timestamp: timestamp,
                isValid: false,
                leftArmAngle: 0,
                rightArmAngle: 0,
                feedback: ValidationStatus.lowConfidence.feedbackMessage
            )
        }
        
        // Calculate arm angles
        let leftArmAngle = calculateArmAngle(
            shoulder: leftShoulder.position,
            hand: leftHand.position,
            spine: spine.position
        )
        
        let rightArmAngle = calculateArmAngle(
            shoulder: rightShoulder.position,
            hand: rightHand.position,
            spine: spine.position
        )
        
        // Validate angles
        let status = validateAngles(left: leftArmAngle, right: rightArmAngle)
        let isValid = status == .valid
        
        // Update consecutive valid frames counter
        if isValid {
            consecutiveValidFrames += 1
        } else {
            consecutiveValidFrames = 0
        }
        
        let result = ValidationResult(
            timestamp: timestamp,
            isValid: isValid,
            leftArmAngle: leftArmAngle,
            rightArmAngle: rightArmAngle,
            feedback: status.feedbackMessage
        )
        
        // Store in history (keep last 100)
        validationHistory.append(result)
        if validationHistory.count > 100 {
            validationHistory.removeFirst()
        }
        
        lastValidationTime = timestamp
        
        return result
    }
    
    // MARK: - Angle Calculation
    
    /// Calculate arm angle from body (horizontal plane)
    private func calculateArmAngle(shoulder: simd_float3, hand: simd_float3, spine: simd_float3) -> Float {
        // Vector from shoulder to hand
        let armVector = hand - shoulder
        
        // Vector from spine to shoulder (body width direction)
        let bodyVector = shoulder - spine
        
        // Project arm vector onto horizontal plane (remove Y component)
        let armVectorHorizontal = simd_float3(armVector.x, 0, armVector.z)
        let bodyVectorHorizontal = simd_float3(bodyVector.x, 0, bodyVector.z)
        
        // Calculate angle between vectors
        let dotProduct = simd_dot(armVectorHorizontal, bodyVectorHorizontal)
        let magnitudeArm = simd_length(armVectorHorizontal)
        let magnitudeBody = simd_length(bodyVectorHorizontal)
        
        guard magnitudeArm > 0, magnitudeBody > 0 else {
            return 0
        }
        
        let cosAngle = dotProduct / (magnitudeArm * magnitudeBody)
        let angleRadians = acos(max(-1, min(1, cosAngle)))
        let angleDegrees = angleRadians * 180.0 / .pi
        
        return angleDegrees
    }
    
    // MARK: - Angle Validation
    
    private func validateAngles(left: Float, right: Float) -> ValidationStatus {
        let leftDiff = abs(left - targetArmAngle)
        let rightDiff = abs(right - targetArmAngle)
        let asymmetry = abs(left - right)
        
        // Check if both arms are within tolerance
        if leftDiff <= angleTolerance && rightDiff <= angleTolerance {
            // Check asymmetry (arms should be roughly equal)
            if asymmetry > 15.0 {
                return .armsAsymmetric
            }
            return .valid
        }
        
        // Determine if arms are too high or too low
        let averageAngle = (left + right) / 2.0
        
        if averageAngle < targetArmAngle - angleTolerance {
            return .armsTooLow
        } else if averageAngle > targetArmAngle + angleTolerance {
            return .armsTooHigh
        }
        
        return .armsAsymmetric
    }
    
    // MARK: - Helper Methods
    
    private func getJoint(_ name: ARSkeleton.JointName, from skeleton: ARSkeleton3D) -> (position: simd_float3, confidence: Float)? {
        guard skeleton.isJointTracked(name) else {
            return nil
        }
        
        let transform = skeleton.modelTransform(for: name)
        let position = simd_float3(transform?.columns.3.x ?? 0,
                                   transform?.columns.3.y ?? 0,
                                   transform?.columns.3.z ?? 0)
        
        // ARKit doesn't provide explicit confidence, so we estimate based on tracking
        let confidence: Float = 0.9 // Assume high confidence if tracked
        
        return (position, confidence)
    }
    
    // MARK: - Status Queries
    
    /// Check if position has been valid for required duration
    var isStableAndValid: Bool {
        consecutiveValidFrames >= requiredValidFrames
    }
    
    /// Get average angle over recent history
    func getAverageAngle(over seconds: TimeInterval = 1.0) -> Float? {
        let cutoffTime = Date().addingTimeInterval(-seconds)
        let recentResults = validationHistory.filter { $0.timestamp > cutoffTime }
        
        guard !recentResults.isEmpty else {
            return nil
        }
        
        let sum = recentResults.reduce(0.0) { $0 + $1.averageAngle }
        return sum / Float(recentResults.count)
    }
    
    /// Get validation statistics
    func getStatistics() -> ValidationStatistics {
        guard !validationHistory.isEmpty else {
            return ValidationStatistics(
                totalFrames: 0,
                validFrames: 0,
                validPercentage: 0,
                averageLeftAngle: 0,
                averageRightAngle: 0
            )
        }
        
        let validFrames = validationHistory.filter { $0.isValid }.count
        let totalFrames = validationHistory.count
        
        let avgLeft = validationHistory.reduce(0.0) { $0 + $1.leftArmAngle } / Float(totalFrames)
        let avgRight = validationHistory.reduce(0.0) { $0 + $1.rightArmAngle } / Float(totalFrames)
        
        return ValidationStatistics(
            totalFrames: totalFrames,
            validFrames: validFrames,
            validPercentage: Float(validFrames) / Float(totalFrames) * 100.0,
            averageLeftAngle: avgLeft,
            averageRightAngle: avgRight
        )
    }
    
    struct ValidationStatistics {
        let totalFrames: Int
        let validFrames: Int
        let validPercentage: Float
        let averageLeftAngle: Float
        let averageRightAngle: Float
        
        var qualityScore: Float {
            // Score from 0-100 based on valid percentage and angle accuracy
            let percentageScore = validPercentage
            let avgAngle = (averageLeftAngle + averageRightAngle) / 2.0
            let angleAccuracy = max(0, 100 - abs(avgAngle - 45.0) * 2)
            
            return (percentageScore + angleAccuracy) / 2.0
        }
    }
    
    // MARK: - Reset
    
    func reset() {
        consecutiveValidFrames = 0
        validationHistory.removeAll()
        lastValidationTime = .distantPast
    }
}

// MARK: - Visual Feedback Helper

extension ArmPositionValidator {
    
    /// Get color for visual feedback based on validation status
    func getFeedbackColor(for result: ValidationResult) -> (red: Float, green: Float, blue: Float, alpha: Float) {
        if result.isValid {
            return (0.0, 1.0, 0.0, 0.3) // Green
        } else {
            let avgAngle = result.averageAngle
            if avgAngle < targetArmAngle - angleTolerance {
                return (1.0, 0.5, 0.0, 0.3) // Orange (too low)
            } else if avgAngle > targetArmAngle + angleTolerance {
                return (1.0, 0.5, 0.0, 0.3) // Orange (too high)
            } else {
                return (1.0, 1.0, 0.0, 0.3) // Yellow (asymmetric)
            }
        }
    }
    
    /// Get overlay message for UI
    func getOverlayMessage(for result: ValidationResult) -> String {
        if isStableAndValid {
            return "✓ Ready to capture"
        } else if result.isValid {
            return "Hold steady... (\(consecutiveValidFrames)/\(requiredValidFrames))"
        } else {
            return result.feedback
        }
    }
}

// MARK: - Debug Information

extension ArmPositionValidator {
    
    func getDebugInfo(for result: ValidationResult) -> String {
        """
        Arm Position Debug:
        - Left Arm: \(String(format: "%.1f°", result.leftArmAngle))
        - Right Arm: \(String(format: "%.1f°", result.rightArmAngle))
        - Target: \(String(format: "%.1f°", targetArmAngle))
        - Tolerance: ±\(String(format: "%.1f°", angleTolerance))
        - Valid: \(result.isValid ? "YES" : "NO")
        - Consecutive Valid: \(consecutiveValidFrames)/\(requiredValidFrames)
        - Feedback: \(result.feedback)
        """
    }
}
