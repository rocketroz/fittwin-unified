import Foundation
import CoreMotion
import Combine

/// Detects and monitors the phone's angle relative to vertical
/// Target angle: 15-20 degrees from vertical for optimal body measurement capture
class PhoneAngleDetector: ObservableObject {
    @Published var currentAngle: Double = 0.0
    @Published var isCorrectAngle: Bool = false
    @Published var angleStatus: AngleStatus = .tooSteep
    
    private let motionManager = CMMotionManager()
    private let targetAngle: Double = 17.5 // Middle of 15-20 degree range
    private let tolerance: Double = 2.5 // ±2.5 degrees
    
    enum AngleStatus {
        case tooSteep // < 15 degrees
        case perfect // 15-20 degrees
        case tooFlat // > 20 degrees
        
        var message: String {
            switch self {
            case .tooSteep:
                return "Tilt phone back more"
            case .perfect:
                return "Perfect angle! ✓"
            case .tooFlat:
                return "Tilt phone forward slightly"
            }
        }
        
        var color: String {
            switch self {
            case .tooSteep:
                return "red"
            case .perfect:
                return "green"
            case .tooFlat:
                return "orange"
            }
        }
    }
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.1 // 10 Hz
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            
            // Calculate angle from vertical using pitch
            // When phone is vertical (standing up), pitch is ~0
            // When tilted back 15-20°, pitch is negative
            let pitch = motion.attitude.pitch
            let angleFromVertical = abs(pitch * 180 / .pi)
            
            DispatchQueue.main.async {
                self.currentAngle = angleFromVertical
                self.updateAngleStatus(angleFromVertical)
            }
        }
    }
    
    private func updateAngleStatus(_ angle: Double) {
        if angle >= 15 && angle <= 20 {
            angleStatus = .perfect
            isCorrectAngle = true
        } else if angle < 15 {
            angleStatus = .tooSteep
            isCorrectAngle = false
        } else {
            angleStatus = .tooFlat
            isCorrectAngle = false
        }
    }
    
    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    deinit {
        stopMonitoring()
    }
}
