//
//  PhoneAngleValidator.swift
//  FitTwinMeasure
//
//  Created by FitTwin Team on 11/9/25.
//

import Foundation
import CoreMotion
import Combine

/// Validates phone angle using device sensors for consistent measurements
@MainActor
class PhoneAngleValidator: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentPitch: Double = 0.0  // Forward/backward tilt (degrees)
    @Published var currentRoll: Double = 0.0   // Left/right tilt (degrees)
    @Published var isAngleCorrect: Bool = false
    @Published var adjustmentGuidance: String = ""
    
    // MARK: - Private Properties
    
    private let motionManager = CMMotionManager()
    private var targetMode: PlacementMode = .ground
    private let angleTolerance: Double = 5.0  // ±5 degrees
    
    // MARK: - Initialization
    
    init() {
        print("📐 PhoneAngleValidator initialized")
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Start monitoring device orientation
    func startMonitoring(for mode: PlacementMode) {
        print("🚀 Starting angle monitoring for \(mode.rawValue)")
        
        self.targetMode = mode
        
        guard motionManager.isDeviceMotionAvailable else {
            print("❌ Device motion not available")
            adjustmentGuidance = "Device motion sensors not available"
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.1  // 10Hz
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else {
                if let error = error {
                    print("❌ Motion update error: \(error.localizedDescription)")
                }
                return
            }
            
            // Convert radians to degrees
            let pitch = motion.attitude.pitch * 180.0 / .pi
            let roll = motion.attitude.roll * 180.0 / .pi
            
            self.currentPitch = pitch
            self.currentRoll = roll
            
            // Validate angle
            self.isAngleCorrect = self.validateAngle(pitch: pitch, roll: roll)
            
            // Update guidance
            self.adjustmentGuidance = self.getAdjustmentGuidance(pitch: pitch, roll: roll)
            
            // Debug logging (every 1 second)
            if Int(Date().timeIntervalSince1970) % 1 == 0 {
                print("📊 Pitch: \(String(format: "%.1f", pitch))°, Roll: \(String(format: "%.1f", roll))°, Valid: \(self.isAngleCorrect)")
            }
        }
    }
    
    /// Stop monitoring device orientation
    func stopMonitoring() {
        print("⏹️ Stopping angle monitoring")
        motionManager.stopDeviceMotionUpdates()
    }
    
    // MARK: - Private Methods
    
    /// Validate if current angle is within tolerance of target
    private func validateAngle(pitch: Double, roll: Double) -> Bool {
        let targetPitch = targetMode.targetPitch
        
        let pitchDiff = abs(pitch - targetPitch)
        let rollDiff = abs(roll)
        
        return pitchDiff < angleTolerance && rollDiff < angleTolerance
    }
    
    /// Get human-readable adjustment guidance
    private func getAdjustmentGuidance(pitch: Double, roll: Double) -> String {
        let targetPitch = targetMode.targetPitch
        
        let pitchDiff = pitch - targetPitch
        let rollDiff = roll
        
        // Check pitch first (more important)
        if abs(pitchDiff) > angleTolerance {
            let degrees = Int(abs(pitchDiff))
            if pitchDiff > 0 {
                return "Tilt phone backward \(degrees)°"
            } else {
                return "Tilt phone forward \(degrees)°"
            }
        }
        
        // Check roll
        if abs(rollDiff) > angleTolerance {
            let degrees = Int(abs(rollDiff))
            if rollDiff > 0 {
                return "Rotate phone \(degrees)° counterclockwise"
            } else {
                return "Rotate phone \(degrees)° clockwise"
            }
        }
        
        return "Perfect angle! ✓"
    }
    
    /// Get visual level indicator (0.0 to 1.0, where 0.5 is perfect)
    func getLevelIndicator() -> Double {
        let targetPitch = targetMode.targetPitch
        let pitchDiff = currentPitch - targetPitch
        
        // Map pitch difference to 0.0-1.0 range
        // -20° = 0.0, 0° = 0.5, +20° = 1.0
        let normalized = (pitchDiff + 20.0) / 40.0
        return max(0.0, min(1.0, normalized))
    }
    
    /// Get color for current angle status
    func getStatusColor() -> String {
        if isAngleCorrect {
            return "green"
        } else if abs(currentPitch - targetMode.targetPitch) < angleTolerance * 2 {
            return "yellow"
        } else {
            return "orange"
        }
    }
}
