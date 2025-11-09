import Foundation
import SwiftUI
import AVFoundation

@MainActor
class MeasurementViewModel: ObservableObject {
    @Published var state: CaptureState = .idle
    @Published var countdown: Int? = nil
    
    private let cameraManager = LiDARCameraManager()
    private let poseDetector = PoseDetector()  // ✅ FIXED: Using real PoseDetector
    
    private var frontImage: UIImage?
    private var frontDepthData: AVDepthData?
    private var frontLandmarks: [BodyLandmark]?
    private var sideImage: UIImage?
    private var sideDepthData: AVDepthData?
    private var sideLandmarks: [BodyLandmark]?
    
    func startMeasurement() {
        state = .requestingPermissions
        
        Task {
            let status = await requestCameraPermission()
            
            if status == .authorized {
                // Setup camera
                do {
                    try await cameraManager.setupSession()
                    cameraManager.startSession()
                    state = .readyForFront
                } catch {
                    state = .error("Failed to setup camera: \(error.localizedDescription)")
                }
            } else {
                state = .error("Camera permission denied. Please enable in Settings.")
            }
        }
    }
    
    func captureFrontPhoto() {
        state = .readyForFront
        startCountdown(duration: 10) {
            Task { @MainActor in
                self.state = .capturingFront
                
                do {
                    let result = try await self.cameraManager.capturePhoto()
                    self.frontImage = result.image
                    self.frontDepthData = result.depthData
                    
                    print("✅ Front image captured")
                    
                    // Move to side view
                    try await Task.sleep(for: .seconds(1))
                    self.state = .readyForSide
                } catch {
                    self.state = .error("Front capture failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func captureSidePhoto() {
        state = .readyForSide
        startCountdown(duration: 5) {
            Task { @MainActor in
                self.state = .capturingSide
                
                do {
                    let result = try await self.cameraManager.capturePhoto()
                    self.sideImage = result.image
                    self.sideDepthData = result.depthData
                    
                    print("✅ Side image captured")
                    
                    // Process measurements
                    self.state = .processing
                    await self.processMeasurements()
                } catch {
                    self.state = .error("Side capture failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func processMeasurements() async {
        guard let frontImage = frontImage, let sideImage = sideImage else {
            state = .error("Missing images")
            return
        }
        
        do {
            // ✅ FIXED: Extract real pose landmarks using Vision framework
            print("🔍 Detecting pose in front image...")
            var frontLandmarks = try await poseDetector.detectPose(in: frontImage)
            print("   Found \(frontLandmarks.count) landmarks")
            
            print("🔍 Detecting pose in side image...")
            var sideLandmarks = try await poseDetector.detectPose(in: sideImage)
            print("   Found \(sideLandmarks.count) landmarks")
            
            // ✅ FIXED: Enhance landmarks with real 3D LiDAR depth data
            if let frontDepthData = frontDepthData {
                print("📊 Enhancing front landmarks with LiDAR depth data...")
                frontLandmarks = try poseDetector.enhanceLandmarksWithDepth(
                    frontLandmarks,
                    depthData: frontDepthData,
                    imageSize: frontImage.size
                )
                print("   ✅ Front landmarks enhanced with 3D depth")
            } else {
                print("   ⚠️ No depth data available for front image")
            }
            
            if let sideDepthData = sideDepthData {
                print("📊 Enhancing side landmarks with LiDAR depth data...")
                sideLandmarks = try poseDetector.enhanceLandmarksWithDepth(
                    sideLandmarks,
                    depthData: sideDepthData,
                    imageSize: sideImage.size
                )
                print("   ✅ Side landmarks enhanced with 3D depth")
            } else {
                print("   ⚠️ No depth data available for side image")
            }
            
            self.frontLandmarks = frontLandmarks
            self.sideLandmarks = sideLandmarks
            
            print("✅ Pose detection complete")
            print("📏 Calculating measurements using proven algorithm...")
            
            // ✅ FIXED: Calculate measurements using proven MeasurementCalculator
            let measurements = MeasurementCalculator.calculateMeasurements(
                frontLandmarks: frontLandmarks,
                sideLandmarks: sideLandmarks,
                referenceHeight: 170.0  // Default reference, can be customized
            )
            
            print("✅ Measurements calculated:")
            print("   Height: \(String(format: "%.1f", measurements.height_cm)) cm")
            print("   Shoulder: \(String(format: "%.1f", measurements.shoulder_width_cm)) cm")
            print("   Chest: \(String(format: "%.1f", measurements.chest_cm)) cm")
            print("   Waist: \(String(format: "%.1f", measurements.waist_natural_cm)) cm")
            print("   Hip: \(String(format: "%.1f", measurements.hip_low_cm)) cm")
            print("   Inseam: \(String(format: "%.1f", measurements.inseam_cm)) cm")
            print("   Outseam: \(String(format: "%.1f", measurements.outseam_cm)) cm")
            print("   Sleeve: \(String(format: "%.1f", measurements.sleeve_length_cm)) cm")
            print("   Neck: \(String(format: "%.1f", measurements.neck_cm)) cm")
            print("   Bicep: \(String(format: "%.1f", measurements.bicep_cm)) cm")
            print("   Forearm: \(String(format: "%.1f", measurements.forearm_cm)) cm")
            print("   Thigh: \(String(format: "%.1f", measurements.thigh_cm)) cm")
            print("   Calf: \(String(format: "%.1f", measurements.calf_cm)) cm")
            
            state = .completed(measurements)
            
            // Stop camera
            cameraManager.stopSession()
        } catch {
            print("❌ Error: \(error.localizedDescription)")
            state = .error("Measurement failed: \(error.localizedDescription)")
        }
    }
    
    private func startCountdown(duration: Int, completion: @escaping () -> Void) {
        countdown = duration
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            Task { @MainActor in
                if let current = self.countdown {
                    if current > 1 {
                        self.countdown = current - 1
                    } else {
                        self.countdown = nil
                        timer.invalidate()
                        completion()
                    }
                }
            }
        }
    }
    
    func reset() {
        state = .idle
        countdown = nil
        frontImage = nil
        frontDepthData = nil
        frontLandmarks = nil
        sideImage = nil
        sideDepthData = nil
        sideLandmarks = nil
        cameraManager.stopSession()
    }
    
    func exportMeasurements() {
        guard case .completed(let measurements) = state else { return }
        
        // Convert to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        if let jsonData = try? encoder.encode(measurements),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📊 Measurements JSON:")
            print(jsonString)
            
            // TODO: Add share sheet or file export
            // For now, just print to console
        }
    }
    
    private func requestCameraPermission() async -> AVAuthorizationStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        if status == .notDetermined {
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted ? .authorized : .denied)
                }
            }
        }
        
        return status
    }
}

// MARK: - Capture State

enum CaptureState: Equatable {
    case idle
    case requestingPermissions
    case readyForFront
    case capturingFront
    case readyForSide
    case capturingSide
    case processing
    case completed(BodyMeasurements)
    case error(String)
    
    static func == (lhs: CaptureState, rhs: CaptureState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.requestingPermissions, .requestingPermissions),
             (.readyForFront, .readyForFront),
             (.capturingFront, .capturingFront),
             (.readyForSide, .readyForSide),
             (.capturingSide, .capturingSide),
             (.processing, .processing):
            return true
        case (.completed, .completed),
             (.error, .error):
            return true
        default:
            return false
        }
    }
}
