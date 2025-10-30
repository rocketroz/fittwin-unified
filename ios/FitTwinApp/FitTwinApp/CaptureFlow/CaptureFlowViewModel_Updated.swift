import Foundation
import SwiftUI
import AVFoundation

/// Updated ViewModel for capture flow with real LiDAR and MediaPipe integration
@MainActor
class CaptureFlowViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var captureState: CaptureState = .initial
    @Published var frontImage: UIImage?
    @Published var sideImage: UIImage?
    @Published var frontDepthData: AVDepthData?
    @Published var sideDepthData: AVDepthData?
    @Published var measurements: BodyMeasurements?
    @Published var error: String?
    @Published var isProcessing = false
    
    // MARK: - Dependencies
    private let poseDetector = PoseDetector()
    private let apiClient = APIClient()
    
    // MARK: - Capture State
    enum CaptureState {
        case initial
        case capturingFront
        case capturingSide
        case processing
        case completed
        case failed(String)
    }
    
    // MARK: - Capture Actions
    
    func startFrontCapture() {
        captureState = .capturingFront
    }
    
    func handleFrontCapture(image: UIImage, depthData: AVDepthData?) {
        frontImage = image
        frontDepthData = depthData
        
        // Automatically move to side capture
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.captureState = .capturingSide
        }
    }
    
    func handleSideCapture(image: UIImage, depthData: AVDepthData?) {
        sideImage = image
        sideDepthData = depthData
        
        // Start processing
        Task {
            await processCapturedImages()
        }
    }
    
    // MARK: - Processing Pipeline
    
    private func processCapturedImages() async {
        guard let frontImage = frontImage else {
            captureState = .failed("Missing front image")
            return
        }
        
        captureState = .processing
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Step 1: Detect pose in front image
            var frontLandmarks = try await poseDetector.detectPose(in: frontImage)
            
            // Step 2: Enhance with depth data if available
            if let frontDepthData = frontDepthData {
                frontLandmarks = try poseDetector.enhanceLandmarksWithDepth(
                    frontLandmarks,
                    depthData: frontDepthData,
                    imageSize: frontImage.size
                )
            }
            
            // Step 3: Detect pose in side image (if available)
            var sideLandmarks: [BodyLandmark]? = nil
            if let sideImage = sideImage {
                sideLandmarks = try await poseDetector.detectPose(in: sideImage)
                
                if let sideDepthData = sideDepthData, let landmarks = sideLandmarks {
                    sideLandmarks = try poseDetector.enhanceLandmarksWithDepth(
                        landmarks,
                        depthData: sideDepthData,
                        imageSize: sideImage.size
                    )
                }
            }
            
            // Step 4: Calculate measurements from landmarks
            let calculatedMeasurements = MeasurementCalculator.calculateMeasurements(
                frontLandmarks: frontLandmarks,
                sideLandmarks: sideLandmarks
            )
            
            self.measurements = calculatedMeasurements
            
            // Step 5: Send to backend for validation
            try await sendMeasurementsToBackend(calculatedMeasurements)
            
            captureState = .completed
            
        } catch {
            let errorMessage = error.localizedDescription
            self.error = errorMessage
            captureState = .failed(errorMessage)
        }
    }
    
    // MARK: - Backend Integration
    
    private func sendMeasurementsToBackend(_ measurements: BodyMeasurements) async throws {
        let endpoint = "http://192.168.4.208:8000/api/measurements/validate"
        let apiKey = "7c4b71191d6026973900ac353d6d68ac5977836cc85710a04ccf3ba147db301e"
        
        guard let url = URL(string: endpoint) else {
            throw ValidationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        // Create request payload
        let payload: [String: Any] = [
            "measurements": measurements.dictionary,
            "metadata": [
                "capture_method": "lidar",
                "has_depth_data": frontDepthData != nil,
                "has_side_view": sideImage != nil,
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ValidationError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ValidationError.serverError(statusCode: httpResponse.statusCode)
        }
        
        // Parse response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("✅ Backend validation response:", json)
        }
    }
    
    // MARK: - Reset
    
    func reset() {
        captureState = .initial
        frontImage = nil
        sideImage = nil
        frontDepthData = nil
        sideDepthData = nil
        measurements = nil
        error = nil
        isProcessing = false
    }
}

// MARK: - API Client (Placeholder)

class APIClient {
    func validateMeasurements(_ measurements: BodyMeasurements) async throws {
        // Implementation moved to CaptureFlowViewModel
    }
}

// MARK: - Validation Error

enum ValidationError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API endpoint URL"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code):
            return "Server error (status code: \(code))"
        }
    }
}
