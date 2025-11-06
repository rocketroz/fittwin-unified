import AVFoundation
import UIKit
import Combine

/// Manages camera session with LiDAR depth data capture
@MainActor
class LiDARCameraManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var capturedImage: UIImage?
    @Published var capturedDepthData: AVDepthData?
    @Published var isSessionRunning = false
    @Published var error: CameraError?
    @Published var countdown: Int = 0
    @Published var isCountingDown = false
    
    // MARK: - Private Properties
    private let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var depthDataOutput = AVCaptureDepthDataOutput()
    private var videoDevice: AVCaptureDevice?
    private var countdownTimer: Timer?
    
    // Completion handlers
    private var photoCaptureCompletion: ((UIImage?, AVDepthData?) -> Void)?
    
    // MARK: - Session Setup
    
    func setupSession() async throws {
        // Request camera permission
        let authorized = await checkCameraAuthorization()
        guard authorized else {
            throw CameraError.notAuthorized
        }
        
        // Configure session
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // Find LiDAR-capable device
        guard let device = findLiDARDevice() else {
            throw CameraError.lidarNotAvailable
        }
        
        videoDevice = device
        
        // Add video input
        let videoInput = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(videoInput) else {
            throw CameraError.cannotAddInput
        }
        session.addInput(videoInput)
        
        // Add photo output
        guard session.canAddOutput(photoOutput) else {
            throw CameraError.cannotAddOutput
        }
        session.addOutput(photoOutput)
        
        // Configure photo output for depth
        if photoOutput.isDepthDataDeliverySupported {
            photoOutput.isDepthDataDeliveryEnabled = true
        }
        
        // Add depth data output
        if session.canAddOutput(depthDataOutput) {
            session.addOutput(depthDataOutput)
            depthDataOutput.isFilteringEnabled = true
        }
        
        session.commitConfiguration()
    }
    
    func startSession() {
        guard !isSessionRunning else { return }
        
        Task {
            session.startRunning()
            isSessionRunning = session.isRunning
        }
    }
    
    func stopSession() {
        guard isSessionRunning else { return }
        
        Task {
            session.stopRunning()
            isSessionRunning = false
        }
    }
    
    // MARK: - Photo Capture
    
    /// Capture photo with countdown timer
    func capturePhotoWithCountdown(
        seconds: Int = 10,
        completion: @escaping (UIImage?, AVDepthData?) -> Void
    ) {
        photoCaptureCompletion = completion
        startCountdown(seconds: seconds)
    }
    
    /// Capture photo immediately
    func capturePhoto(completion: @escaping (UIImage?, AVDepthData?) -> Void) {
        photoCaptureCompletion = completion
        performCapture()
    }
    
    private func startCountdown(seconds: Int) {
        countdown = seconds
        isCountingDown = true
        
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            Task { @MainActor in
                self.countdown -= 1
                
                if self.countdown <= 0 {
                    timer.invalidate()
                    self.isCountingDown = false
                    self.performCapture()
                }
            }
        }
    }
    
    private func performCapture() {
        let settings = AVCapturePhotoSettings()
        
        // Enable depth data capture if available
        if photoOutput.isDepthDataDeliverySupported {
            settings.isDepthDataDeliveryEnabled = true
        }
        
        // Set high quality
        settings.photoQualityPrioritization = .quality
        
        // Capture photo
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - Helper Methods
    
    private func checkCameraAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
    
    private func findLiDARDevice() -> AVCaptureDevice? {
        // Try to find device with LiDAR scanner (iPhone 12 Pro and later)
        if let device = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) {
            return device
        }
        
        // Fallback to dual camera with depth
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            return device
        }
        
        // Fallback to wide angle camera
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }
    
    // MARK: - Preview Layer
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension LiDARCameraManager: AVCapturePhotoCaptureDelegate {
    
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task { @MainActor in
            if let error = error {
                self.error = .captureError(error.localizedDescription)
                photoCaptureCompletion?(nil, nil)
                return
            }
            
            // Extract image
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                self.error = .invalidImageData
                photoCaptureCompletion?(nil, nil)
                return
            }
            
            // Extract depth data
            let depthData = photo.depthData
            
            // Store captured data
            self.capturedImage = image
            self.capturedDepthData = depthData
            
            // Call completion handler
            photoCaptureCompletion?(image, depthData)
            photoCaptureCompletion = nil
        }
    }
}

// MARK: - Camera Error

enum CameraError: LocalizedError {
    case notAuthorized
    case lidarNotAvailable
    case cannotAddInput
    case cannotAddOutput
    case captureError(String)
    case invalidImageData
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Camera access not authorized"
        case .lidarNotAvailable:
            return "LiDAR sensor not available on this device"
        case .cannotAddInput:
            return "Cannot add camera input"
        case .cannotAddOutput:
            return "Cannot add photo output"
        case .captureError(let message):
            return "Capture error: \(message)"
        case .invalidImageData:
            return "Invalid image data"
        }
    }
}
