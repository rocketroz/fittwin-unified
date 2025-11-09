import Foundation

/// Client for Python measurement validation API
class PythonMeasurementAPI {
    
    // MARK: - Configuration
    
    private let baseURL: String
    private let apiKey: String
    
    init() {
        // Read from Info.plist (same pattern as original FitTwinApp)
        let bundle = Bundle.main
        let baseURLString = bundle.object(forInfoDictionaryKey: "FITWIN_API_URL") as? String ?? "http://127.0.0.1:8000"
        self.baseURL = baseURLString
        self.apiKey = bundle.object(forInfoDictionaryKey: "FITWIN_API_KEY") as? String ?? "staging-secret-key"
        
        print("⚙️ API Configuration:")
        print("   Base URL: \(baseURL)")
        print("   API Key: \(apiKey.prefix(8))...")
    }
    
    // For testing with custom values
    init(baseURL: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
    
    // MARK: - Request/Response Models
    
    struct MediaPipeLandmark: Codable {
        let x: Double
        let y: Double
        let z: Double
        let visibility: Double
    }
    
    struct MediaPipeLandmarks: Codable {
        let landmarks: [MediaPipeLandmark]
        let timestamp: String
        let image_width: Int
        let image_height: Int
    }
    
    struct MeasurementRequest: Codable {
        let source_type: String
        let platform: String
        let session_id: String
        let front_landmarks: MediaPipeLandmarks
        let side_landmarks: MediaPipeLandmarks
        let front_photo_url: String?
        let side_photo_url: String?
    }
    
    struct MeasurementResponse: Codable {
        let valid: Bool
        let measurements_cm: [String: Double]
        let model_version: String
        let confidence: Double
        let session_id: String?
        
        // Individual measurements
        let height_cm: Double?
        let neck_cm: Double?
        let shoulder_cm: Double?
        let chest_cm: Double?
        let underbust_cm: Double?
        let waist_natural_cm: Double?
        let sleeve_cm: Double?
        let bicep_cm: Double?
        let forearm_cm: Double?
        let hip_low_cm: Double?
        let thigh_cm: Double?
        let knee_cm: Double?
        let calf_cm: Double?
        let ankle_cm: Double?
        let front_rise_cm: Double?
        let back_rise_cm: Double?
        let inseam_cm: Double?
        let outseam_cm: Double?
    }
    
    // MARK: - API Methods
    
    func validateMeasurements(
        frontPose: MediaPipePoseDetector.PoseResult,
        sidePose: MediaPipePoseDetector.PoseResult,
        sessionId: String = UUID().uuidString
    ) async throws -> MeasurementResponse {
        
        // Convert pose results to API format
        let frontLandmarks = MediaPipeLandmarks(
            landmarks: frontPose.landmarks.map { landmark in
                MediaPipeLandmark(
                    x: landmark.x,
                    y: landmark.y,
                    z: landmark.z,
                    visibility: landmark.visibility
                )
            },
            timestamp: ISO8601DateFormatter().string(from: frontPose.timestamp),
            image_width: frontPose.imageWidth,
            image_height: frontPose.imageHeight
        )
        
        let sideLandmarks = MediaPipeLandmarks(
            landmarks: sidePose.landmarks.map { landmark in
                MediaPipeLandmark(
                    x: landmark.x,
                    y: landmark.y,
                    z: landmark.z,
                    visibility: landmark.visibility
                )
            },
            timestamp: ISO8601DateFormatter().string(from: sidePose.timestamp),
            image_width: sidePose.imageWidth,
            image_height: sidePose.imageHeight
        )
        
        // Create request payload
        let request = MeasurementRequest(
            source_type: "mediapipe_ios",
            platform: "ios_native",
            session_id: sessionId,
            front_landmarks: frontLandmarks,
            side_landmarks: sideLandmarks,
            front_photo_url: nil,
            side_photo_url: nil
        )
        
        // Make API call
        return try await post(endpoint: "/measurements/validate", body: request)
    }
    
    // MARK: - HTTP Client
    
    private func post<T: Codable, R: Codable>(
        endpoint: String,
        body: T
    ) async throws -> R {
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        urlRequest.timeoutInterval = 30
        
        // Encode body
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        urlRequest.httpBody = try encoder.encode(body)
        
        // Log request (debug)
        if let bodyString = String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) {
            print("📤 API Request to \(endpoint):")
            print(bodyString.prefix(500))  // First 500 chars
        }
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Log response (debug)
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 API Response (\(httpResponse.statusCode)):")
            print(responseString.prefix(500))  // First 500 chars
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to parse error
            if let errorString = String(data: data, encoding: .utf8) {
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorString)
            }
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: "Unknown error")
        }
        
        // Decode response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            return try decoder.decode(R.self, from: data)
        } catch {
            print("❌ Decoding error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString)")
            }
            throw APIError.decodingError(error)
        }
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
