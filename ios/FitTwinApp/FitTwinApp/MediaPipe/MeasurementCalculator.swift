import Foundation
import CoreGraphics

/// Calculates body measurements from MediaPipe-style landmarks
/// Based on formulas from docs/measurement_formulas.md
class MeasurementCalculator {
    
    // MARK: - Main Calculation
    
    /// Calculate all measurements from front and side view landmarks
    static func calculateMeasurements(
        frontLandmarks: [BodyLandmark],
        sideLandmarks: [BodyLandmark]?,
        referenceHeight: Double = 170.0  // cm
    ) -> BodyMeasurements {
        
        // Calculate pixels per cm ratio using height
        let pixelsPerCm = calculatePixelsPerCm(landmarks: frontLandmarks, referenceHeight: referenceHeight)
        
        // Calculate individual measurements
        let height = calculateHeight(landmarks: frontLandmarks, pixelsPerCm: pixelsPerCm)
        let shoulderWidth = calculateShoulderWidth(landmarks: frontLandmarks, pixelsPerCm: pixelsPerCm)
        let chest = calculateChest(frontLandmarks: frontLandmarks, sideLandmarks: sideLandmarks, pixelsPerCm: pixelsPerCm)
        let waist = calculateWaist(frontLandmarks: frontLandmarks, sideLandmarks: sideLandmarks, pixelsPerCm: pixelsPerCm)
        let hip = calculateHip(frontLandmarks: frontLandmarks, sideLandmarks: sideLandmarks, pixelsPerCm: pixelsPerCm)
        let inseam = calculateInseam(landmarks: frontLandmarks, pixelsPerCm: pixelsPerCm)
        let outseam = calculateOutseam(landmarks: frontLandmarks, pixelsPerCm: pixelsPerCm)
        let sleeveLength = calculateSleeveLength(landmarks: frontLandmarks, pixelsPerCm: pixelsPerCm)
        
        return BodyMeasurements(
            height_cm: height,
            shoulder_width_cm: shoulderWidth,
            chest_cm: chest,
            waist_natural_cm: waist,
            hip_low_cm: hip,
            inseam_cm: inseam,
            outseam_cm: outseam,
            sleeve_length_cm: sleeveLength,
            neck_cm: shoulderWidth * 0.4,  // Estimated from shoulder width
            bicep_cm: calculateBicep(landmarks: frontLandmarks, pixelsPerCm: pixelsPerCm),
            forearm_cm: calculateForearm(landmarks: frontLandmarks, pixelsPerCm: pixelsPerCm),
            thigh_cm: calculateThigh(landmarks: frontLandmarks, pixelsPerCm: pixelsPerCm),
            calf_cm: calculateCalf(landmarks: frontLandmarks, pixelsPerCm: pixelsPerCm)
        )
    }
    
    // MARK: - Helper Functions
    
    private static func calculatePixelsPerCm(landmarks: [BodyLandmark], referenceHeight: Double) -> Double {
        guard let nose = landmark(at: 0, in: landmarks),
              let leftAnkle = landmark(at: 27, in: landmarks),
              let rightAnkle = landmark(at: 28, in: landmarks) else {
            return 1.0
        }
        
        let ankleY = (leftAnkle.y + rightAnkle.y) / 2
        let heightPixels = abs(nose.y - ankleY)
        
        return heightPixels / referenceHeight
    }
    
    private static func calculateHeight(landmarks: [BodyLandmark], pixelsPerCm: Double) -> Double {
        guard let nose = landmark(at: 0, in: landmarks),
              let leftAnkle = landmark(at: 27, in: landmarks),
              let rightAnkle = landmark(at: 28, in: landmarks) else {
            return 0
        }
        
        let ankleY = (leftAnkle.y + rightAnkle.y) / 2
        let heightPixels = abs(nose.y - ankleY)
        
        return heightPixels / pixelsPerCm
    }
    
    private static func calculateShoulderWidth(landmarks: [BodyLandmark], pixelsPerCm: Double) -> Double {
        guard let leftShoulder = landmark(at: 11, in: landmarks),
              let rightShoulder = landmark(at: 12, in: landmarks) else {
            return 0
        }
        
        let distance = euclideanDistance(leftShoulder.point, rightShoulder.point)
        return distance / pixelsPerCm
    }
    
