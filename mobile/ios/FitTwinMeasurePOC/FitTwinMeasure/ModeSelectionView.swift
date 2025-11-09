//
//  ModeSelectionView.swift
//  FitTwinMeasure
//
//  Created by FitTwin Team on 11/9/25.
//

import SwiftUI

struct ModeSelectionView: View {
    @Binding var selectedMode: CaptureMode?
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Text("FitTwin Body Measurement")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("How would you like to measure?")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Mode cards
                VStack(spacing: 20) {
                    ForEach(CaptureMode.allCases, id: \.self) { mode in
                        ModeCard(mode: mode) {
                            selectedMode = mode
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Settings button
                Button(action: {
                    // TODO: Show settings
                }) {
                    HStack {
                        Image(systemName: "gearshape")
                        Text("Settings")
                    }
                    .foregroundColor(.gray)
                }
                .padding(.bottom, 20)
            }
        }
    }
}

struct ModeCard: View {
    let mode: CaptureMode
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
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if let badge = mode.badge {
                            Text(badge)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(mode == .solo ? .green : .orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    (mode == .solo ? Color.green : Color.orange)
                                        .opacity(0.2)
                                )
                                .cornerRadius(4)
                        }
                    }
                    
                    Spacer()
                }
                
                // Description
                Text(mode.description)
                    .font(.body)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Features
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(mode.features, id: \.self) { feature in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(.gray)
                            Text(feature)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Action button
                HStack {
                    Spacer()
                    Text("Start \(mode.rawValue)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(mode == .solo ? Color.green : Color.blue)
                        .cornerRadius(8)
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ModeSelectionView(selectedMode: .constant(nil))
    }
}
