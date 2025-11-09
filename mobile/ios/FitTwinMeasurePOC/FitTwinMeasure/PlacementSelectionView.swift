//
//  PlacementSelectionView.swift
//  FitTwinMeasure
//
//  Created by FitTwin Team on 11/9/25.
//

import SwiftUI

struct PlacementSelectionView: View {
    @Binding var selectedPlacement: PlacementMode?
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
                    Text("📱 Solo Mode")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Choose phone placement")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Placement cards
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(PlacementMode.allCases, id: \.self) { mode in
                            PlacementCard(mode: mode) {
                                selectedPlacement = mode
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
        }
    }
}

struct PlacementCard: View {
    let mode: PlacementMode
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 15) {
                // Header with icon and badge
                HStack {
                    Text(mode.icon)
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(mode.rawValue)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if let badge = mode.badge {
                            Text(badge)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    Spacer()
                }
                
                // Illustration placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 120)
                    
                    // Simple illustration
                    VStack(spacing: 10) {
                        placementIllustration
                        
                        Text(illustrationLabel)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Description
                Text(mode.description)
                    .font(.body)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Select button
                HStack {
                    Spacer()
                    Text("Select")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var placementIllustration: some View {
        switch mode {
        case .ground:
            // Phone flat on ground
            VStack(spacing: 5) {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 60, height: 100)
                    .cornerRadius(8)
                
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120, height: 3)
            }
            
        case .wall:
            // Phone at 45° angle
            VStack(spacing: 5) {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 60, height: 100)
                    .cornerRadius(8)
                    .rotationEffect(.degrees(-45))
                
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 3, height: 80)
                    .offset(x: -40)
            }
            
        case .upright:
            // Phone standing vertical
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 60, height: 100)
                .cornerRadius(8)
        }
    }
    
    private var illustrationLabel: String {
        switch mode {
        case .ground:
            return "Phone flat, camera facing up"
        case .wall:
            return "Phone at 45° against wall"
        case .upright:
            return "Phone standing vertical"
        }
    }
}

struct PlacementSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        PlacementSelectionView(
            selectedPlacement: .constant(nil),
            onBack: {}
        )
    }
}