    private static func calculateChest(
        frontLandmarks: [BodyLandmark],
        sideLandmarks: [BodyLandmark]?,
        pixelsPerCm: Double
    ) -> Double {
        let shoulderWidth = calculateShoulderWidth(landmarks: frontLandmarks, pixelsPerCm: pixelsPerCm)
        let chestWidth = shoulderWidth * 1.1  // Chest is ~10% wider than shoulders
        
        // Estimate depth from side view if available, otherwise use approximation
        let chestDepth: Double
        if let sideLandmarks = sideLandmarks,
           let leftShoulder = landmark(at: 11, in: sideLandmarks),
           let rightShoulder = landmark(at: 12, in: sideLandmarks) {
            // Use Z-depth from side view
            chestDepth = abs(leftShoulder.z - rightShoulder.z) / pixelsPerCm * 1.2
        } else {
            chestDepth = chestWidth * 0.5  // Approximate depth as 50% of width
        }
        
        // Calculate ellipse circumference using Ramanujan's approximation
        return ellipseCircumference(a: chestWidth / 2, b: chestDepth / 2)
    }
    
    private static func calculateWaist(
        frontLandmarks: [BodyLandmark],
        sideLandmarks: [BodyLandmark]?,
        pixelsPerCm: Double
    ) -> Double {
        guard let leftHip = landmark(at: 23, in: frontLandmarks),
              let rightHip = landmark(at: 24, in: frontLandmarks) else {
            return 0
        }
        
        let hipWidth = euclideanDistance(leftHip.point, rightHip.point) / pixelsPerCm
        let waistWidth = hipWidth * 0.9  // Waist is narrower than hips
        
        let waistDepth: Double
        if let sideLandmarks = sideLandmarks,
           let leftHip = landmark(at: 23, in: sideLandmarks),
           let rightHip = landmark(at: 24, in: sideLandmarks) {
            waistDepth = abs(leftHip.z - rightHip.z) / pixelsPerCm * 0.85
        } else {
            waistDepth = waistWidth * 0.45
        }
        
        return ellipseCircumference(a: waistWidth / 2, b: waistDepth / 2)
    }
    
    private static func calculateHip(
        frontLandmarks: [BodyLandmark],
        sideLandmarks: [BodyLandmark]?,
        pixelsPerCm: Double
    ) -> Double {
        guard let leftHip = landmark(at: 23, in: frontLandmarks),
              let rightHip = landmark(at: 24, in: frontLandmarks) else {
            return 0
        }
        
        let hipWidth = euclideanDistance(leftHip.point, rightHip.point) / pixelsPerCm
        
        let hipDepth: Double
        if let sideLandmarks = sideLandmarks,
           let leftHip = landmark(at: 23, in: sideLandmarks),
           let rightHip = landmark(at: 24, in: sideLandmarks) {
            hipDepth = abs(leftHip.z - rightHip.z) / pixelsPerCm
        } else {
            hipDepth = hipWidth * 0.5
        }
        
        return ellipseCircumference(a: hipWidth / 2, b: hipDepth / 2)
    }
    
    private static func calculateInseam(landmarks: [BodyLandmark], pixelsPerCm: Double) -> Double {
        guard let leftAnkle = landmark(at: 27, in: landmarks),
              let leftHip = landmark(at: 23, in: landmarks) else {
            return 0
        }
        
        let distance = euclideanDistance(leftAnkle.point, leftHip.point)
        return distance / pixelsPerCm
    }
    
    private static func calculateOutseam(landmarks: [BodyLandmark], pixelsPerCm: Double) -> Double {
        guard let leftAnkle = landmark(at: 27, in: landmarks),
              let rightAnkle = landmark(at: 28, in: landmarks),
              let leftShoulder = landmark(at: 11, in: landmarks),
              let rightShoulder = landmark(at: 12, in: landmarks),
              let leftHip = landmark(at: 23, in: landmarks),
              let rightHip = landmark(at: 24, in: landmarks) else {
            return 0
        }
        
        let ankleY = (leftAnkle.y + rightAnkle.y) / 2
        let shoulderY = (leftShoulder.y + rightShoulder.y) / 2
        let hipY = (leftHip.y + rightHip.y) / 2
        let waistY = (shoulderY + hipY) / 2
        
        let outseamPixels = abs(ankleY - waistY)
        return outseamPixels / pixelsPerCm
    }
    
