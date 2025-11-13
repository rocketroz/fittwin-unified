import SwiftUI

struct OnboardingCoordinatorView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var userHeight: Double = 170.0 // Default 170cm
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            TabView(selection: $currentStep) {
                WelcomeView()
                    .tag(0)
                
                HowItWorksView()
                    .tag(1)
                
                ClothingGuidanceView()
                    .tag(2)
                
                HeightInputView(height: $userHeight) {
                    completeOnboarding()
                }
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
    
    private func completeOnboarding() {
        appState.completeOnboarding(height: userHeight)
    }
}

#Preview {
    OnboardingCoordinatorView()
        .environmentObject(AppState())
}
