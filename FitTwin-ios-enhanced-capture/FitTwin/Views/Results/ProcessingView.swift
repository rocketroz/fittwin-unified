import SwiftUI

struct ProcessingView: View {
    let progress: Double
    let measurementData: MeasurementData?
    
    @EnvironmentObject var supabaseService: SupabaseService
    @State private var hasSpoken = false
    @State private var uploadStatus: UploadStatus = .idle
    @State private var uploadError: String?
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Processing animation
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.teal, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50))
                    .foregroundColor(.teal)
            }
            
            // Title
            Text("Analyzing Your Body")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            // Progress text
            Text("\(Int(progress * 100))%")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.teal)
            
            // Status messages
            VStack(spacing: 12) {
                StatusRow(
                    icon: "checkmark.circle.fill",
                    text: "Detecting body landmarks",
                    isComplete: progress > 0.2
                )
                StatusRow(
                    icon: "checkmark.circle.fill",
                    text: "Calculating measurements",
                    isComplete: progress > 0.5
                )
                StatusRow(
                    icon: "checkmark.circle.fill",
                    text: "Validating accuracy",
                    isComplete: progress > 0.8
                )
                StatusRow(
                    icon: "checkmark.circle.fill",
                    text: "Finalizing results",
                    isComplete: progress >= 1.0
                )
                StatusRow(
                    icon: uploadStatus.icon,
                    text: uploadStatus.text,
                    isComplete: uploadStatus == .success
                )
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            if !hasSpoken {
                AudioNarrator.shared.speak("Perfect! Now analyzing your measurements. This will take about 30 seconds.")
                hasSpoken = true
            }
        }
        .onChange(of: progress) { newProgress in
            // Start upload when processing is complete
            if newProgress >= 1.0 && uploadStatus == .idle {
                uploadMeasurements()
            }
        }
    }
    
    private func uploadMeasurements() {
        guard let data = measurementData else {
            uploadStatus = .failed
            uploadError = "No measurement data available"
            return
        }
        
        uploadStatus = .uploading
        
        Task {
            do {
                // Ensure user is authenticated
                if !supabaseService.isAuthenticated {
                    try await supabaseService.signInAnonymously()
                }
                
                // Upload measurement
                let measurementId = try await supabaseService.uploadMeasurement(data)
                
                await MainActor.run {
                    uploadStatus = .success
                    print("✅ Measurement uploaded successfully: \(measurementId)")
                }
            } catch {
                await MainActor.run {
                    uploadStatus = .failed
                    uploadError = error.localizedDescription
                    print("❌ Upload failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

enum UploadStatus: Equatable {
    case idle
    case uploading
    case success
    case failed
    
    var icon: String {
        switch self {
        case .idle:
            return "cloud.fill"
        case .uploading:
            return "arrow.up.circle"
        case .success:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
    
    var text: String {
        switch self {
        case .idle:
            return "Preparing to sync"
        case .uploading:
            return "Syncing to cloud"
        case .success:
            return "Synced successfully"
        case .failed:
            return "Sync failed (saved locally)"
        }
    }
}

struct StatusRow: View {
    let icon: String
    let text: String
    let isComplete: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(isComplete ? .green : .white.opacity(0.3))
                .font(.system(size: 20))
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(isComplete ? .white : .white.opacity(0.5))
            
            Spacer()
        }
    }
}

#Preview {
    ProcessingView(progress: 0.6)
}
