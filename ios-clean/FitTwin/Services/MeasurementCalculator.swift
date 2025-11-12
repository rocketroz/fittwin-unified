import Foundation
import CoreGraphics

/// Calculates body measurements from pose landmarks
class MeasurementCalculator {
    
    // MARK: - Calculate Measurements
    
    static func calculateMeasurements(
        frontLandmarks: [Landmark],
        sideLandmarks: [Landmark],
        userHeight: Double, // in cm
        imageSize: CGSize
    ) -> Measurements? {
        
        guard frontLandmarks.count == 33, sideLandmarks.count == 33 else {
            return nil
        }
        
        // Calculate scale factor from user's actual height
        let scaleFactor = calculateScaleFactor(
            landmarks: frontLandmarks,
            actualHeight: userHeight,
            imageSize: imageSize
        )
        
        // Calculate all measurements
        let height = userHeight // Use provided height
        let shoulderWidth = calculateShoulderWidth(frontLandmarks, scale: scaleFactor, imageSize: imageSize)
        let chestCircumference = calculateChestCircumference(frontLandmarks, sideLandmarks, scale: scaleFactor, imageSize: imageSize)
        let waistCircumference = calculateWaistCircumference(frontLandmarks, sideLandmarks, scale: scaleFactor, imageSize: imageSize)
        let hipCircumference = calculateHipCircumference(frontLandmarks, sideLandmarks, scale: scaleFactor, imageSize: imageSize)
        let inseam = calculateInseam(frontLandmarks, scale: scaleFactor, imageSize: imageSize)
        let armLength = calculateArmLength(frontLandmarks, scale: scaleFactor, imageSize: imageSize)
        
        // Additional measurements
        let neckCircumference = calculateNeckCircumference(frontLandmarks, sideLandmarks, scale: scaleFactor, imageSize: imageSize)
        let bicepCircumference = calculateBicepCircumference(frontLandmarks, sideLandmarks, scale: scaleFactor, imageSize: imageSize)
        let forearmCircumference = calculateForearmCircumference(frontLandmarks, sideLandmarks, scale: scaleFactor, imageSize: imageSize)
        let wristCircumference = calculateWristCircumference(frontLandmarks, sideLandmarks, scale: scaleFactor, imageSize: imageSize)
        let thighCircumference = calculateThighCircumference(frontLandmarks, sideLandmarks, scale: scaleFactor, imageSize: imageSize)
        let calfCircumference = calculateCalfCircumference(frontLandmarks, sideLandmarks, scale: scaleFactor, imageSize: imageSize)
        let ankleCircumference = calculateAnkleCircumference(frontLandmarks, sideLandmarks, scale: scaleFactor, imageSize: imageSize)
        
        // Lengths
        let torsoLength = calculateTorsoLength(frontLandmarks, scale: scaleFactor, imageSize: imageSize)
        let legLength = calculateLegLength(frontLandmarks, scale: scaleFactor, imageSize: imageSize)
        let armSpan = calculateArmSpan(frontLandmarks, scale: scaleFactor, imageSize: imageSize)
        
        // Widths
        let chestWidth = calculateChestWidth(frontLandmarks, scale: scaleFactor, imageSize: imageSize)
        let waistWidth = calculateWaistWidth(frontLandmarks, scale: scaleFactor, imageSize: imageSize)
        let hipWidth = calculateHipWidth(frontLandmarks, scale: scaleFactor, imageSize: imageSize)
        
        // Depths (from side view)
        let chestDepth = calculateChestDepth(sideLandmarks, scale: scaleFactor, imageSize: imageSize)
        let waistDepth = calculateWaistDepth(sideLandmarks, scale: scaleFactor, imageSize: imageSize)
        let hipDepth = calculateHipDepth(sideLandmarks, scale: scaleFactor, imageSize: imageSize)
        
        return Measurements(
            height: height,
            shoulderWidth: shoulderWidth,
            chestCircumference: chestCircumference,
            waistCircumference: waistCircumference,
            hipCircumference: hipCircumference,
            inseam: inseam,
            armLength: armLength,
            neckCircumference: neckCircumference,
            bicepCircumference: bicepCircumference,
            forearmCircumference: forearmCircumference,
            wristCircumference: wristCircumference,
            thighCircumference: thighCircumference,
            calfCircumference: calfCircumference,
            ankleCircumference: ankleCircumference,
            torsoLength: torsoLength,
            legLength: legLength,
            armSpan: armSpan,
            chestWidth: chestWidth,
            waistWidth: waistWidth,
            hipWidth: hipWidth,
            chestDepth: chestDepth,
            waistDepth: waistDepth,
            hipDepth: hipDepth
        )
    }
    
