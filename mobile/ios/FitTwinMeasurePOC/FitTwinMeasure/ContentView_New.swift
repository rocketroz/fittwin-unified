//
//  ContentView_New.swift
//  FitTwinMeasure
//
//  Created by FitTwin Team on 11/9/25.
//  New ContentView with Solo Mode and Two Person Mode selection
//

import SwiftUI

struct ContentView_New: View {
    @State private var selectedMode: CaptureMode?
    @State private var selectedPlacement: PlacementMode?
    @State private var showAngleValidation = false
    @State private var showCapture = false
    @State private var measurements: BodyMeasurements?
    
    var body: some View {
        ZStack {
            if selectedMode == nil {
                // Mode selection
                ModeSelectionView(selectedMode: $selectedMode)
            } else if selectedMode == .solo {
                // Solo Mode flow
                if selectedPlacement == nil {
                    PlacementSelectionView(
                        selectedPlacement: $selectedPlacement,
                        onBack: { selectedMode = nil }
                    )
                } else if !showAngleValidation {
                    // Angle validation
                    AngleValidationView(
                        placementMode: selectedPlacement!,
                        onContinue: { showAngleValidation = true },
                        onBack: { selectedPlacement = nil }
                    )
                } else {
                    // Solo Mode capture
                    SoloModeCaptureView(
                        placementMode: selectedPlacement!,
                        onBack: {
                            showAngleValidation = false
                            selectedPlacement = nil
                            selectedMode = nil
                        },
                        onComplete: { result in
                            measurements = result
                            // TODO: Handle completion
                        }
                    )
                }
            } else if selectedMode == .twoPerson {
                // Two Person Mode (existing ARKit implementation)
                if #available(iOS 13.0, *) {
                    ARBodyCaptureView_Enhanced()
                        .onDisappear {
                            selectedMode = nil
                        }
                } else {
                    Text("ARKit Body Tracking requires iOS 13+")
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct ContentView_New_Previews: PreviewProvider {
    static var previews: some View {
        ContentView_New()
    }
}
