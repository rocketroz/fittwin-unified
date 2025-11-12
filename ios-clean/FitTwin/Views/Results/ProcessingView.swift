import SwiftUI

struct ProcessingView: View {
    let progress: Double
    
    @State private var hasSpoken = false
    
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
