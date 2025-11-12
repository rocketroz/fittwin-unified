import SwiftUI

struct HeightInputView: View {
    @Binding var height: Double
    let onComplete: () -> Void
    
    @State private var heightUnit: HeightUnit = .cm
    @State private var feet: Int = 5
    @State private var inches: Double = 7.0
    
    enum HeightUnit {
        case cm
        case feetInches
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Enter Your Height")
                .font(.system(size: 34, weight: .bold))
            
            Text("This helps us calculate accurate measurements")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Unit selector
            Picker("Unit", selection: $heightUnit) {
                Text("cm").tag(HeightUnit.cm)
                Text("ft/in").tag(HeightUnit.feetInches)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 60)
            .onChange(of: heightUnit) { _, newValue in
                updateHeight()
            }
            
            // Height input
            if heightUnit == .cm {
                VStack(spacing: 10) {
                    Text("\(Int(height)) cm")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.teal)
                    
                    Slider(value: $height, in: 120...220, step: 1)
                        .padding(.horizontal, 40)
                        .tint(.teal)
                }
            } else {
                VStack(spacing: 10) {
                    Text("\(feet)' \(String(format: "%.1f\"", inches))")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.teal)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text("Feet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Picker("Feet", selection: $feet) {
                                ForEach(4...7, id: \.self) { ft in
                                    Text("\(ft)").tag(ft)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 120)
                            .clipped()
                        }
                        
                        VStack {
                            Text("Inches")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Picker("Inches", selection: $inches) {
                                ForEach(0..<12) { inch in
                                    Text("\(inch)").tag(Double(inch))
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 120)
                            .clipped()
                        }
                    }
                    .onChange(of: feet) { _, _ in updateHeight() }
                    .onChange(of: inches) { _, _ in updateHeight() }
                }
            }
            
            Spacer()
            
            // Continue button
            Button(action: onComplete) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.teal)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .onAppear {
            // Initialize from cm height
            let totalInches = height / 2.54
            feet = Int(totalInches / 12)
            inches = totalInches.truncatingRemainder(dividingBy: 12)
        }
    }
    
    private func updateHeight() {
        if heightUnit == .feetInches {
            let totalInches = Double(feet * 12) + inches
            height = totalInches * 2.54
        }
    }
}

#Preview {
    HeightInputView(height: .constant(170.0)) {
        print("Complete")
    }
}
