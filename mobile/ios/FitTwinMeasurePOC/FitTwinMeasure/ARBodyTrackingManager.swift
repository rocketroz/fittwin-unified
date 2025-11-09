//
//  ARBodyTrackingManager.swift
//  FitTwinMeasure
//
//  Created by Manus AI Agent on 2024-11-09.
//  ARKit Body Tracking implementation for accurate body measurements
//

import Foundation
import ARKit
import RealityKit
import Combine

/// Manages ARKit body tracking session for measurement capture
@available(iOS 13.0, *)
class ARBodyTrackingManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isSessionRunning = false
    @Published var isBodyDetected = false
    @Published var trackingQuality: ARFrame.WorldTrackingState.Reason? = nil
    @Published var captureProgress: Double = 0.0
    @Published var currentRotationAngle: Double = 0.0
    @Published var currentSkeleton: ARSkeleton3D?  // For arm position validation
    
    // MARK: - Public Properties
    
    let arSession = ARSession()  // Public for ARViewContainer
    
    // MARK: - Private Properties
    private var bodyAnchor: ARBodyAnchor?
    private var capturedFrames: [CapturedBodyFrame] = []
    private var depthMaps: [AVDepthData] = []
    private var startTime: Date?
    private let captureDuration: TimeInterval = 30.0  // 30 seconds for 360° rotation
    private let frameInterval: TimeInterval = 1.5  // Capture every 1.5 seconds
    private var lastCaptureTime: TimeInterval = 0
    
    // MARK: - Configuration
    
    private var configuration: ARBodyTrackingConfiguration {
        let config = ARBodyTrackingConfiguration()
        config.isAutoFocusEnabled = true
        config.environmentTexturing = .automatic
        
        // Enable depth data if available
        if ARBodyTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics.insert(.sceneDepth)
        }
        
        return config
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        arSession.delegate = self
    }
    
    // MARK: - Session Management
    
    /// Check if ARKit Body Tracking is supported on this device
    static func isSupported() -> Bool {
        return ARBodyTrackingConfiguration.isSupported
    }
    
    /// Start ARKit body tracking session
    func startSession() {
        guard ARBodyTrackingConfiguration.isSupported else {
            print("❌ ARKit Body Tracking not supported on this device")
            print("   Requires: iPhone 12 Pro or later with A14 Bionic chip")
            return
        }
        
        print("🚀 Starting ARKit Body Tracking session...")
        
        // Reset state
        capturedFrames = []
        depthMaps = []
        startTime = nil
        lastCaptureTime = 0
        captureProgress = 0.0
        currentRotationAngle = 0.0
        
        // Start session
        arSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        isSessionRunning = true
        
        print("✅ ARKit session started")
    }
    
    /// Stop ARKit session
    func stopSession() {
        print("⏹️ Stopping ARKit session...")
        arSession.pause()
        isSessionRunning = false
        print("✅ ARKit session stopped")
    }
    
    /// Start capture (begin recording frames)
    func startCapture() {
        print("📹 Starting 360° capture...")
        print("   Duration: \(Int(captureDuration)) seconds")
        print("   Frames: ~\(Int(captureDuration / frameInterval))")
        
        startTime = Date()
        capturedFrames = []
        depthMaps = []
        lastCaptureTime = 0
        captureProgress = 0.0
    }
    
    /// Stop capture and return captured data
    func stopCapture() -> CaptureResult? {
        print("⏹️ Stopping capture...")
        print("📊 Captured \(capturedFrames.count) frames")
        print("📊 Captured \(depthMaps.count) depth maps")
        
        guard !capturedFrames.isEmpty else {
            print("❌ No frames captured")
            return nil
        }
        
        let result = CaptureResult(
            frames: capturedFrames,
            depthMaps: depthMaps,
            duration: captureDuration
        )
        
        // Reset
        startTime = nil
        
        return result
    }
    
    // MARK: - Frame Capture
    
    private func shouldCaptureFrame(timestamp: TimeInterval) -> Bool {
        guard let startTime = startTime else { return false }
        
        let elapsed = timestamp - startTime.timeIntervalSinceReferenceDate
        
        // Check if capture duration exceeded
        if elapsed >= captureDuration {
            return false
        }
        
        // Check if enough time passed since last capture
        if elapsed - lastCaptureTime >= frameInterval {
            return true
        }
        
        return false
    }
    
    private func captureFrame(_ frame: ARFrame, bodyAnchor: ARBodyAnchor) {
        let timestamp = frame.timestamp
        
        guard shouldCaptureFrame(timestamp: timestamp) else { return }
        
        lastCaptureTime = timestamp - (startTime?.timeIntervalSinceReferenceDate ?? 0)
        
        // Extract skeleton
        let skeleton = extractSkeleton(from: bodyAnchor)
        
        // Extract depth if available
        var depthData: AVDepthData?
        if let sceneDepth = frame.sceneDepth {
            depthData = convertToAVDepthData(sceneDepth)
        }
        
        // Create captured frame
        let capturedFrame = CapturedBodyFrame(
            timestamp: timestamp,
            skeleton: skeleton,
            transform: bodyAnchor.transform,
            depthData: depthData,
            cameraTransform: frame.camera.transform
        )
        
        capturedFrames.append(capturedFrame)
        
        if let depthData = depthData {
            depthMaps.append(depthData)
        }
        
        // Update progress
        let elapsed = lastCaptureTime
        captureProgress = min(elapsed / captureDuration, 1.0)
        
        print("📸 Frame \(capturedFrames.count) captured at \(String(format: "%.1f", elapsed))s (progress: \(Int(captureProgress * 100))%)")
        
        // Auto-stop if duration reached
        if captureProgress >= 1.0 {
            print("✅ Capture complete!")
            // Notify completion (handled by view model)
        }
    }
    
    // MARK: - Skeleton Extraction
    
    private func extractSkeleton(from bodyAnchor: ARBodyAnchor) -> BodySkeleton {
        let skeleton = bodyAnchor.skeleton
        
        // Extract all joint transforms
        var joints: [String: simd_float4x4] = [:]
        
        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
            if let jointIndex = ARSkeletonDefinition.defaultBody3D.index(for: ARSkeleton.JointName(rawValue: jointName)) {
                let jointTransform = skeleton.jointModelTransforms[jointIndex]
                joints[jointName] = jointTransform
            }
        }
        
        return BodySkeleton(
            joints: joints,
            rootTransform: bodyAnchor.transform
        )
    }
    
    // MARK: - Depth Conversion
    
    private func convertToAVDepthData(_ sceneDepth: ARDepthData) -> AVDepthData? {
        // ARKit provides depth as CVPixelBuffer
        // Convert to AVDepthData format
        
        let depthMap = sceneDepth.depthMap
        let confidenceMap = sceneDepth.confidenceMap
        
        // Create depth data description
        var depthDataMap = depthMap
        
        // Note: This is a simplified conversion
        // In production, you'd want to properly create AVDepthData with calibration
        
        return try? AVDepthData(fromDictionaryRepresentation: [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_DepthFloat32,
            kCVPixelBufferWidthKey: CVPixelBufferGetWidth(depthMap),
            kCVPixelBufferHeightKey: CVPixelBufferGetHeight(depthMap)
        ])
    }
    
    // MARK: - Rotation Estimation
    
    private func estimateRotationAngle() -> Double {
        guard capturedFrames.count >= 2 else { return 0.0 }
        
        // Estimate rotation based on camera transform changes
        let firstTransform = capturedFrames.first!.cameraTransform
        let lastTransform = capturedFrames.last!.cameraTransform
        
        // Extract rotation around Y-axis (vertical)
        let firstForward = simd_make_float3(firstTransform.columns.2)
        let lastForward = simd_make_float3(lastTransform.columns.2)
        
        // Calculate angle between forward vectors
        let dot = simd_dot(firstForward, lastForward)
        let angle = acos(dot) * 180.0 / .pi
        
        return Double(angle)
    }
}

