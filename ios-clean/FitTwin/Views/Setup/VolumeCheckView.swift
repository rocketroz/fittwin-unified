import SwiftUI

struct VolumeCheckView: View {
    let onContinue: () -> Void
    
    @State private var hasConfirmed = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 80))
                .foregroundColor(.teal)
            
            // Title
            Text("Turn Up Your Volume")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Description
            Text("FitTwin uses audio guidance to help you through the measurement process. Please turn up your volume so you can hear the instructions.")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Test audio button
            Button(action: {
                AudioNarrator.shared.speak("This is a test. Can you hear me clearly?")
                hasConfirmed = true
            }) {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Test Audio")
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.teal)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white)
                .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            
            // Continue button
            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(hasConfirmed ? Color.teal : Color.gray.opacity(0.5))
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            .disabled(!hasConfirmed)
            
            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
    }
}

#Preview {
    VolumeCheckView {
        print("Continue")
    }
}
