
import SwiftUI

struct ModeSelectionView: View {
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        VStack(spacing: 40) {
            Text("Select Your Scan Mode")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack {
                Button(action: {
                    appModel.appState = .soloScanning
                }) {
                    Text("Solo Scan")
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Text("For height & length estimates. Requires you to enter your height for scale.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            VStack {
                Button(action: {
                    appModel.appState = .proScanning
                }) {
                    Text("Pro Scan")
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Text("For high-accuracy circumference & length. Requires a partner.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
}
