import Foundation

// MARK: - Measurement Data

struct MeasurementData: Codable {
    let id: UUID
    let timestamp: Date
    let userHeight: Double // in cm
    let measurements: Measurements
    let frontLandmarks: [Landmark]
    let sideLandmarks: [Landmark]
    let frontImageData: Data?
    let sideImageData: Data?
    let confidenceScore: Double
    let deviceInfo: DeviceInfo
    
    init(
        userHeight: Double,
        measurements: Measurements,
        frontLandmarks: [Landmark],
        sideLandmarks: [Landmark],
        frontImage: Data? = nil,
        sideImage: Data? = nil,
        confidenceScore: Double
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.userHeight = userHeight
        self.measurements = measurements
        self.frontLandmarks = frontLandmarks
        self.sideLandmarks = sideLandmarks
        self.frontImageData = frontImage
        self.sideImageData = sideImage
        self.confidenceScore = confidenceScore
        self.deviceInfo = DeviceInfo.current
    }
}

// MARK: - Measurements

struct Measurements: Codable {
    // Primary measurements (cm)
    let height: Double
    let shoulderWidth: Double
    let chestCircumference: Double
    let waistCircumference: Double
    let hipCircumference: Double
    let inseam: Double
    let armLength: Double
    
    // Additional measurements
    let neckCircumference: Double
    let bicepCircumference: Double
    let forearmCircumference: Double
    let wristCircumference: Double
    let thighCircumference: Double
    let calfCircumference: Double
    let ankleCircumference: Double
    
    // Lengths
    let torsoLength: Double
    let legLength: Double
    let armSpan: Double
    
    // Widths
    let chestWidth: Double
    let waistWidth: Double
    let hipWidth: Double
    
    // Depths (from side view)
    let chestDepth: Double
    let waistDepth: Double
    let hipDepth: Double
    
    // Computed properties for display
    var heightInches: Double {
        height / 2.54
    }
    
    var heightFeetInches: (feet: Int, inches: Double) {
        let totalInches = heightInches
        let feet = Int(totalInches / 12)
        let inches = totalInches.truncatingRemainder(dividingBy: 12)
        return (feet, inches)
    }
}

// MARK: - Landmark

struct Landmark: Codable {
    let index: Int
    let x: Double // Normalized 0-1
    let y: Double // Normalized 0-1
    let z: Double // Depth (relative)
    let visibility: Double // 0-1
    let presence: Double // 0-1
    
    var isValid: Bool {
        visibility > 0.5 && presence > 0.5
    }
}

// MARK: - Device Info

struct DeviceInfo: Codable {
    let model: String
    let systemVersion: String
    let appVersion: String
    
    static var current: DeviceInfo {
        DeviceInfo(
            model: UIDevice.current.model,
            systemVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
    }
}

// MARK: - Capture State

enum CaptureState {
    case idle
    case setupPhone
    case ready
    case countingDown(Int)
    case capturing
    case processing
    case complete
    case error(Error)
}

// MARK: - Pose Landmark Indices

enum PoseLandmark: Int, CaseIterable {
    case nose = 0
    case leftEyeInner = 1
    case leftEye = 2
    case leftEyeOuter = 3
    case rightEyeInner = 4
    case rightEye = 5
    case rightEyeOuter = 6
    case leftEar = 7
    case rightEar = 8
    case mouthLeft = 9
    case mouthRight = 10
    case leftShoulder = 11
    case rightShoulder = 12
    case leftElbow = 13
    case rightElbow = 14
    case leftWrist = 15
    case rightWrist = 16
    case leftPinky = 17
    case rightPinky = 18
    case leftIndex = 19
    case rightIndex = 20
    case leftThumb = 21
    case rightThumb = 22
    case leftHip = 23
    case rightHip = 24
    case leftKnee = 25
    case rightKnee = 26
    case leftAnkle = 27
    case rightAnkle = 28
    case leftHeel = 29
    case rightHeel = 30
    case leftFootIndex = 31
    case rightFootIndex = 32
}
