import SwiftUI

/// Guides user to place phone at correct angle on the floor
struct PhoneSetupView: View {
    @StateObject private var angleDetector = PhoneAngleDetector()
    @StateObject private var narrator = AudioNarrator()
    let onContinue: () -> Void
    
    @State private var hasNarratedInstructions = false
    @State private var hasNarratedSuccess = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue.gradient)
                    .rotationEffect(.degrees(-15)) // Show tilted phone
                
                Text("Phone Setup")
                    .font(.title.bold())
                
                Text("Place your phone on the floor against a wall")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Angle Indicator
            VStack(spacing: 16) {
                // Visual angle meter
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 150, height: 150)
                    
                    Circle()
                        .trim(from: 0, to: min(angleDetector.currentAngle / 90, 1.0))
                        .stroke(angleColor, lineWidth: 8)
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: angleDetector.currentAngle)
                    
                    VStack(spacing: 4) {
                        Text("\(Int(angleDetector.currentAngle))°")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(angleColor)
                        Text("Current Angle")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Status Message
                HStack(spacing: 8) {
                    Image(systemName: angleDetector.isCorrectAngle ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(angleColor)
                    Text(angleDetector.angleStatus.message)
                        .font(.headline)
                        .foregroundStyle(angleColor)
                }
                .padding()
                .background(angleColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            
            // Instructions
            VStack(alignment: .leading, spacing: 16) {
                InstructionStep(number: 1, text: "Find a plain wall with good lighting")
                InstructionStep(number: 2, text: "Place phone on floor against wall")
                InstructionStep(number: 3, text: "Tilt top of phone back 15-20°")
                InstructionStep(number: 4, text: "Wait for green indicator")
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            
            Spacer()
            
            // Continue Button (only enabled when angle is correct)
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(angleDetector.isCorrectAngle ? Color.blue.gradient : Color.gray.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!angleDetector.isCorrectAngle)
            .animation(.easeInOut, value: angleDetector.isCorrectAngle)
        }
        .padding(24)
        .onAppear {
            if !hasNarratedInstructions {
                narrator.narratePhonePlacement()
                hasNarratedInstructions = true
            }
        }
        .onChange(of: angleDetector.isCorrectAngle) { _, isCorrect in
            if isCorrect && !hasNarratedSuccess {
                narrator.narratePhoneAngleCorrect()
                hasNarratedSuccess = true
            }
        }
    }
    
    private var angleColor: Color {
        switch angleDetector.angleStatus {
        case .tooSteep:
            return .red
        case .perfect:
            return .green
        case .tooFlat:
            return .orange
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(.blue.gradient, in: Circle())
            
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    PhoneSetupView(onContinue: {})
}
