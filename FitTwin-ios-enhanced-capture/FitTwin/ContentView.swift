import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                // Main app - go straight to capture flow
                CaptureCoordinatorView()
            } else {
                // Onboarding flow
                OnboardingCoordinatorView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
