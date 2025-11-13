
import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Your Measurements")
                .font(.largeTitle)
                .fontWeight(.bold)

            if let measurements = appModel.bodyMeasurements {
                Group {
                    if let height = measurements.height {
                        MeasurementRow(label: "Height", value: height)
                    }
                    if let armSpan = measurements.armSpan {
                        MeasurementRow(label: "Arm Span", value: armSpan)
                    }
                    if let inseam = measurements.inseam {
                        MeasurementRow(label: "Inseam", value: inseam)
                    }
                    if let chest = measurements.chest {
                        MeasurementRow(label: "Chest Circumference", value: chest)
                    }
                    if let waist = measurements.waist {
                        MeasurementRow(label: "Waist Circumference", value: waist)
                    }
                    if let hips = measurements.hips {
                        MeasurementRow(label: "Hips Circumference", value: hips)
                    }
                }
            } else {
                Text("No measurements available.")
            }

            Spacer()

            Button(action: {
                appModel.appState = .selectingMode
            }) {
                Text("Start Over")
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct MeasurementRow: View {
    var label: String
    var value: Double

    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.semibold)
            Spacer()
            Text(String(format: "%.2f cm", value))
        }
        .font(.title2)
    }
}
