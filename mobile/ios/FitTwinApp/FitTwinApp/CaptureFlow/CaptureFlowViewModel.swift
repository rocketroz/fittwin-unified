import Foundation

@MainActor
final class CaptureFlowViewModel: ObservableObject {
    @Published private(set) var state: CaptureSessionState = .idle
    @Published var alertMessage: String?

    private let permissionManager = CameraPermissionManager()
    private let apiBaseURL: URL
    private let apiKey: String

    init() {
        let bundle = Bundle.main
        let urlString = bundle.object(forInfoDictionaryKey: "FITWIN_API_URL") as? String ?? "http://127.0.0.1:8000"
        apiBaseURL = URL(string: urlString)?.appendingPathComponent("measurements/validate") ?? URL(string: "http://127.0.0.1:8000/measurements/validate")!
        apiKey = bundle.object(forInfoDictionaryKey: "FITWIN_API_KEY") as? String ?? "staging-secret-key"
    }

    func startFlow( ) {
        Task {
            state = .requestingPermissions
            let status = await permissionManager.requestAccess()

            switch status {
            case .authorized:
                state = .readyForFront
            case .denied, .restricted:
                let message = "Camera access is required to capture measurements. Update permissions in Settings."
                state = .error(message)
                alertMessage = message
            case .notDetermined:
                let message = "Camera permission not determined. Please try again."
                state = .error(message)
                alertMessage = message
            }
        }
    }

    func captureFrontPhoto() {
        state = .capturingFront

        Task {
            try await Task.sleep(for: .seconds(1))
            state = .readyForSide
        }
    }

    func captureSidePhoto() {
        state = .capturingSide

        Task {
            try await Task.sleep(for: .seconds(1))
            state = .processing
            await processMeasurements()
        }
    }

    // ✅ UPDATED: Real backend API call
    private func processMeasurements() async {
        print("🔵 Starting processMeasurements…")
        print("🔵 API URL: \(apiBaseURL.absoluteString)")
        
        do {
            // Create measurement data
            let measurementData: [String: Any] = [
                "session_id": UUID().uuidString,
                "measurements": [
                    "height": 175.0,
                    "chest": 95.0,
                    "waist": 80.0
                ],
                "source": "ios_lidar"
            ]
            
            print("🔵 Measurement data created")
            
            // Convert to JSON
            let jsonData = try JSONSerialization.data(withJSONObject: measurementData)
            print("🔵 JSON data created, size: \(jsonData.count) bytes")
            
            // Create URL
            var request = URLRequest(url: apiBaseURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type" )
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
            request.httpBody = jsonData
            request.timeoutInterval = 30
            
            print("🔵 Request configured, making API call..." )
            
            // Make API call
            let (data, response) = try await URLSession.shared.data(for: request)
            
            print("🔵 Response received")
            
            // Check response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type" )
                throw NSError(domain: "Invalid response", code: -1)
            }
            
            print("🔵 HTTP Status Code: \(httpResponse.statusCode )")
            
            if httpResponse.statusCode == 200 {
                // Success!
                print("✅ Measurements validated successfully" )
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("✅ Response:", json)
                }
                state = .completed
            } else {
                let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                print("❌ API Error - Status: \(httpResponse.statusCode ), Body: \(responseString)")
                throw NSError(domain: "API Error", code: httpResponse.statusCode )
            }
            
        } catch let urlError as URLError {
            let message = "Network error: \(urlError.localizedDescription). Make sure the backend at \(apiBaseURL.absoluteString) is reachable from your device."
            state = .error(message)
            alertMessage = message
            print("❌ URLError: \(urlError)")
        } catch let apiError as NSError where apiError.domain == "API Error" {
            let message = "Backend rejected the request (HTTP \(apiError.code)). Check the FastAPI logs for the detailed error."
            state = .error(message)
            alertMessage = message
            print("❌ API Error: status=\(apiError.code)")
        } catch {
            let message = "Failed to process measurements: \(error.localizedDescription)"
            state = .error(message)
            alertMessage = message
            print("❌ Error:", error)
        }
    }

    func resetFlow() {
        state = .idle
        alertMessage = nil
    }
}
