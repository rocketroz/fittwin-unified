import Foundation
import SwiftUI
import AVFoundation

@MainActor
class MeasurementViewModel: ObservableObject {
    @Published var state: CaptureState = .idle
    @Published var countdown: Int? = nil
    
    private let cameraManager = LiDARCameraManager()
    private let poseDetector = MediaPipePoseDetector()
    private let pythonAPI = PythonMeasurementAPI(
        baseURL: "https://your-api-url.com",  // TODO: Replace with actual URL
        apiKey: "your-api-key"  // TODO: Replace with actual key
    )
    
    private var frontImage: UIImage?
    private var frontDepthData: AVDepthData?
    private var frontPose: MediaPipePoseDetector.PoseResult?
    private var sideImage: UIImage?
    private var sideDepthData: AVDepthData?
    private var sidePose: MediaPipePoseDetector.PoseResult?
    
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
                    
                    // Process measurements
                    self.state = .processing
                    try await Task.sleep(for: .seconds(1))
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
            // Extract pose landmarks from both images
            print("🔍 Detecting pose in front image...")
            let frontPose = try await poseDetector.detectPose(in: frontImage)
            self.frontPose = frontPose
            
            print("🔍 Detecting pose in side image...")
            let sidePose = try await poseDetector.detectPose(in: sideImage)
            self.sidePose = sidePose
            
            print("✅ Pose detection complete")
            print("📤 Sending to Python API...")
            
            // Send to Python API for measurement calculation
            let response = try await pythonAPI.validateMeasurements(
                frontPose: frontPose,
                sidePose: sidePose
            )
            
            print("✅ Received measurements from API")
            print("📊 Confidence: \(response.confidence)")
            
            // Convert API response to BodyMeasurements
            let measurements = BodyMeasurements(
                height_cm: response.height_cm ?? 0,
                shoulder_width_cm: response.shoulder_cm ?? 0,
                chest_cm: response.chest_cm ?? 0,
                waist_natural_cm: response.waist_natural_cm ?? 0,
                hip_low_cm: response.hip_low_cm ?? 0,
                inseam_cm: response.inseam_cm ?? 0,
                outseam_cm: response.outseam_cm ?? 0,
                sleeve_length_cm: response.sleeve_cm ?? 0,
                neck_cm: response.neck_cm ?? 0,
                bicep_cm: response.bicep_cm ?? 0,
                forearm_cm: response.forearm_cm ?? 0,
                thigh_cm: response.thigh_cm ?? 0,
                calf_cm: response.calf_cm ?? 0
            )
            
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
        frontPose = nil
        sideImage = nil
        sideDepthData = nil
        sidePose = nil
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