    // MARK: - Scale Factor
    
    private static func calculateScaleFactor(
        landmarks: [Landmark],
        actualHeight: Double,
        imageSize: CGSize
    ) -> Double {
        // Calculate pixel height from ankle to head
        let leftAnkle = landmarks[PoseLandmark.leftAnkle.rawValue]
        let rightAnkle = landmarks[PoseLandmark.rightAnkle.rawValue]
        let nose = landmarks[PoseLandmark.nose.rawValue]
        
        let ankleY = (leftAnkle.y + rightAnkle.y) / 2.0
        let headY = nose.y
        
        let pixelHeight = abs(ankleY - headY) * imageSize.height
        
        // Scale factor: cm per pixel
        return actualHeight / pixelHeight
    }
    
    // MARK: - Distance Calculations
    
    private static func distance2D(_ p1: Landmark, _ p2: Landmark, imageSize: CGSize) -> Double {
        let dx = (p1.x - p2.x) * imageSize.width
        let dy = (p1.y - p2.y) * imageSize.height
        return sqrt(dx * dx + dy * dy)
    }
    
    private static func distance3D(_ p1: Landmark, _ p2: Landmark, imageSize: CGSize) -> Double {
        let dx = (p1.x - p2.x) * imageSize.width
        let dy = (p1.y - p2.y) * imageSize.height
        let dz = (p1.z - p2.z) * imageSize.width // Use width as reference for depth
        return sqrt(dx * dx + dy * dy + dz * dz)
    }
    
    // MARK: - Primary Measurements
    
    private static func calculateShoulderWidth(_ landmarks: [Landmark], scale: Double, imageSize: CGSize) -> Double {
        let leftShoulder = landmarks[PoseLandmark.leftShoulder.rawValue]
        let rightShoulder = landmarks[PoseLandmark.rightShoulder.rawValue]
        let pixelDistance = distance2D(leftShoulder, rightShoulder, imageSize: imageSize)
        return pixelDistance * scale
    }
    
    private static func calculateChestCircumference(
        _ frontLandmarks: [Landmark],
        _ sideLandmarks: [Landmark],
        scale: Double,
        imageSize: CGSize
    ) -> Double {
        // Width from front view
        let width = calculateChestWidth(frontLandmarks, scale: scale, imageSize: imageSize)
        // Depth from side view
        let depth = calculateChestDepth(sideLandmarks, scale: scale, imageSize: imageSize)
        // Approximate circumference using ellipse formula
        return Double.pi * sqrt(2 * (width * width + depth * depth))
    }
    
    private static func calculateWaistCircumference(
        _ frontLandmarks: [Landmark],
        _ sideLandmarks: [Landmark],
        scale: Double,
        imageSize: CGSize
    ) -> Double {
        let width = calculateWaistWidth(frontLandmarks, scale: scale, imageSize: imageSize)
        let depth = calculateWaistDepth(sideLandmarks, scale: scale, imageSize: imageSize)
        return Double.pi * sqrt(2 * (width * width + depth * depth))
    }
    
    private static func calculateHipCircumference(
        _ frontLandmarks: [Landmark],
        _ sideLandmarks: [Landmark],
        scale: Double,
        imageSize: CGSize
    ) -> Double {
        let width = calculateHipWidth(frontLandmarks, scale: scale, imageSize: imageSize)
        let depth = calculateHipDepth(sideLandmarks, scale: scale, imageSize: imageSize)
        return Double.pi * sqrt(2 * (width * width + depth * depth))
    }
    
    private static func calculateInseam(_ landmarks: [Landmark], scale: Double, imageSize: CGSize) -> Double {
        let leftHip = landmarks[PoseLandmark.leftHip.rawValue]
        let leftAnkle = landmarks[PoseLandmark.leftAnkle.rawValue]
        let pixelDistance = distance2D(leftHip, leftAnkle, imageSize: imageSize)
        return pixelDistance * scale
    }
    
