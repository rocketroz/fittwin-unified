
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        VStack {
            switch appModel.appState {
            case .idle:
                Text("Idle")
            case .selectingMode:
                ModeSelectionView()
            case .soloScanning:
                SoloScanView()
            case .proScanning:
                ProScanView()
            case .processing:
                Text("Processing...")
            case .results:
                ResultsView()
            }
        }
    }
}
