import SwiftUI

/// Updated SwiftUI view for the capture flow with camera integration
struct CaptureFlowView: View {
    @StateObject private var viewModel = CaptureFlowViewModel()
    @State private var showingFrontCamera = false
    @State private var showingSideCamera = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    Spacer()
                    
                    // Main content based on state
                    switch viewModel.captureState {
                    case .initial:
                        initialView
                    case .capturingFront:
                        EmptyView() // Camera view is presented as sheet
                    case .capturingSide:
                        EmptyView() // Camera view is presented as sheet
                    case .processing:
                        processingView
                    case .completed:
                        completedView
                    case .failed(let error):
                        errorView(message: error)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    actionButtons
                }
                .padding()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingFrontCamera) {
                CameraCaptureView(captureMode: .front) { image, depthData in
                    viewModel.handleFrontCapture(image: image, depthData: depthData)
                    showingFrontCamera = false
                    
                    // Automatically show side camera after front capture
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingSideCamera = true
                    }
                }
            }
            .sheet(isPresented: $showingSideCamera) {
                CameraCaptureView(captureMode: .side) { image, depthData in
                    viewModel.handleSideCapture(image: image, depthData: depthData)
                    showingSideCamera = false
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Body Measurement")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Capture your measurements with LiDAR")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var initialView: some View {
        VStack(spacing: 32) {
            // Instructions
            VStack(spacing: 16) {
                instructionRow(
                    icon: "1.circle.fill",
                    text: "Stand 6-8 feet from your device"
                )
                instructionRow(
                    icon: "2.circle.fill",
                    text: "Capture front view with arms slightly away"
                )
                instructionRow(
                    icon: "3.circle.fill",
                    text: "Turn left and capture side view"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.1), radius: 10)
            )
            
            // Preview images if available
            if viewModel.frontImage != nil || viewModel.sideImage != nil {
                HStack(spacing: 16) {
                    if let frontImage = viewModel.frontImage {
                        capturePreview(image: frontImage, label: "Front")
                    }
                    if let sideImage = viewModel.sideImage {
                        capturePreview(image: sideImage, label: "Side")
                    }
                }
            }
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Processing measurements...")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Analyzing body landmarks and calculating dimensions")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var completedView: some View {
        VStack(spacing: 24) {
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Measurements Complete!")
                .font(.title2)
                .fontWeight(.bold)
            
            // Measurements summary
            if let measurements = viewModel.measurements {
                measurementsSummary(measurements)
            }
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            switch viewModel.captureState {
            case .initial:
                Button(action: startCapture) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Start Capture")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
            case .completed, .failed:
                Button(action: viewModel.reset) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Capture Again")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
            default:
                EmptyView()
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func instructionRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    private func capturePreview(image: UIImage, label: String) -> some View {
        VStack(spacing: 8) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                )
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func measurementsSummary(_ measurements: BodyMeasurements) -> some View {
        VStack(spacing: 12) {
            measurementRow(label: "Height", value: measurements.height_cm, unit: "cm")
            measurementRow(label: "Chest", value: measurements.chest_cm, unit: "cm")
            measurementRow(label: "Waist", value: measurements.waist_natural_cm, unit: "cm")
            measurementRow(label: "Hip", value: measurements.hip_low_cm, unit: "cm")
            measurementRow(label: "Inseam", value: measurements.inseam_cm, unit: "cm")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
    }
    
    private func measurementRow(label: String, value: Double, unit: String) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(String(format: "%.1f %@", value, unit))
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
    }
    
    // MARK: - Actions
    
    private func startCapture() {
        viewModel.startFrontCapture()
        showingFrontCamera = true
    }
}

// MARK: - Preview

struct CaptureFlowView_Previews: PreviewProvider {
    static var previews: some View {
        CaptureFlowView()
    }
}
