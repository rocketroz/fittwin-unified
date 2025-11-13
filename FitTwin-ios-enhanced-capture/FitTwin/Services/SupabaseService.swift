import Foundation
import Supabase

/// Service for interacting with Supabase backend
@MainActor
class SupabaseService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var error: SupabaseError?
    
    // MARK: - Private Properties
    private var client: SupabaseClient?
    
    // MARK: - Configuration
    private let supabaseURL: String
    private let supabaseKey: String
    
    // MARK: - Initialization
    
    init(url: String, key: String) {
        self.supabaseURL = url
        self.supabaseKey = key
        setupClient()
    }
    
    // Convenience init with environment variables
    init() {
        // TODO: Replace with your Supabase project URL and anon key
        // Get these from: Supabase Dashboard > Settings > API
        self.supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
        self.supabaseKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
        setupClient()
    }
    
    // MARK: - Setup
    
    private func setupClient() {
        guard !supabaseURL.isEmpty, !supabaseKey.isEmpty else {
            print("⚠️ Supabase credentials not configured")
            return
        }
        
        guard let url = URL(string: supabaseURL) else {
            error = .invalidConfiguration
            return
        }
        
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseKey
        )
        
        // Check auth state
        Task {
            await checkAuthState()
        }
    }
    
    // MARK: - Authentication
    
    func checkAuthState() async {
        guard let client = client else { return }
        
        do {
            let session = try await client.auth.session
            self.currentUser = session.user
            self.isAuthenticated = true
        } catch {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
    
    func signInAnonymously() async throws {
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        do {
            let session = try await client.auth.signInAnonymously()
            self.currentUser = session.user
            self.isAuthenticated = true
        } catch {
            throw SupabaseError.authenticationFailed(error)
        }
    }
    
    func signInWithEmail(email: String, password: String) async throws {
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            self.currentUser = session.user
            self.isAuthenticated = true
        } catch {
            throw SupabaseError.authenticationFailed(error)
        }
    }
    
    func signUpWithEmail(email: String, password: String) async throws {
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        do {
            let session = try await client.auth.signUp(email: email, password: password)
            self.currentUser = session.user
            self.isAuthenticated = true
        } catch {
            throw SupabaseError.authenticationFailed(error)
        }
    }
    
    func signOut() async throws {
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        do {
            try await client.auth.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            throw SupabaseError.authenticationFailed(error)
        }
    }
    
    // MARK: - Measurements
    
    func uploadMeasurement(_ measurementData: MeasurementData) async throws -> String {
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        guard let userId = currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        // Prepare measurement record
        let record: [String: Any] = [
            "user_id": userId.uuidString,
            "height_cm": measurementData.userHeight,
            "shoulder_width": measurementData.measurements.shoulderWidth,
            "chest_circumference": measurementData.measurements.chestCircumference,
            "waist_circumference": measurementData.measurements.waistCircumference,
            "hip_circumference": measurementData.measurements.hipCircumference,
            "inseam": measurementData.measurements.inseam,
            "arm_length": measurementData.measurements.armLength,
            "neck_circumference": measurementData.measurements.neckCircumference,
            "bicep_circumference": measurementData.measurements.bicepCircumference,
            "forearm_circumference": measurementData.measurements.forearmCircumference,
            "wrist_circumference": measurementData.measurements.wristCircumference,
            "thigh_circumference": measurementData.measurements.thighCircumference,
            "calf_circumference": measurementData.measurements.calfCircumference,
            "ankle_circumference": measurementData.measurements.ankleCircumference,
            "torso_length": measurementData.measurements.torsoLength,
            "leg_length": measurementData.measurements.legLength,
            "arm_span": measurementData.measurements.armSpan,
            "chest_width": measurementData.measurements.chestWidth,
            "waist_width": measurementData.measurements.waistWidth,
            "hip_width": measurementData.measurements.hipWidth,
            "chest_depth": measurementData.measurements.chestDepth,
            "waist_depth": measurementData.measurements.waistDepth,
            "hip_depth": measurementData.measurements.hipDepth,
            "confidence_score": measurementData.confidenceScore,
            "device_model": measurementData.deviceModel,
            "device_os": measurementData.deviceOS,
            "app_version": measurementData.appVersion
        ]
        
        do {
            let response: [MeasurementRecord] = try await client
                .from("measurements")
                .insert(record)
                .select()
                .execute()
                .value
            
            guard let first = response.first else {
                throw SupabaseError.uploadFailed
            }
            
            return first.id.uuidString
        } catch {
            throw SupabaseError.uploadFailed
        }
    }
    
    func fetchMeasurements(limit: Int = 10) async throws -> [MeasurementRecord] {
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        guard let userId = currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        do {
            let measurements: [MeasurementRecord] = try await client
                .from("measurements")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            return measurements
        } catch {
            throw SupabaseError.fetchFailed
        }
    }
    
    func fetchLatestMeasurement() async throws -> MeasurementRecord? {
        let measurements = try await fetchMeasurements(limit: 1)
        return measurements.first
    }
    
    func deleteMeasurement(id: String) async throws {
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        do {
            try await client
                .from("measurements")
                .delete()
                .eq("id", value: id)
                .execute()
        } catch {
            throw SupabaseError.deleteFailed
        }
    }
    
    // MARK: - Image Upload (Optional)
    
    func uploadImage(_ image: UIImage, type: ImageType) async throws -> String {
        guard let client = client else {
            throw SupabaseError.clientNotInitialized
        }
        
        guard let userId = currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw SupabaseError.invalidImageData
        }
        
        // Create unique filename
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "\(userId.uuidString)/\(type.rawValue)_\(timestamp).jpg"
        
        do {
            let path = try await client.storage
                .from("measurement-images")
                .upload(
                    path: filename,
                    file: imageData,
                    options: FileOptions(contentType: "image/jpeg")
                )
            
            // Get public URL
            let url = try client.storage
                .from("measurement-images")
                .getPublicURL(path: path)
            
            return url.absoluteString
        } catch {
            throw SupabaseError.imageUploadFailed
        }
    }
}