// MARK: - ARSessionDelegate

@available(iOS 13.0, *)
extension ARBodyTrackingManager: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Update tracking quality
        switch frame.camera.trackingState {
        case .normal:
            trackingQuality = nil
        case .limited(let reason):
            trackingQuality = reason
        case .notAvailable:
            trackingQuality = nil
        }
        
        // Update rotation angle estimate
        if startTime != nil {
            currentRotationAngle = estimateRotationAngle()
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let bodyAnchor = anchor as? ARBodyAnchor {
                print("✅ Body detected!")
                self.bodyAnchor = bodyAnchor
                DispatchQueue.main.async {
                    self.isBodyDetected = true
                }
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let bodyAnchor = anchor as? ARBodyAnchor {
                self.bodyAnchor = bodyAnchor
                
                // Publish skeleton for arm position validation
                DispatchQueue.main.async {
                    self.currentSkeleton = bodyAnchor.skeleton
                }
                
                // Capture frame if in capture mode
                if startTime != nil {
                    captureFrame(session.currentFrame!, bodyAnchor: bodyAnchor)
                }
            }
        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            if anchor is ARBodyAnchor {
                print("⚠️ Body lost!")
                self.bodyAnchor = nil
                DispatchQueue.main.async {
                    self.isBodyDetected = false
                }
            }
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("❌ ARSession error: \(error.localizedDescription)")
    }
}

