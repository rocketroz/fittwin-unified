import SwiftUI

struct CaptureCoordinatorView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = CaptureViewModel()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            switch viewModel.currentStep {
            case .volumeCheck:
                VolumeCheckView {
                    viewModel.moveToNext()
                }
                
            case .phoneSetup:
                PhoneSetupView {
                    viewModel.moveToNext()
                }
                
            case .frontCapture:
                CaptureView(
                    viewType: .front,
                    userHeight: appState.userHeight ?? 170.0,
                    onComplete: { landmarks, image in
                        viewModel.saveFrontCapture(landmarks: landmarks, image: image)
                    }
                )
                
            case .rotationInstruction:
                RotationInstructionView {
                    viewModel.moveToNext()
                }
                
            case .sideCapture:
                CaptureView(
                    viewType: .side,
                    userHeight: appState.userHeight ?? 170.0,
                    onComplete: { landmarks, image in
                        viewModel.saveSideCapture(landmarks: landmarks, image: image)
                    }
                )
                
            case .processing:
                ProcessingView(progress: viewModel.processingProgress)
                
            case .results:
                if let measurements = viewModel.measurements {
                    ResultsView(measurements: measurements) {
                        appState.saveMeasurements(measurements)
                        viewModel.reset()
                    }
                }
            }
        }
        .onAppear {
            viewModel.appState = appState
        }
    }
}

// MARK: - ViewModel

@MainActor
class CaptureViewModel: ObservableObject {
    @Published var currentStep: CaptureStep = .volumeCheck
    @Published var processingProgress: Double = 0.0
    @Published var measurements: MeasurementData?
    
    var appState: AppState?
    
    private var frontLandmarks: [Landmark]?
    private var sideLandmarks: [Landmark]?
    private var frontImage: UIImage?
    private var sideImage: UIImage?
    
    enum CaptureStep {
        case volumeCheck
        case phoneSetup
        case frontCapture
        case rotationInstruction
        case sideCapture
        case processing
        case results
    }
    
    func moveToNext() {
        switch currentStep {
        case .volumeCheck:
            currentStep = .phoneSetup
        case .phoneSetup:
            currentStep = .frontCapture
        case .frontCapture:
            currentStep = .rotationInstruction
        case .rotationInstruction:
            currentStep = .sideCapture
        case .sideCapture:
            currentStep = .processing
            processMeasurements()
        case .processing:
            currentStep = .results
        case .results:
            break
        }
    }
    
    func saveFrontCapture(landmarks: [Landmark], image: UIImage) {
        self.frontLandmarks = landmarks
        self.frontImage = image
        moveToNext()
    }
    
    func saveSideCapture(landmarks: [Landmark], image: UIImage) {
        self.sideLandmarks = landmarks
        self.sideImage = image
        moveToNext()
    }
    
    private func processMeasurements() {
        guard let frontLandmarks = frontLandmarks,
              let sideLandmarks = sideLandmarks,
              let userHeight = appState?.userHeight else {
            return
        }
        
        Task {
            // Simulate processing with progress
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                processingProgress = Double(i) / 10.0
            }
            
            // Calculate measurements
            if let calculatedMeasurements = MeasurementCalculator.calculateMeasurements(
                frontLandmarks: frontLandmarks,
                sideLandmarks: sideLandmarks,
                userHeight: userHeight,
                imageSize: CGSize(width: 1080, height: 1920) // Assume standard size
            ) {
                // Validate
                if MeasurementCalculator.validateMeasurements(calculatedMeasurements) {
                    let measurementData = MeasurementData(
                        userHeight: userHeight,
                        measurements: calculatedMeasurements,
                        frontLandmarks: frontLandmarks,
                        sideLandmarks: sideLandmarks,
                        frontImage: frontImage?.jpegData(compressionQuality: 0.8),
                        sideImage: sideImage?.jpegData(compressionQuality: 0.8),
                        confidenceScore: calculateConfidence(frontLandmarks: frontLandmarks, sideLandmarks: sideLandmarks)
                    )
                    
                    self.measurements = measurementData
                    moveToNext()
                }
            }
        }
    }
    
    private func calculateConfidence(frontLandmarks: [Landmark], sideLandmarks: [Landmark]) -> Double {
        let frontValid = frontLandmarks.filter { $0.isValid }.count
        let sideValid = sideLandmarks.filter { $0.isValid }.count
        return Double(frontValid + sideValid) / Double(frontLandmarks.count + sideLandmarks.count)
    }
    
    func reset() {
        currentStep = .volumeCheck
        processingProgress = 0.0
        measurements = nil
        frontLandmarks = nil
        sideLandmarks = nil
        frontImage = nil
        sideImage = nil
    }
}

#Preview {
    CaptureCoordinatorView()
        .environmentObject(AppState())
}
