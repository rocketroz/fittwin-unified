import SwiftUI

struct ResultsView: View {
    let measurements: MeasurementData
    let onComplete: () -> Void
    
    @State private var hasSpoken = false
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Measurements Complete!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Confidence: \(Int(measurements.confidenceScore * 100))%")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
            }
            .padding(.top, 40)
            .padding(.bottom, 20)
            
            // Tab selector
            Picker("Category", selection: $selectedTab) {
                Text("Primary").tag(0)
                Text("Detailed").tag(1)
                Text("All").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Measurements list
            ScrollView {
                VStack(spacing: 0) {
                    if selectedTab == 0 {
                        primaryMeasurements
                    } else if selectedTab == 1 {
                        detailedMeasurements
                    } else {
                        allMeasurements
                    }
                }
            }
            .background(Color.white)
            
            // Bottom buttons
            VStack(spacing: 12) {
                Button(action: {
                    // TODO: Upload to backend
                    AudioNarrator.shared.speak("Measurements saved successfully!")
                    onComplete()
                }) {
                    Text("Save & Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.teal)
                        .cornerRadius(16)
                }
                
                Button(action: {
                    // TODO: Share functionality
                }) {
                    Text("Share Results")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.teal)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(Color.black)
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            if !hasSpoken {
                AudioNarrator.shared.speak("Success! Your measurements are ready. You can now save them to your profile.")
                hasSpoken = true
            }
        }
    }
    
    // MARK: - Primary Measurements
    
    private var primaryMeasurements: some View {
        VStack(spacing: 0) {
            MeasurementRow(
                label: "Height",
                value: formatHeight(measurements.measurements.height),
                icon: "arrow.up.and.down"
            )
            MeasurementRow(
                label: "Shoulder Width",
                value: formatCm(measurements.measurements.shoulderWidth),
                icon: "arrow.left.and.right"
            )
            MeasurementRow(
                label: "Chest",
                value: formatCm(measurements.measurements.chestCircumference),
                icon: "circle"
            )
            MeasurementRow(
                label: "Waist",
                value: formatCm(measurements.measurements.waistCircumference),
                icon: "circle"
            )
            MeasurementRow(
                label: "Hips",
                value: formatCm(measurements.measurements.hipCircumference),
                icon: "circle"
            )
            MeasurementRow(
                label: "Inseam",
                value: formatCm(measurements.measurements.inseam),
                icon: "arrow.up.and.down"
            )
            MeasurementRow(
                label: "Arm Length",
                value: formatCm(measurements.measurements.armLength),
                icon: "arrow.left.and.right"
            )
        }
    }
    
    // MARK: - Detailed Measurements
    
    private var detailedMeasurements: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Upper Body")
            MeasurementRow(label: "Neck", value: formatCm(measurements.measurements.neckCircumference), icon: "circle")
            MeasurementRow(label: "Bicep", value: formatCm(measurements.measurements.bicepCircumference), icon: "circle")
            MeasurementRow(label: "Forearm", value: formatCm(measurements.measurements.forearmCircumference), icon: "circle")
            MeasurementRow(label: "Wrist", value: formatCm(measurements.measurements.wristCircumference), icon: "circle")
            
            SectionHeader(title: "Lower Body")
            MeasurementRow(label: "Thigh", value: formatCm(measurements.measurements.thighCircumference), icon: "circle")
            MeasurementRow(label: "Calf", value: formatCm(measurements.measurements.calfCircumference), icon: "circle")
            MeasurementRow(label: "Ankle", value: formatCm(measurements.measurements.ankleCircumference), icon: "circle")
            
            SectionHeader(title: "Lengths")
            MeasurementRow(label: "Torso", value: formatCm(measurements.measurements.torsoLength), icon: "arrow.up.and.down")
            MeasurementRow(label: "Leg", value: formatCm(measurements.measurements.legLength), icon: "arrow.up.and.down")
            MeasurementRow(label: "Arm Span", value: formatCm(measurements.measurements.armSpan), icon: "arrow.left.and.right")
        }
    }
    
    // MARK: - All Measurements
    
    private var allMeasurements: some View {
        VStack(spacing: 0) {
            primaryMeasurements
            detailedMeasurements
            
            SectionHeader(title: "Widths")
            MeasurementRow(label: "Chest Width", value: formatCm(measurements.measurements.chestWidth), icon: "arrow.left.and.right")
            MeasurementRow(label: "Waist Width", value: formatCm(measurements.measurements.waistWidth), icon: "arrow.left.and.right")
            MeasurementRow(label: "Hip Width", value: formatCm(measurements.measurements.hipWidth), icon: "arrow.left.and.right")
            
            SectionHeader(title: "Depths")
            MeasurementRow(label: "Chest Depth", value: formatCm(measurements.measurements.chestDepth), icon: "arrow.forward.and.backward")
            MeasurementRow(label: "Waist Depth", value: formatCm(measurements.measurements.waistDepth), icon: "arrow.forward.and.backward")
            MeasurementRow(label: "Hip Depth", value: formatCm(measurements.measurements.hipDepth), icon: "arrow.forward.and.backward")
        }
    }
    
    // MARK: - Formatting
    
    private func formatCm(_ value: Double) -> String {
        "\(Int(value.rounded())) cm / \(String(format: "%.1f", value / 2.54))""
    }
    
    private func formatHeight(_ cm: Double) -> String {
        let (feet, inches) = measurements.measurements.heightFeetInches
        return "\(Int(cm)) cm / \(feet)' \(String(format: "%.1f", inches))""
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
    }
}

// MARK: - Measurement Row

struct MeasurementRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.teal)
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 16))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.teal)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

#Preview {
    ResultsView(
        measurements: MeasurementData(
            userHeight: 175.0,
            measurements: Measurements(
                height: 175.0,
                shoulderWidth: 45.0,
                chestCircumference: 95.0,
                waistCircumference: 80.0,
                hipCircumference: 95.0,
                inseam: 80.0,
                armLength: 60.0,
                neckCircumference: 38.0,
                bicepCircumference: 32.0,
                forearmCircumference: 26.0,
                wristCircumference: 17.0,
                thighCircumference: 55.0,
                calfCircumference: 36.0,
                ankleCircumference: 23.0,
                torsoLength: 50.0,
                legLength: 90.0,
                armSpan: 175.0,
                chestWidth: 40.0,
                waistWidth: 32.0,
                hipWidth: 38.0,
                chestDepth: 22.0,
                waistDepth: 20.0,
                hipDepth: 24.0
            ),
            frontLandmarks: [],
            sideLandmarks: [],
            confidenceScore: 0.92
        )
    ) {
        print("Complete")
    }
}
