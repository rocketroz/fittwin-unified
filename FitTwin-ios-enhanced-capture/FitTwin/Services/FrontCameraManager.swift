import AVFoundation
import UIKit
import Combine

/// Manages front-facing camera with real-time frame processing for MediaPipe
@MainActor
class FrontCameraManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var isSessionRunning = false
    @Published var error: CameraError?
    @Published var currentFrame: UIImage?
    
    // MARK: - Frame Stream
    nonisolated private let frameSubject = PassthroughSubject<CMSampleBuffer, Never>()
    var framePublisher: AnyPublisher<CMSampleBuffer, Never> {
        frameSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    // Make the session internal so other views can create preview layers from it
    nonisolated let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.fittwin.camera.session")
    private let videoQueue = DispatchQueue(label: "com.fittwin.camera.video")
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    // MARK: - Configuration
    private let targetFrameRate: Int32 = 30
    private let videoOrientation: AVCaptureVideoOrientation = .portrait
    
    // MARK: - Setup
    
    func setupSession() async throws {
        session.beginConfiguration()
        
        // Configure for high quality video
        if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
        }
        
        // Get front camera
        guard let frontCamera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ) else {
            throw CameraError.deviceNotFound
        }
        
        // Configure camera settings
        try frontCamera.lockForConfiguration()
        
        // Set frame rate
        if let format = findBestFormat(for: frontCamera) {
            frontCamera.activeFormat = format
            
            let frameDuration = CMTime(value: 1, timescale: targetFrameRate)
            frontCamera.activeVideoMinFrameDuration = frameDuration
            frontCamera.activeVideoMaxFrameDuration = frameDuration
        }
        
        // Enable auto focus and exposure
        if frontCamera.isFocusModeSupported(.continuousAutoFocus) {
            frontCamera.focusMode = .continuousAutoFocus
        }
        if frontCamera.isExposureModeSupported(.continuousAutoExposure) {
            frontCamera.exposureMode = .continuousAutoExposure
        }
        
        frontCamera.unlockForConfiguration()
        
        // Create and add input
        let videoDeviceInput = try AVCaptureDeviceInput(device: frontCamera)
        guard session.canAddInput(videoDeviceInput) else {
            throw CameraError.cannotAddInput
        }
        session.addInput(videoDeviceInput)
        self.videoDeviceInput = videoDeviceInput
        
        // Configure video output
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        
        guard session.canAddOutput(videoOutput) else {
            throw CameraError.cannotAddOutput
        }
        session.addOutput(videoOutput)
        
        // Set video orientation
        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = videoOrientation
            }
            // Mirror for front camera
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }
        
        session.commitConfiguration()
        
        // Create preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        if let connection = previewLayer.connection {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = videoOrientation
            }
        }
        self.previewLayer = previewLayer
    }
    
    // MARK: - Best Format Selection
    
    private func findBestFormat(for device: AVCaptureDevice) -> AVCaptureDevice.Format? {
        let formats = device.formats
        
        // Find format with 1920x1080 or closest
        let targetWidth: Int32 = 1920
        let targetHeight: Int32 = 1080
        
        var bestFormat: AVCaptureDevice.Format?
        var smallestDiff: Int32 = Int32.max
        
        for format in formats {
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let diff = abs(dimensions.width - targetWidth) + abs(dimensions.height - targetHeight)
            
            // Check if format supports target frame rate
            let ranges = format.videoSupportedFrameRateRanges
            let supportsFrameRate = ranges.contains { range in
                range.minFrameRate <= Double(targetFrameRate) &&
                range.maxFrameRate >= Double(targetFrameRate)
            }
            
            if supportsFrameRate && diff < smallestDiff {
                smallestDiff = diff
                bestFormat = format
            }
        }
        
        return bestFormat
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
    
    func captureCurrentFrame() async -> UIImage? {
        return currentFrame
    }
    
    // MARK: - Permissions
    
    /// Checks and requests camera permission, calling completion with the result on the main thread.
    func checkPermissions(_ completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            DispatchQueue.main.async { completion(true) }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        case .denied, .restricted:
            DispatchQueue.main.async { completion(false) }
        @unknown default:
            DispatchQueue.main.async { completion(false) }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension FrontCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Send frame to subscribers (MediaPipe)
        frameSubject.send(sampleBuffer)
        
        // Convert to UIImage for preview/capture
        if let image = imageFromSampleBuffer(sampleBuffer) {
            Task { @MainActor in
                self.currentFrame = image
            }
        }
    }
    
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Frame dropped - could log for debugging
        print("Frame dropped")
    }
    
    // MARK: - Image Conversion
    
    private nonisolated func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly) }
        
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        
        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }
        
        guard let cgImage = context.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
    }
}

// MARK: - Camera Error

enum CameraError: LocalizedError {
    case deviceNotFound
    case cannotAddInput
    case cannotAddOutput
    case invalidImageData
    case permissionDenied
    case sessionInterrupted
    
    var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "Front camera not found on this device"
        case .cannotAddInput:
            return "Cannot add camera input to session"
        case .cannotAddOutput:
            return "Cannot add video output to session"
        case .invalidImageData:
            return "Invalid image data from camera"
        case .permissionDenied:
            return "Camera permission denied. Please enable in Settings."
        case .sessionInterrupted:
            return "Camera session was interrupted"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Go to Settings > FitTwin > Camera and enable access"
        case .deviceNotFound:
            return "This device may not have a front-facing camera"
        default:
            return "Try restarting the app"
        }
    }
}
