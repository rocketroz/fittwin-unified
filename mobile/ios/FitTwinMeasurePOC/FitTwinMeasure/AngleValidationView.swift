//
//  AngleValidationView.swift
//  FitTwinMeasure
//
//  Created by FitTwin Team on 11/9/25.
//

import SwiftUI

struct AngleValidationView: View {
    let placementMode: PlacementMode
    @StateObject private var angleValidator = PhoneAngleValidator()
    @State private var showContinueButton = false
    let onContinue: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Header
                HStack {
                    Button(action: onBack) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                VStack(spacing: 10) {
                    Text("📐 Adjust Phone Angle")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(placementMode.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Camera preview placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 300)
                    
                    VStack(spacing: 20) {
                        // Level indicator
                        LevelIndicator(
                            position: angleValidator.getLevelIndicator(),
                            isCorrect: angleValidator.isAngleCorrect
                        )
                        
                        // Camera preview text
                        Text("Camera Preview")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                
                // Angle status
                VStack(spacing: 15) {
                    HStack {
                        Text("Current Angle:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(String(format: "%.1f", angleValidator.currentPitch))°")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Target Angle:")
                            .foregroundColor(.gray)
                        Spacer()
                        HStack(spacing: 5) {
                            Text("\(String(format: "%.0f", placementMode.targetPitch))°")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            
                            if angleValidator.isAngleCorrect {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
                .background(Color.white.opacity(0.05))
                .cornerRadius(15)
                .padding(.horizontal, 20)
                
                // Guidance message
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(angleValidator.isAngleCorrect ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .frame(height: 60)
                    
                    HStack(spacing: 10) {
                        Image(systemName: angleValidator.isAngleCorrect ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(angleValidator.isAngleCorrect ? .green : .orange)
                        
                        Text(angleValidator.adjustmentGuidance)
                            .font(.body)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 15) {
                    if angleValidator.isAngleCorrect || showContinueButton {
                        Button(action: onContinue) {
                            Text("Continue to Positioning")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                    }
                    
                    Button(action: {
                        showContinueButton = true
                    }) {
                        Text("Skip Validation (not recommended)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            print("🎬 AngleValidationView appeared for \(placementMode.rawValue)")
            angleValidator.startMonitoring(for: placementMode)
        }
        .onDisappear {
            print("👋 AngleValidationView disappeared")
            angleValidator.stopMonitoring()
        }
    }
}

struct LevelIndicator: View {
    let position: Double  // 0.0 to 1.0, where 0.5 is perfect
    let isCorrect: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            // Level bar
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 200, height: 8)
                
                // Center marker
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 2, height: 20)
                    .offset(x: 100)
                
                // Current position indicator
                Circle()
                    .fill(isCorrect ? Color.green : Color.orange)
                    .frame(width: 20, height: 20)
                    .offset(x: CGFloat(position * 200) - 10)
                    .animation(.easeInOut(duration: 0.2), value: position)
            }
            
            // Labels
            HStack {
                Text("Backward")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("Perfect")
                    .font(.caption2)
                    .foregroundColor(isCorrect ? .green : .gray)
                    .fontWeight(isCorrect ? .bold : .regular)
                
                Spacer()
                
                Text("Forward")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .frame(width: 200)
        }
    }
}

struct AngleValidationView_Previews: PreviewProvider {
    static var previews: some View {
        AngleValidationView(
            placementMode: .ground,
            onContinue: {},
            onBack: {}
        )
    }
}
