import SwiftUI

/// Displays clothing recommendations for optimal measurement capture
struct ClothingGuidanceView: View {
    @StateObject private var narrator = AudioNarrator()
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue.gradient)
                
                Text("What to Wear")
                    .font(.title.bold())
                
                Text("Wear form-fitting clothes for accurate measurements")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Recommendations
            VStack(alignment: .leading, spacing: 20) {
                RecommendationRow(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    title: "Fitted T-Shirt or Tank Top",
                    description: "Form-fitting top that shows your body shape"
                )
                
                RecommendationRow(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    title: "Fitted Shorts or Leggings",
                    description: "Tight-fitting bottoms, not baggy pants"
                )
                
                RecommendationRow(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    title: "Solid Colors",
                    description: "Avoid busy patterns for best results"
                )
                
                RecommendationRow(
                    icon: "xmark.circle.fill",
                    iconColor: .red,
                    title: "Avoid Baggy Clothes",
                    description: "Loose clothing hides your body shape"
                )
                
                RecommendationRow(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    title: "Barefoot or Thin Shoes",
                    description: "No thick-soled shoes"
                )
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            
            Spacer()
            
            // Continue Button
            Button(action: onContinue) {
                Text("I'm Ready")
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
            narrator.narrateVolumePrompt()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                narrator.narrateClothingInstructions()
            }
        }
    }
}

struct RecommendationRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ClothingGuidanceView(onContinue: {})
}
