import SwiftUI

/// Enhanced capture flow with clothing guidance, phone setup, and audio narration
struct EnhancedCaptureFlowView: View {
    @StateObject private var narrator = AudioNarrator()
    @State private var currentStep: CaptureStep = .clothingGuidance
    
    enum CaptureStep {
        case clothingGuidance
        case phoneSetup
        case positioning
        case frontCapture
        case rotation
        case sideCapture
        case processing
        case complete
    }
    
    var body: some View {
        Group {
            switch currentStep {
            case .clothingGuidance:
                ClothingGuidanceView {
                    currentStep = .phoneSetup
                }
                
            case .phoneSetup:
                PhoneSetupView {
                    currentStep = .positioning
                    narrator.narrateStepBack()
                }
                
            case .positioning:
                PositioningView {
                    currentStep = .frontCapture
                }
                
            case .frontCapture:
                CaptureView(
                    title: "Front Photo",
                    instruction: "Stand straight, arms slightly away from body",
                    countdown: 10,
                    onComplete: {
                        currentStep = .rotation
                        narrator.narrateRotateInstruction()
                    }
                )
                
            case .rotation:
                RotationInstructionView {
                    currentStep = .sideCapture
                }
                
            case .sideCapture:
                CaptureView(
                    title: "Side Photo",
                    instruction: "Turn 90° left, keep arms in same position",
                    countdown: 5,
                    onComplete: {
                        currentStep = .processing
                        narrator.narrateProcessing()
                    }
                )
                
            case .processing:
                ProcessingView {
                    currentStep = .complete
                    narrator.narrateComplete()
                }
                
            case .complete:
                CompletionView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Positioning View

struct PositioningView: View {
    @StateObject private var narrator = AudioNarrator()
    let onReady: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Get in Position")
                .font(.title.bold())
            
            VStack(spacing: 20) {
                Image(systemName: "figure.stand")
                    .font(.system(size: 100))
                    .foregroundStyle(.blue.gradient)
                
                Text("Step back 6-8 feet from your phone")
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                PositioningTip(icon: "arrow.left.and.right", text: "Stand with arms slightly away from body")
                PositioningTip(icon: "eye", text: "Look at your phone screen")
                PositioningTip(icon: "sun.max", text: "Make sure lighting is even")
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            
            Spacer()
            
            Button(action: onReady) {
                Text("I'm in Position")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(24)
        .onAppear {
            narrator.narrateFrontPoseInstructions()
        }
    }
}

struct PositioningTip: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Capture View with Countdown

struct CaptureView: View {
    let title: String
    let instruction: String
    let countdown: Int
    let onComplete: () -> Void
    
    @State private var timeRemaining: Int
    @State private var isCapturing = false
    
    init(title: String, instruction: String, countdown: Int, onComplete: @escaping () -> Void) {
        self.title = title
        self.instruction = instruction
        self.countdown = countdown
        self.onComplete = onComplete
        self._timeRemaining = State(initialValue: countdown)
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Text(title)
                .font(.title.bold())
            
            // Countdown Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(countdown))
                    .stroke(.blue.gradient, lineWidth: 12)
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timeRemaining)
                
                Text("\(timeRemaining)")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(.blue)
            }
            
            Text(instruction)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            // AR Body Outline Placeholder
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .frame(height: 300)
                .overlay {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 120))
                        .foregroundStyle(.blue.opacity(0.3))
                }
            
            Spacer()
        }
        .padding(24)
        .onAppear {
            startCountdown()
        }
    }
    
    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer.invalidate()
                onComplete()
            }
        }
    }
}

// MARK: - Rotation Instruction View

struct RotationInstructionView: View {
    let onReady: () -> Void
    @State private var timeRemaining = 5
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Rotate Left")
                .font(.title.bold())
            
            Image(systemName: "arrow.turn.up.left")
                .font(.system(size: 100))
                .foregroundStyle(.blue.gradient)
            
            Text("Turn 90° to your left")
                .font(.headline)
            
            Text("Auto-advancing in \(timeRemaining)...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(24)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timer.invalidate()
                    onReady()
                }
            }
        }
    }
}

// MARK: - Processing View

struct ProcessingView: View {
    let onComplete: () -> Void
    @State private var progress: Double = 0.0
    
    var body: some View {
        VStack(spacing: 32) {
            Text("Processing")
                .font(.title.bold())
            
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(.linear)
                .scaleEffect(y: 2)
                .tint(.blue)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.blue)
            
            Text("Creating your digital twin...")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(24)
        .onAppear {
            simulateProcessing()
        }
    }
    
    private func simulateProcessing() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            if progress < 1.0 {
                progress += 0.033 // ~30 seconds total
            } else {
                timer.invalidate()
                onComplete()
            }
        }
    }
}

// MARK: - Completion View

struct CompletionView: View {
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.green)
            
            Text("Success!")
                .font(.title.bold())
            
            Text("Your digital twin is ready")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button("View My Avatar") {
                // Navigate to avatar view
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }
}

#Preview {
    NavigationStack {
        EnhancedCaptureFlowView()
    }
}
