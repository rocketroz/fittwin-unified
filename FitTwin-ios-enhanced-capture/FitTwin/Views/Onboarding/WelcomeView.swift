import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo/Icon
            Image(systemName: "figure.stand")
                .font(.system(size: 100))
                .foregroundColor(.teal)
            
            // Title
            Text("Welcome to FitTwin")
                .font(.system(size: 34, weight: .bold))
                .multilineTextAlignment(.center)
            
            // Subtitle
            Text("Your Digital Twin for Perfect Fit Shopping")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Features
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(icon: "camera.fill", title: "AI Body Scanning", description: "Accurate measurements using your phone's camera")
                FeatureRow(icon: "ruler.fill", title: "50+ Measurements", description: "Professional-grade body measurements")
                FeatureRow(icon: "checkmark.seal.fill", title: "Perfect Fit", description: "Always order the right size, every time")
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Swipe hint
            Text("Swipe to continue")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.bottom, 40)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.teal)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    WelcomeView()
}