// MARK: - Data Structures

struct BodySkeleton {
    let joints: [String: simd_float4x4]  // Joint name -> transform
    let rootTransform: simd_float4x4
    
    /// Get 3D position of a joint
    func position(for jointName: String) -> simd_float3? {
        guard let jointTransform = joints[jointName] else { return nil }
        
        // Apply root transform
        let worldTransform = simd_mul(rootTransform, jointTransform)
        
        // Extract position
        return simd_make_float3(worldTransform.columns.3)
    }
    
    /// Get all joint positions
    func allPositions() -> [String: simd_float3] {
        var positions: [String: simd_float3] = [:]
        
        for (jointName, _) in joints {
            if let pos = position(for: jointName) {
                positions[jointName] = pos
            }
        }
        
        return positions
    }
}

struct CapturedBodyFrame {
    let timestamp: TimeInterval
    let skeleton: BodySkeleton
    let transform: simd_float4x4
    let depthData: AVDepthData?
    let cameraTransform: simd_float4x4
}

struct CaptureResult {
    let frames: [CapturedBodyFrame]
    let depthMaps: [AVDepthData]
    let duration: TimeInterval
    
    var frameCount: Int { frames.count }
    var averageFrameRate: Double { Double(frameCount) / duration }
}

// MARK: - ARKit Joint Names (Reference)

extension ARBodyTrackingManager {
    
    /// Standard ARKit body joint names (90+ joints)
    static let standardJoints = [
        // Spine
        "root",
        "hips_joint",
        "spine_1_joint",
        "spine_2_joint",
        "spine_3_joint",
        "spine_4_joint",
        "spine_5_joint",
        "spine_6_joint",
        "spine_7_joint",
        "neck_1_joint",
        "neck_2_joint",
        "neck_3_joint",
        "neck_4_joint",
        "head_joint",
        
        // Left arm
        "left_shoulder_1_joint",
        "left_arm_joint",
        "left_forearm_joint",
        "left_hand_joint",
        
        // Right arm
        "right_shoulder_1_joint",
        "right_arm_joint",
        "right_forearm_joint",
        "right_hand_joint",
        
        // Left leg
        "left_upLeg_joint",
        "left_leg_joint",
        "left_foot_joint",
        "left_toes_joint",
        
        // Right leg
        "right_upLeg_joint",
        "right_leg_joint",
        "right_foot_joint",
        "right_toes_joint"
    ]
    
    /// Key joints for measurements
    static let measurementJoints = [
        "head_joint",           // Top of head
        "neck_1_joint",         // Neck base
        "left_shoulder_1_joint",  // Left shoulder
        "right_shoulder_1_joint", // Right shoulder
        "spine_7_joint",        // Chest level
        "spine_4_joint",        // Waist level
        "hips_joint",           // Hip level
        "left_arm_joint",       // Left bicep
        "right_arm_joint",      // Right bicep
        "left_forearm_joint",   // Left forearm
        "right_forearm_joint",  // Right forearm
        "left_upLeg_joint",     // Left thigh
        "right_upLeg_joint",    // Right thigh
        "left_leg_joint",       // Left calf
        "right_leg_joint",      // Right calf
        "left_foot_joint",      // Left ankle
        "right_foot_joint"      // Right ankle
    ]
}