    private static func calculateArmLength(_ landmarks: [Landmark], scale: Double, imageSize: CGSize) -> Double {
        let leftShoulder = landmarks[PoseLandmark.leftShoulder.rawValue]
        let leftWrist = landmarks[PoseLandmark.leftWrist.rawValue]
        let pixelDistance = distance2D(leftShoulder, leftWrist, imageSize: imageSize)
        return pixelDistance * scale
    }
    
    // MARK: - Additional Measurements
    
    private static func calculateNeckCircumference(
        _ frontLandmarks: [Landmark],
        _ sideLandmarks: [Landmark],
        scale: Double,
        imageSize: CGSize
    ) -> Double {
        // Estimate from shoulder width
        let shoulderWidth = calculateShoulderWidth(frontLandmarks, scale: scale, imageSize: imageSize)
        return shoulderWidth * 0.4 // Approximate ratio
    }
    
    private static func calculateBicepCircumference(
        _ frontLandmarks: [Landmark],
        _ sideLandmarks: [Landmark],
        scale: Double,
        imageSize: CGSize
    ) -> Double {
        let leftShoulder = frontLandmarks[PoseLandmark.leftShoulder.rawValue]
        let leftElbow = frontLandmarks[PoseLandmark.leftElbow.rawValue]
        let armWidth = distance2D(leftShoulder, leftElbow, imageSize: imageSize) * 0.3
        return armWidth * scale * Double.pi
    }
    
    private static func calculateForearmCircumference(
        _ frontLandmarks: [Landmark],
        _ sideLandmarks: [Landmark],
        scale: Double,
        imageSize: CGSize
    ) -> Double {
        let leftElbow = frontLandmarks[PoseLandmark.leftElbow.rawValue]
        let leftWrist = frontLandmarks[PoseLandmark.leftWrist.rawValue]
        let forearmWidth = distance2D(leftElbow, leftWrist, imageSize: imageSize) * 0.25
        return forearmWidth * scale * Double.pi
    }
    
    private static func calculateWristCircumference(
        _ frontLandmarks: [Landmark],
        _ sideLandmarks: [Landmark],
        scale: Double,
        imageSize: CGSize
    ) -> Double {
        let leftWrist = frontLandmarks[PoseLandmark.leftWrist.rawValue]
        let leftPinky = frontLandmarks[PoseLandmark.leftPinky.rawValue]
        let wristWidth = distance2D(leftWrist, leftPinky, imageSize: imageSize) * 2.0
        return wristWidth * scale * Double.pi
    }
    
    private static func calculateThighCircumference(
        _ frontLandmarks: [Landmark],
        _ sideLandmarks: [Landmark],
        scale: Double,
        imageSize: CGSize
    ) -> Double {
        let leftHip = frontLandmarks[PoseLandmark.leftHip.rawValue]
        let leftKnee = frontLandmarks[PoseLandmark.leftKnee.rawValue]
        let thighWidth = distance2D(leftHip, leftKnee, imageSize: imageSize) * 0.35
        return thighWidth * scale * Double.pi
    }
    
    private static func calculateCalfCircumference(
        _ frontLandmarks: [Landmark],
        _ sideLandmarks: [Landmark],
        scale: Double,
        imageSize: CGSize
    ) -> Double {
        let leftKnee = frontLandmarks[PoseLandmark.leftKnee.rawValue]
        let leftAnkle = frontLandmarks[PoseLandmark.leftAnkle.rawValue]
        let calfWidth = distance2D(leftKnee, leftAnkle, imageSize: imageSize) * 0.3
        return calfWidth * scale * Double.pi
    }
    
    private static func calculateAnkleCircumference(
        _ frontLandmarks: [Landmark],
        _ sideLandmarks: [Landmark],
        scale: Double,
        imageSize: CGSize
    ) -> Double {
        let leftAnkle = frontLandmarks[PoseLandmark.leftAnkle.rawValue]
        let leftHeel = frontLandmarks[PoseLandmark.leftHeel.rawValue]
        let ankleWidth = distance2D(leftAnkle, leftHeel, imageSize: imageSize) * 1.5
        return ankleWidth * scale * Double.pi
    }
    
