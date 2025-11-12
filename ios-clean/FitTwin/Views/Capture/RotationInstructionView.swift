import SwiftUI

struct RotationInstructionView: View {
    let onContinue: () -> Void
    
    @State private var hasSpoken = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Rotation icon
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 100))
                .foregroundColor(.teal)
                .rotationEffect(.degrees(90))
            
            // Title
            Text("Rotate 90°")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
            
            // Instructions
            VStack(alignment: .leading, spacing: 20) {
                InstructionRow(
                    number: 1,
                    text: "Stay in the same position"
                )
                InstructionRow(
                    number: 2,
                    text: "Turn your body 90° to the right"
                )
                InstructionRow(
                    number: 3,
                    text: "Show your profile to the camera"
                )
                InstructionRow(
                    number: 4,
                    text: "Keep arms in the same position"
                )
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Continue button
            Button(action: {
                AudioNarrator.shared.speak("Great! Now let's capture your side view.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    onContinue()
                }
            }) {
                Text("I'm Ready")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.teal)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            if !hasSpoken {
                AudioNarrator.shared.speak("Great job! Now rotate 90 degrees to your right to show your profile.")
                hasSpoken = true
            }
        }
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.teal)
                    .frame(width: 32, height: 32)
                Text("\(number)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.system(size: 18))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    RotationInstructionView {
        print("Continue")
    }
}
