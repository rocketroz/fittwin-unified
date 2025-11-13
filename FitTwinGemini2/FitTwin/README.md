
# FitTwin iOS App

This is a native iOS application for body measurement using two different modes: "Solo Scan" and "Pro Scan".

## Architecture

The app is built using SwiftUI and follows a modular architecture.

- **`FitTwinApp.swift`**: The main entry point of the application.
- **`Models/`**: Contains the data models for the app.
  - **`AppModel.swift`**: Manages the overall state of the app.
  - **`BodyMeasurements.swift`**: A struct to hold the measurement data.
- **`Views/`**: Contains the SwiftUI views.
  - **`ContentView.swift`**: The main view that routes between other views based on the app state.
  - **`ModeSelectionView.swift`**: The screen where the user selects the scan mode.
  - **`SoloScan/`**: Views for the "Solo Scan" mode (front camera + MediaPipe).
  - **`ProScan/`**: Views for the "Pro Scan" mode (rear LiDAR + Object Capture).
  - **`Results/`**: The view to display the measurement results.
- **`Services/`**: Contains the business logic for the app.
  - **`MediaPipeService.swift`**: A service to interact with the MediaPipe Pose Landmarker.
  - **`SoloMeasurementService.swift`**: A service to calculate body measurements from MediaPipe landmarks.
  - **`ProMeasurementService.swift`**: A service to calculate body measurements from a 3D model.

## How to Build

This project uses Swift Package Manager for dependencies.

1.  Make sure you have Xcode installed.
2.  Open the project in Xcode.
3.  Xcode should automatically resolve the package dependencies.
4.  Build and run the app on a compatible iOS device.

## Current Status

This is a prototype with placeholder logic for the core measurement functionalities.

- The MediaPipe integration is mocked.
- The Object Capture and 3D model analysis are placeholders.
- The UI is functional for navigating between the different modes.
