import SwiftUI

struct ContentView: View {
    @State private var selectedMethod: CaptureMethod = .arkit
    @State private var showCapture = false
    
    enum CaptureMethod {
        case arkit
        case vision
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App header
                VStack(spacing: 12) {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("FitTwin Measure")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Accurate body measurements using LiDAR")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Capture method selection
                VStack(spacing: 20) {
                    Text("Select Capture Method")
                        .font(.headline)
                    
                    // ARKit method (recommended)
                    captureMethodCard(
                        method: .arkit,
                        icon: "arkit",
                        title: "ARKit Body Tracking",
                        subtitle: "Best Accuracy (±1-2 cm)",
                        features: [
                            "90+ body joints tracked",
                            "Real-time 3D skeleton",
                            "360° rotation capture",
                            "Professional quality"
                        ],
                        badge: "RECOMMENDED",
                        isSelected: selectedMethod == .arkit
                    )
                    
                    // Vision method (fallback)
                    captureMethodCard(
                        method: .vision,
                        icon: "camera.viewfinder",
                        title: "Vision Framework",
                        subtitle: "Good Accuracy (±2-3 cm)",
                        features: [
                            "17 body joints tracked",
                            "2 static photos",
                            "Quick capture (15 sec)",
                            "Works on older devices"
                        ],
                        badge: nil,
                        isSelected: selectedMethod == .vision
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Start button
                Button(action: { showCapture = true }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Measurement")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showCapture) {
                if selectedMethod == .arkit {
                    if #available(iOS 13.0, *) {
                        ARBodyCaptureView_Enhanced()
                    } else {
                        Text("ARKit Body Tracking requires iOS 13+")
                    }
                } else {
                    VisionCaptureView()
                }
            }
        }
    }
    
    private func captureMethodCard(
        method: CaptureMethod,
        icon: String,
        title: String,
        subtitle: String,
        features: [String],
        badge: String?,
        isSelected: Bool
    ) -> some View {
        Button(action: { selectedMethod = method }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: icon)
                        .font(.title)
                        .foregroundColor(isSelected ? .blue : .gray)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(isSelected ? .blue : .secondary)
                    }
                    
                    Spacer()
                    
                    if let badge = badge {
                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .blue : .gray)
                }
                
                // Features
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundColor(isSelected ? .blue : .gray)
                            
                            Text(feature)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.05) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Vision Capture View (Wrapper)

struct VisionCaptureView: View {
    @StateObject private var viewModel = MeasurementViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    switch viewModel.state {
                    case .idle:
                        IdleView(onStart: viewModel.startMeasurement)
                        
                    case .requestingPermissions:
                        ProgressView("Requesting camera access...")
                            .foregroundColor(.white)
                        
                    case .readyForFront:
                        CaptureView(
                            title: "Front View",
                            instruction: "Stand 6 feet from camera\nFace the camera directly",
                            countdown: viewModel.countdown,
                            onCapture: viewModel.captureFrontPhoto
                        )
                        
                    case .capturingFront:
                        ProgressView("Capturing front view...")
                            .foregroundColor(.white)
                        
                    case .readyForSide:
                        CaptureView(
                            title: "Side View",
                            instruction: "Rotate 90° to your left\nStand sideways to camera",
                            countdown: viewModel.countdown,
                            onCapture: viewModel.captureSidePhoto
                        )
                        
                    case .capturingSide:
                        ProgressView("Capturing side view...")
                            .foregroundColor(.white)
                        
                    case .processing:
                        ProgressView("Calculating measurements...")
                            .foregroundColor(.white)
                        
                    case .completed(let measurements):
                        ResultsView(
                            measurements: measurements,
                            onReset: viewModel.reset,
                            onExport: viewModel.exportMeasurements
                        )
                        
                    case .error(let message):
                        ErrorView(message: message, onRetry: viewModel.reset)
                    }
                }
                .padding()
            }
            .navigationTitle("Vision Capture")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Idle View

struct IdleView: View {
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "figure.stand")
                .font(.system(size: 100))
                .foregroundColor(.white)
            
            Text("Body Measurement\nCapture")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Uses LiDAR for accurate measurements")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Button(action: onStart) {
                Text("Start Measurement")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Capture View

struct CaptureView: View {
    let title: String
    let instruction: String
    let countdown: Int?
    let onCapture: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Camera preview placeholder
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 400)
                .overlay(
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                        
                        if let countdown = countdown {
                            Text("\(countdown)")
                                .font(.system(size: 80, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.top, 20)
                        }
                    }
                )
            
            Text(instruction)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            if countdown == nil {
                Button(action: onCapture) {
                    Text("Start Capture")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - Results View

struct ResultsView: View {
    let measurements: BodyMeasurements
    let onReset: () -> Void
    let onExport: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Measurements")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 12) {
                    MeasurementRow(label: "Height", value: measurements.height_cm, unit: "cm")
                    MeasurementRow(label: "Shoulder Width", value: measurements.shoulder_width_cm, unit: "cm")
                    MeasurementRow(label: "Chest", value: measurements.chest_cm, unit: "cm")
                    MeasurementRow(label: "Waist", value: measurements.waist_natural_cm, unit: "cm")
                    MeasurementRow(label: "Hip", value: measurements.hip_low_cm, unit: "cm")
                    MeasurementRow(label: "Inseam", value: measurements.inseam_cm, unit: "cm")
                    MeasurementRow(label: "Outseam", value: measurements.outseam_cm, unit: "cm")
                    MeasurementRow(label: "Sleeve Length", value: measurements.sleeve_length_cm, unit: "cm")
                    MeasurementRow(label: "Neck", value: measurements.neck_cm, unit: "cm")
                    MeasurementRow(label: "Bicep", value: measurements.bicep_cm, unit: "cm")
                    MeasurementRow(label: "Forearm", value: measurements.forearm_cm, unit: "cm")
                    MeasurementRow(label: "Thigh", value: measurements.thigh_cm, unit: "cm")
                    MeasurementRow(label: "Calf", value: measurements.calf_cm, unit: "cm")
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                HStack(spacing: 15) {
                    Button(action: onExport) {
                        Label("Export", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: onReset) {
                        Label("New Measurement", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
}

struct MeasurementRow: View {
    let label: String
    let value: Double
    let unit: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white)
            Spacer()
            Text(String(format: "%.1f %@", value, unit))
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(message)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onRetry) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }
}