// MARK: - Supporting Types

struct MeasurementRecord: Codable {
    let id: UUID
    let userId: UUID
    let createdAt: Date
    let heightCm: Double
    let shoulderWidth: Double
    let chestCircumference: Double
    let waistCircumference: Double
    let hipCircumference: Double
    let inseam: Double
    let armLength: Double
    let confidenceScore: Double?
    let deviceModel: String?
    let deviceOS: String?
    let appVersion: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case createdAt = "created_at"
        case heightCm = "height_cm"
        case shoulderWidth = "shoulder_width"
        case chestCircumference = "chest_circumference"
        case waistCircumference = "waist_circumference"
        case hipCircumference = "hip_circumference"
        case inseam
        case armLength = "arm_length"
        case confidenceScore = "confidence_score"
        case deviceModel = "device_model"
        case deviceOS = "device_os"
        case appVersion = "app_version"
    }
}

enum ImageType: String {
    case front = "front"
    case side = "side"
}

enum SupabaseError: LocalizedError {
    case clientNotInitialized
    case invalidConfiguration
    case notAuthenticated
    case authenticationFailed(Error)
    case uploadFailed
    case fetchFailed
    case deleteFailed
    case invalidImageData
    case imageUploadFailed
    
    var errorDescription: String? {
        switch self {
        case .clientNotInitialized:
            return "Supabase client not initialized"
        case .invalidConfiguration:
            return "Invalid Supabase configuration"
        case .notAuthenticated:
            return "User not authenticated"
        case .authenticationFailed(let error):
            return "Authentication failed: \(error.localizedDescription)"
        case .uploadFailed:
            return "Failed to upload measurement"
        case .fetchFailed:
            return "Failed to fetch measurements"
        case .deleteFailed:
            return "Failed to delete measurement"
        case .invalidImageData:
            return "Invalid image data"
        case .imageUploadFailed:
            return "Failed to upload image"
        }
    }
}
