import SwiftUI

@main
struct FitTwinApp: App {
    
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.light) // Force light mode for consistency
        }
    }
}

/// Global app state
class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool = false
    @Published var userHeight: Double? = nil // in centimeters
    @Published var measurements: MeasurementData? = nil
    
    init() {
        // Load from UserDefaults
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if let height = UserDefaults.standard.object(forKey: "userHeight") as? Double {
            userHeight = height
        }
    }
    
    func completeOnboarding(height: Double) {
        self.userHeight = height
        self.hasCompletedOnboarding = true
        
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(height, forKey: "userHeight")
    }
    
    func saveMeasurements(_ data: MeasurementData) {
        self.measurements = data
        // TODO: Upload to backend
    }
    
    func reset() {
        hasCompletedOnboarding = false
        userHeight = nil
        measurements = nil
        
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "userHeight")
    }
}