    private static func calculateSleeveLength(landmarks: [BodyLandmark], pixelsPerCm: Double) -> Double {
        guard let leftShoulder = landmark(at: 11, in: landmarks),
              let leftWrist = landmark(at: 15, in: landmarks) else {
            return 0
        }
        
        let distance = euclideanDistance(leftShoulder.point, leftWrist.point)
        return distance / pixelsPerCm
    }
    
    private static func calculateBicep(landmarks: [BodyLandmark], pixelsPerCm: Double) -> Double {
        guard let leftShoulder = landmark(at: 11, in: landmarks),
              let leftElbow = landmark(at: 13, in: landmarks) else {
            return 0
        }
        
        let length = euclideanDistance(leftShoulder.point, leftElbow.point) / pixelsPerCm
        return length * 0.3  // Circumference ≈ 30% of length
    }
    
    private static func calculateForearm(landmarks: [BodyLandmark], pixelsPerCm: Double) -> Double {
        guard let leftElbow = landmark(at: 13, in: landmarks),
              let leftWrist = landmark(at: 15, in: landmarks) else {
            return 0
        }
        
        let length = euclideanDistance(leftElbow.point, leftWrist.point) / pixelsPerCm
        return length * 0.25  // Circumference ≈ 25% of length
    }
    
    private static func calculateThigh(landmarks: [BodyLandmark], pixelsPerCm: Double) -> Double {
        guard let leftHip = landmark(at: 23, in: landmarks),
              let leftKnee = landmark(at: 25, in: landmarks) else {
            return 0
        }
        
        let length = euclideanDistance(leftHip.point, leftKnee.point) / pixelsPerCm
        return length * 0.35  // Circumference ≈ 35% of length
    }
    
    private static func calculateCalf(landmarks: [BodyLandmark], pixelsPerCm: Double) -> Double {
        guard let leftKnee = landmark(at: 25, in: landmarks),
              let leftAnkle = landmark(at: 27, in: landmarks) else {
            return 0
        }
        
        let length = euclideanDistance(leftKnee.point, leftAnkle.point) / pixelsPerCm
        return length * 0.25  // Circumference ≈ 25% of length
    }
    
    // MARK: - Utility Functions
    
    private static func landmark(at index: Int, in landmarks: [BodyLandmark]) -> BodyLandmark? {
        return landmarks.first { $0.index == index }
    }
    
    private static func euclideanDistance(_ p1: CGPoint, _ p2: CGPoint) -> Double {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Ramanujan's approximation for ellipse circumference
    private static func ellipseCircumference(a: Double, b: Double) -> Double {
        let h = pow((a - b), 2) / pow((a + b), 2)
        return .pi * (a + b) * (1 + (3 * h) / (10 + sqrt(4 - 3 * h)))
    }
}

// MARK: - Body Measurements Model

struct BodyMeasurements: Codable {
    let height_cm: Double
    let shoulder_width_cm: Double
    let chest_cm: Double
    let waist_natural_cm: Double
    let hip_low_cm: Double
    let inseam_cm: Double
    let outseam_cm: Double
    let sleeve_length_cm: Double
    let neck_cm: Double
    let bicep_cm: Double
    let forearm_cm: Double
    let thigh_cm: Double
    let calf_cm: Double
    
    var dictionary: [String: Double] {
        return [
            "height": height_cm,
            "shoulder_width": shoulder_width_cm,
            "chest": chest_cm,
            "waist": waist_natural_cm,
            "hip": hip_low_cm,
            "inseam": inseam_cm,
            "outseam": outseam_cm,
            "sleeve_length": sleeve_length_cm,
            "neck": neck_cm,
            "bicep": bicep_cm,
            "forearm": forearm_cm,
            "thigh": thigh_cm,
            "calf": calf_cm
        ]
    }
}
