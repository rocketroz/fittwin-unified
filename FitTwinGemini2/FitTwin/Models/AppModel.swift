
import Foundation
import Combine

enum AppState {
    case idle
    case selectingMode
    case soloScanning
    case proScanning
    case processing
    case results
}

class AppModel: ObservableObject {
    @Published var appState: AppState = .selectingMode
    @Published var bodyMeasurements: BodyMeasurements?
}
