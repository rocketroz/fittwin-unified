import SwiftUI

struct HowItWorksView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("How It Works")
                .font(.system(size: 34, weight: .bold))
            
            Spacer()
            
            VStack(spacing: 40) {
                StepView(
                    number: 1,
                    icon: "iphone.and.arrow.forward",
                    title: "Place Your Phone",
                    description: "Set your phone on the floor against a wall at the right angle"
                )
                
                StepView(
                    number: 2,
                    icon: "figure.stand",
                    title: "Get in Frame",
                    description: "Step back 6-8 feet and match the on-screen body outline"
                )
                
                StepView(
                    number: 3,
                    icon: "camera.fill",
                    title: "Auto Capture",
                    description: "Hold still for 10 seconds, then rotate 90° for side view"
                )
                
                StepView(
                    number: 4,
                    icon: "checkmark.circle.fill",
                    title: "Get Measurements",
                    description: "AI processes your photos and delivers 50+ accurate measurements"
                )
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            Text("Swipe to continue")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.bottom, 40)
        }
    }
}

struct StepView: View {
    let number: Int
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Number badge
            ZStack {
                Circle()
                    .fill(Color.teal)
                    .frame(width: 40, height: 40)
                Text("\(number)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(.teal)
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    HowItWorksView()
}