    // MARK: - Lengths
    
    private static func calculateTorsoLength(_ landmarks: [Landmark], scale: Double, imageSize: CGSize) -> Double {
        let leftShoulder = landmarks[PoseLandmark.leftShoulder.rawValue]
        let leftHip = landmarks[PoseLandmark.leftHip.rawValue]
        let pixelDistance = distance2D(leftShoulder, leftHip, imageSize: imageSize)
        return pixelDistance * scale
    }
    
    private static func calculateLegLength(_ landmarks: [Landmark], scale: Double, imageSize: CGSize) -> Double {
        let leftHip = landmarks[PoseLandmark.leftHip.rawValue]
        let leftAnkle = landmarks[PoseLandmark.leftAnkle.rawValue]
        let pixelDistance = distance2D(leftHip, leftAnkle, imageSize: imageSize)
        return pixelDistance * scale
    }
    
    private static func calculateArmSpan(_ landmarks: [Landmark], scale: Double, imageSize: CGSize) -> Double {
        let leftWrist = landmarks[PoseLandmark.leftWrist.rawValue]
        let rightWrist = landmarks[PoseLandmark.rightWrist.rawValue]
        let pixelDistance = distance2D(leftWrist, rightWrist, imageSize: imageSize)
        return pixelDistance * scale
    }
    
    // MARK: - Widths
    
    private static func calculateChestWidth(_ landmarks: [Landmark], scale: Double, imageSize: CGSize) -> Double {
        // Use shoulder width as proxy for chest width
        return calculateShoulderWidth(landmarks, scale: scale, imageSize: imageSize) * 0.9
    }
    
    private static func calculateWaistWidth(_ landmarks: [Landmark], scale: Double, imageSize: CGSize) -> Double {
        let leftHip = landmarks[PoseLandmark.leftHip.rawValue]
        let rightHip = landmarks[PoseLandmark.rightHip.rawValue]
        let pixelDistance = distance2D(leftHip, rightHip, imageSize: imageSize)
        return pixelDistance * scale * 0.8 // Waist is narrower than hips
    }
    
    private static func calculateHipWidth(_ landmarks: [Landmark], scale: Double, imageSize: CGSize) -> Double {
        let leftHip = landmarks[PoseLandmark.leftHip.rawValue]
        let rightHip = landmarks[PoseLandmark.rightHip.rawValue]
        let pixelDistance = distance2D(leftHip, rightHip, imageSize: imageSize)
        return pixelDistance * scale
    }
    
    // MARK: - Depths (Side View)
    
    private static func calculateChestDepth(_ landmarks: [Landmark], scale: Double, imageSize: CGSize) -> Double {
        // Estimate from shoulder to back (using z-coordinate or shoulder width)
        let shoulderWidth = calculateShoulderWidth(landmarks, scale: scale, imageSize: imageSize)
        return shoulderWidth * 0.5 // Approximate ratio
    }
    
    private static func calculateWaistDepth(_ landmarks: [Landmark], scale: Double, imageSize: CGSize) -> Double {
        let waistWidth = calculateWaistWidth(landmarks, scale: scale, imageSize: imageSize)
        return waistWidth * 0.6 // Approximate ratio
    }
    
    private static func calculateHipDepth(_ landmarks: [Landmark], scale: Double, imageSize: CGSize) -> Double {
        let hipWidth = calculateHipWidth(landmarks, scale: scale, imageSize: imageSize)
        return hipWidth * 0.7 // Approximate ratio
    }
    
    // MARK: - Validation
    
    static func validateMeasurements(_ measurements: Measurements) -> Bool {
        // Sanity checks
        guard measurements.height > 120 && measurements.height < 250 else { return false } // 4' to 8'
        guard measurements.shoulderWidth > 30 && measurements.shoulderWidth < 70 else { return false }
        guard measurements.chestCircumference > 60 && measurements.chestCircumference < 150 else { return false }
        guard measurements.waistCircumference > 50 && measurements.waistCircumference < 150 else { return false }
        guard measurements.hipCircumference > 60 && measurements.hipCircumference < 160 else { return false }
        guard measurements.inseam > 50 && measurements.inseam < 120 else { return false }
        guard measurements.armLength > 40 && measurements.armLength < 100 else { return false }
        
        return true
    }
}
