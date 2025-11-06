import AVFoundation
import UIKit

/// Manages camera session with LiDAR depth data capture
@MainActor
class LiDARCameraManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var capturedImage: UIImage?
    @Published var capturedDepthData: AVDepthData?
    @Published var isSessionRunning = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.fittwin.camera.session")
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    // MARK: - Setup
    
    func setupSession() async throws {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // Get LiDAR camera (back dual camera on iPhone 12 Pro+)
        guard let videoDevice = AVCaptureDevice.default(
            .builtInLiDARDepthCamera,
            for: .video,
            position: .back
        ) else {
            // Fallback to regular back camera if LiDAR not available
            guard let fallbackDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .back
            ) else {
                throw CameraError.deviceNotFound
            }
            try await setupDevice(fallbackDevice)
            return
        }
        
        try await setupDevice(videoDevice)
    }
    
    private func setupDevice(_ device: AVCaptureDevice) async throws {
        // Create input
        let videoDeviceInput = try AVCaptureDeviceInput(device: device)
        
        guard session.canAddInput(videoDeviceInput) else {
            throw CameraError.cannotAddInput
        }
        session.addInput(videoDeviceInput)
        self.videoDeviceInput = videoDeviceInput
        
        // Add photo output
        guard session.canAddOutput(photoOutput) else {
            throw CameraError.cannotAddOutput
        }
        session.addOutput(photoOutput)
        
        // Enable depth data delivery if available
        if photoOutput.isDepthDataDeliverySupported {
            photoOutput.isDepthDataDeliveryEnabled = true
        }
        
        session.commitConfiguration()
        
        // Create preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        self.previewLayer = previewLayer
    }
    
    // MARK: - Session Control
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
                Task { @MainActor in
                    self.isSessionRunning = true
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                Task { @MainActor in
                    self.isSessionRunning = false
                }
            }
        }
    }
    
    // MARK: - Photo Capture
    
    func capturePhoto() async throws -> (image: UIImage, depthData: AVDepthData?) {
        return try await withCheckedThrowingContinuation { continuation in
            let settings = AVCapturePhotoSettings()
            
            // Enable depth data capture if available
            if photoOutput.isDepthDataDeliverySupported {
                settings.isDepthDataDeliveryEnabled = true
            }
            
            // Set high quality
            settings.photoQualityPrioritization = .quality
            
            let delegate = PhotoCaptureDelegate { result in
                continuation.resume(with: result)
            }
            
            photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }
}

// MARK: - Photo Capture Delegate

private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    
    private let completion: (Result<(UIImage, AVDepthData?), Error>) -> Void
    
    init(completion: @escaping (Result<(UIImage, AVDepthData?), Error>) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completion(.failure(CameraError.invalidImageData))
            return
        }
        
        let depthData = photo.depthData
        completion(.success((image, depthData)))
    }
}

// MARK: - Errors

enum CameraError: LocalizedError {
    case deviceNotFound
    case cannotAddInput
    case cannotAddOutput
    case invalidImageData
    case captureFailure(Error)
    
    var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "Camera device not found"
        case .cannotAddInput:
            return "Cannot add camera input"
        case .cannotAddOutput:
            return "Cannot add photo output"
        case .invalidImageData:
            return "Invalid image data captured"
        case .captureFailure(let error):
            return "Capture failed: \(error.localizedDescription)"
        }
    }
}
