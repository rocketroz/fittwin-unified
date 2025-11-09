import Foundation
import SwiftUI
import AVFoundation

@MainActor
class MeasurementViewModel: ObservableObject {
    @Published var state: CaptureState = .idle
    @Published var countdown: Int? = nil
    
    private let cameraManager = LiDARCameraManager()
    private let calculator = MeasurementCalculator()
    private var frontImage: UIImage?
    private var frontDepthData: AVDepthData?
    private var sideImage: UIImage?
    private var sideDepthData: AVDepthData?
    
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
        guard let frontImage = frontImage else {
            state = .error("Missing front image")
            return
        }
        
        do {
            // Extract pose landmarks from front image
            let frontLandmarks = try await extractLandmarks(from: frontImage)
            
            // Extract pose landmarks from side image (if available)
            var sideLandmarks: [BodyLandmark]? = nil
            if let sideImage = sideImage {
                sideLandmarks = try? await extractLandmarks(from: sideImage)
            }
            
            // Calculate measurements
            let measurements = calculator.calculateMeasurements(
                frontLandmarks: frontLandmarks,
                sideLandmarks: sideLandmarks,
                referenceHeight: 170.0  // Default, can be user-provided
            )
            
            state = .completed(measurements)
            
            // Stop camera
            cameraManager.stopSession()
        } catch {
            state = .error("Measurement calculation failed: \(error.localizedDescription)")
        }
    }
    
    private func extractLandmarks(from image: UIImage) async throws -> [BodyLandmark] {
        // TODO: Integrate with MediaPipe or Vision framework
        // For now, return mock landmarks for testing
        return generateMockLandmarks()
    }
    
    private func generateMockLandmarks() -> [BodyLandmark] {
        // Mock MediaPipe pose landmarks (33 points)
        var landmarks: [BodyLandmark] = []
        
        // Nose (0)
        landmarks.append(BodyLandmark(index: 0, x: 0.5, y: 0.2, z: 0.0))
        
        // Shoulders (11, 12)
        landmarks.append(BodyLandmark(index: 11, x: 0.4, y: 0.35, z: 0.0))
        landmarks.append(BodyLandmark(index: 12, x: 0.6, y: 0.35, z: 0.0))
        
        // Elbows (13, 14)
        landmarks.append(BodyLandmark(index: 13, x: 0.35, y: 0.5, z: 0.0))
        landmarks.append(BodyLandmark(index: 14, x: 0.65, y: 0.5, z: 0.0))
        
        // Wrists (15, 16)
        landmarks.append(BodyLandmark(index: 15, x: 0.3, y: 0.65, z: 0.0))
        landmarks.append(BodyLandmark(index: 16, x: 0.7, y: 0.65, z: 0.0))
        
        // Hips (23, 24)
        landmarks.append(BodyLandmark(index: 23, x: 0.42, y: 0.6, z: 0.0))
        landmarks.append(BodyLandmark(index: 24, x: 0.58, y: 0.6, z: 0.0))
        
        // Knees (25, 26)
        landmarks.append(BodyLandmark(index: 25, x: 0.4, y: 0.75, z: 0.0))
        landmarks.append(BodyLandmark(index: 26, x: 0.6, y: 0.75, z: 0.0))
        
        // Ankles (27, 28)
        landmarks.append(BodyLandmark(index: 27, x: 0.4, y: 0.95, z: 0.0))
        landmarks.append(BodyLandmark(index: 28, x: 0.6, y: 0.95, z: 0.0))
        
        return landmarks
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
        sideImage = nil
        sideDepthData = nil
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
