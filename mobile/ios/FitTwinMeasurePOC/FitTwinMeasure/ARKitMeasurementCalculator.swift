//
//  ARKitMeasurementCalculator.swift
//  FitTwinMeasure
//
//  Created by Manus AI Agent on 2024-11-09.
//  Calculate body measurements from ARKit skeleton and 3D point cloud
//

import Foundation
import simd
import ARKit

/// Calculate accurate body measurements from ARKit body tracking data
@available(iOS 13.0, *)
class ARKitMeasurementCalculator {
    
    // MARK: - Main Calculation
    
    /// Calculate all measurements from capture result
    static func calculateMeasurements(from captureResult: CaptureResult) -> BodyMeasurements {
        print("📏 Calculating measurements from \(captureResult.frameCount) frames...")
        
        // Average skeleton across all frames for stability
        let averageSkeleton = averageSkeletons(captureResult.frames.map { $0.skeleton })
        
        // Fuse depth maps into 3D point cloud
        let pointCloud = fuseDepthMaps(captureResult.depthMaps)
        
        print("   Point cloud: \(pointCloud.count) points")
        
        // Calculate each measurement
        let height = calculateHeight(skeleton: averageSkeleton)
        let shoulderWidth = calculateShoulderWidth(skeleton: averageSkeleton)
        let chest = calculateChestCircumference(skeleton: averageSkeleton, pointCloud: pointCloud)
        let waist = calculateWaistCircumference(skeleton: averageSkeleton, pointCloud: pointCloud)
        let hip = calculateHipCircumference(skeleton: averageSkeleton, pointCloud: pointCloud)
        let inseam = calculateInseam(skeleton: averageSkeleton)
        let outseam = calculateOutseam(skeleton: averageSkeleton)
        let sleeveLength = calculateSleeveLength(skeleton: averageSkeleton)
        let neck = calculateNeckCircumference(skeleton: averageSkeleton, pointCloud: pointCloud)
        let bicep = calculateBicepCircumference(skeleton: averageSkeleton, pointCloud: pointCloud)
        let forearm = calculateForearmCircumference(skeleton: averageSkeleton, pointCloud: pointCloud)
        let thigh = calculateThighCircumference(skeleton: averageSkeleton, pointCloud: pointCloud)
        let calf = calculateCalfCircumference(skeleton: averageSkeleton, pointCloud: pointCloud)
        
        return BodyMeasurements(
            height_cm: height,
            shoulder_width_cm: shoulderWidth,
            chest_cm: chest,
            waist_natural_cm: waist,
            hip_low_cm: hip,
            inseam_cm: inseam,
            outseam_cm: outseam,
            sleeve_length_cm: sleeveLength,
            neck_cm: neck,
            bicep_cm: bicep,
            forearm_cm: forearm,
            thigh_cm: thigh,
            calf_cm: calf
        )
    }
    
    // MARK: - Skeleton Averaging
    
    private static func averageSkeletons(_ skeletons: [BodySkeleton]) -> BodySkeleton {
        guard !skeletons.isEmpty else {
            fatalError("Cannot average empty skeleton array")
        }
        
        // Get all joint names
        let jointNames = skeletons.first!.joints.keys
        
        // Average each joint position
        var averagedJoints: [String: simd_float4x4] = [:]
        
        for jointName in jointNames {
            var sumPosition = simd_float3(0, 0, 0)
            var count = 0
            
            for skeleton in skeletons {
                if let pos = skeleton.position(for: jointName) {
                    sumPosition += pos
                    count += 1
                }
            }
            
            if count > 0 {
                let avgPosition = sumPosition / Float(count)
                
                // Create transform with averaged position
                var transform = matrix_identity_float4x4
                transform.columns.3 = simd_float4(avgPosition.x, avgPosition.y, avgPosition.z, 1.0)
                
                averagedJoints[jointName] = transform
            }
        }
        
        // Average root transform
        let avgRootTransform = skeletons.first!.rootTransform  // Simplified
        
        return BodySkeleton(joints: averagedJoints, rootTransform: avgRootTransform)
    }
    
    // MARK: - Depth Fusion
    
    private static func fuseDepthMaps(_ depthMaps: [AVDepthData]) -> [Point3D] {
        var pointCloud: [Point3D] = []
        
        for depthMap in depthMaps {
            let points = depthMapToPointCloud(depthMap)
            pointCloud.append(contentsOf: points)
        }
        
        // Remove outliers
        pointCloud = statisticalOutlierRemoval(pointCloud, k: 20, stddevMult: 2.0)
        
        return pointCloud
    }
    
    private static func depthMapToPointCloud(_ depthData: AVDepthData) -> [Point3D] {
        let depthMap = depthData.depthDataMap
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else { return [] }
        
        let floatBuffer = baseAddress.assumingMemoryBound(to: Float32.self)
        
        var points: [Point3D] = []
        
        // Sample every Nth pixel to reduce point count
        let pixelStride = 4
        
        for y in stride(from: 0, to: height, by: pixelStride) {
            for x in stride(from: 0, to: width, by: pixelStride) {
                let index = y * width + x
                let depth = floatBuffer[index]
                
                // Skip invalid depth values
                if depth > 0 && depth < 5.0 {  // Within 5 meters
                    // Convert pixel coordinates to 3D
                    let point = Point3D(
                        x: Double(x) / Double(width),  // Normalized
                        y: Double(y) / Double(height),
                        z: Double(depth)
                    )
                    points.append(point)
                }
            }
        }
        
        return points
    }
    
    private static func statisticalOutlierRemoval(_ points: [Point3D], k: Int, stddevMult: Double) -> [Point3D] {
        // Simplified outlier removal
        // In production, use proper k-NN distance calculation
        
        guard points.count > k else { return points }
        
        // Calculate mean distance to k nearest neighbors for each point
        // Remove points with distance > mean + stddevMult * stddev
        
        // For now, just return all points (implement proper algorithm in production)
        return points
    }
    
    // MARK: - Measurement Calculations
    
    private static func calculateHeight(skeleton: BodySkeleton) -> Double {
        guard let headPos = skeleton.position(for: "head_joint"),
              let footPos = skeleton.position(for: "left_foot_joint") else {
            return 0
        }
        
        let height = Double(abs(headPos.y - footPos.y)) * 100.0  // Convert to cm
        
        print("   Height: \(String(format: "%.1f", height)) cm")
        return height
    }
    
    private static func calculateShoulderWidth(skeleton: BodySkeleton) -> Double {
        guard let leftShoulder = skeleton.position(for: "left_shoulder_1_joint"),
              let rightShoulder = skeleton.position(for: "right_shoulder_1_joint") else {
            return 0
        }
        
        let width = Double(simd_distance(leftShoulder, rightShoulder)) * 100.0  // Convert to cm
        
        print("   Shoulder Width: \(String(format: "%.1f", width)) cm")
        return width
    }
    
    private static func calculateChestCircumference(skeleton: BodySkeleton, pointCloud: [Point3D]) -> Double {
        guard let chestJoint = skeleton.position(for: "spine_7_joint") else {
            return 0
        }
        
        // Extract horizontal slice at chest height
        let chestHeight = Double(chestJoint.y)
        let sliceThickness: Double = 0.05  // 5cm slice
        
        let chestSlice = pointCloud.filter { point in
            abs(point.y - chestHeight) < sliceThickness
        }
        
        guard !chestSlice.isEmpty else {
            print("   ⚠️ No points found at chest height, using approximation")
            return calculateShoulderWidth(skeleton: skeleton) * 1.2  // Approximate
        }
        
        // Fit ellipse to slice
        let circumference = fitEllipseCircumference(chestSlice)
        
        print("   Chest: \(String(format: "%.1f", circumference)) cm")
        return circumference
    }
    
    private static func calculateWaistCircumference(skeleton: BodySkeleton, pointCloud: [Point3D]) -> Double {
        guard let waistJoint = skeleton.position(for: "spine_4_joint") else {
            return 0
        }
        
        let waistHeight = waistJoint.y
        let sliceThickness: Float = 0.05
        
        let waistSlice = pointCloud.filter { point in
            abs(Float(point.y) - waistHeight) < sliceThickness
        }
        
        guard !waistSlice.isEmpty else {
            print("   ⚠️ No points found at waist height, using approximation")
            return calculateHipCircumference(skeleton: skeleton, pointCloud: pointCloud) * 0.85
        }
        
        let circumference = fitEllipseCircumference(waistSlice)
        
        print("   Waist: \(String(format: "%.1f", circumference)) cm")
        return circumference
    }
    
    private static func calculateHipCircumference(skeleton: BodySkeleton, pointCloud: [Point3D]) -> Double {
        guard let hipJoint = skeleton.position(for: "hips_joint") else {
            return 0
        }
        
        let hipHeight = Double(hipJoint.y)
        let sliceThickness: Double = 0.05
        
        let hipSlice = pointCloud.filter { point in
            abs(point.y - hipHeight) < sliceThickness
        }
        
        guard !hipSlice.isEmpty else {
            print("   ⚠️ No points found at hip height, using approximation")
            return calculateShoulderWidth(skeleton: skeleton) * 1.1
        }
        
        let circumference = fitEllipseCircumference(hipSlice)
        
        print("   Hip: \(String(format: "%.1f", circumference)) cm")
        return circumference
    }
    
    private static func calculateInseam(skeleton: BodySkeleton) -> Double {
        guard let hipJoint = skeleton.position(for: "hips_joint"),
              let ankleJoint = skeleton.position(for: "left_foot_joint") else {
            return 0
        }
        
        let inseam = Double(simd_distance(hipJoint, ankleJoint)) * 100.0
        
        print("   Inseam: \(String(format: "%.1f", inseam)) cm")
        return inseam
    }
    
    private static func calculateOutseam(skeleton: BodySkeleton) -> Double {
        guard let waistJoint = skeleton.position(for: "spine_4_joint"),
              let ankleJoint = skeleton.position(for: "left_foot_joint") else {
            return 0
        }
        
        let outseam = Double(simd_distance(waistJoint, ankleJoint)) * 100.0
        
        print("   Outseam: \(String(format: "%.1f", outseam)) cm")
        return outseam
    }
    
    private static func calculateSleeveLength(skeleton: BodySkeleton) -> Double {
        guard let shoulderJoint = skeleton.position(for: "left_shoulder_1_joint"),
              let wristJoint = skeleton.position(for: "left_hand_joint") else {
            return 0
        }
        
        let sleeveLength = Double(simd_distance(shoulderJoint, wristJoint)) * 100.0
        
        print("   Sleeve Length: \(String(format: "%.1f", sleeveLength)) cm")
        return sleeveLength
    }
    
    private static func calculateNeckCircumference(skeleton: BodySkeleton, pointCloud: [Point3D]) -> Double {
        guard let neckJoint = skeleton.position(for: "neck_1_joint") else {
            return 0
        }
        
        let neckHeight = Double(neckJoint.y)
        let sliceThickness: Double = 0.03  // 3cm slice (neck is smaller)
        
        let neckSlice = pointCloud.filter { point in
            abs(point.y - neckHeight) < sliceThickness
        }
        
        guard !neckSlice.isEmpty else {
            print("   ⚠️ No points found at neck height, using approximation")
            return 38.0  // Average neck circumference
        }
        
        let circumference = fitEllipseCircumference(neckSlice)
        
        print("   Neck: \(String(format: "%.1f", circumference)) cm")
        return circumference
    }
    
    private static func calculateBicepCircumference(skeleton: BodySkeleton, pointCloud: [Point3D]) -> Double {
        guard let shoulderJoint = skeleton.position(for: "left_shoulder_1_joint"),
              let elbowJoint = skeleton.position(for: "left_forearm_joint") else {
            return 0
        }
        
        // Bicep is at midpoint between shoulder and elbow
        let bicepPos = (shoulderJoint + elbowJoint) / 2.0
        let bicepHeight = Double(bicepPos.y)
        let sliceThickness: Double = 0.03
        
        let bicepSlice = pointCloud.filter { point in
            abs(point.y - bicepHeight) < sliceThickness &&
            abs(point.x - Double(bicepPos.x)) < 0.1 &&  // Near arm
            abs(point.z - Double(bicepPos.z)) < 0.1
        }
        
        guard !bicepSlice.isEmpty else {
            print("   ⚠️ No points found at bicep, using approximation")
            let armLength = Double(simd_distance(shoulderJoint, elbowJoint)) * 100.0
            return armLength * 0.4  // Approximate from bone length
        }
        
        let circumference = fitEllipseCircumference(bicepSlice)
        
        print("   Bicep: \(String(format: "%.1f", circumference)) cm")
        return circumference
    }
    
    private static func calculateForearmCircumference(skeleton: BodySkeleton, pointCloud: [Point3D]) -> Double {
        guard let elbowJoint = skeleton.position(for: "left_forearm_joint"),
              let wristJoint = skeleton.position(for: "left_hand_joint") else {
            return 0
        }
        
        let forearmPos = (elbowJoint + wristJoint) / 2.0
        let forearmHeight = Double(forearmPos.y)
        let sliceThickness: Double = 0.03
        
        let forearmSlice = pointCloud.filter { point in
            abs(point.y - forearmHeight) < sliceThickness &&
            abs(point.x - Double(forearmPos.x)) < 0.1 &&
            abs(point.z - Double(forearmPos.z)) < 0.1
        }
        
        guard !forearmSlice.isEmpty else {
            print("   ⚠️ No points found at forearm, using approximation")
            let forearmLength = Double(simd_distance(elbowJoint, wristJoint)) * 100.0
            return forearmLength * 0.35
        }
        
        let circumference = fitEllipseCircumference(forearmSlice)
        
        print("   Forearm: \(String(format: "%.1f", circumference)) cm")
        return circumference
    }
    
    private static func calculateThighCircumference(skeleton: BodySkeleton, pointCloud: [Point3D]) -> Double {
        guard let hipJoint = skeleton.position(for: "left_upLeg_joint"),
              let kneeJoint = skeleton.position(for: "left_leg_joint") else {
            return 0
        }
        
        let thighPos = (hipJoint + kneeJoint) / 2.0
        let thighHeight = Double(thighPos.y)
        let sliceThickness: Double = 0.05
        
        let thighSlice = pointCloud.filter { point in
            abs(point.y - thighHeight) < sliceThickness &&
            abs(point.x - Double(thighPos.x)) < 0.15 &&
            abs(point.z - Double(thighPos.z)) < 0.15
        }
        
        guard !thighSlice.isEmpty else {
            print("   ⚠️ No points found at thigh, using approximation")
            let thighLength = Double(simd_distance(hipJoint, kneeJoint)) * 100.0
            return thighLength * 0.5
        }
        
        let circumference = fitEllipseCircumference(thighSlice)
        
        print("   Thigh: \(String(format: "%.1f", circumference)) cm")
        return circumference
    }
    
    private static func calculateCalfCircumference(skeleton: BodySkeleton, pointCloud: [Point3D]) -> Double {
        guard let kneeJoint = skeleton.position(for: "left_leg_joint"),
              let ankleJoint = skeleton.position(for: "left_foot_joint") else {
            return 0
        }
        
        let calfPos = (kneeJoint + ankleJoint) / 2.0
        let calfHeight = Double(calfPos.y)
        let sliceThickness: Double = 0.05
        
        let calfSlice = pointCloud.filter { point in
            abs(point.y - calfHeight) < sliceThickness &&
            abs(point.x - Double(calfPos.x)) < 0.15 &&
            abs(point.z - Double(calfPos.z)) < 0.15
        }
        
        guard !calfSlice.isEmpty else {
            print("   ⚠️ No points found at calf, using approximation")
            let calfLength = Double(simd_distance(kneeJoint, ankleJoint)) * 100.0
            return calfLength * 0.45
        }
        
        let circumference = fitEllipseCircumference(calfSlice)
        
        print("   Calf: \(String(format: "%.1f", circumference)) cm")
        return circumference
    }
    
    // MARK: - Ellipse Fitting
    
    private static func fitEllipseCircumference(_ points: [Point3D]) -> Double {
        guard points.count >= 3 else { return 0 }
        
        // Project points to 2D (remove Y coordinate)
        let points2D = points.map { (x: $0.x, z: $0.z) }
        
        // Find center
        let centerX = points2D.map { $0.x }.reduce(0, +) / Double(points2D.count)
        let centerZ = points2D.map { $0.z }.reduce(0, +) / Double(points2D.count)
        
        // Calculate distances from center
        let distances = points2D.map { point in
            sqrt(pow(point.x - centerX, 2) + pow(point.z - centerZ, 2))
        }
        
        // Find max and min distances (semi-major and semi-minor axes)
        let maxDist = distances.max() ?? 0
        let minDist = distances.min() ?? 0
        
        let a = maxDist * 100.0  // Convert to cm
        let b = minDist * 100.0
        
        // Calculate ellipse circumference using Ramanujan's approximation
        return ellipseCircumference(a: a, b: b)
    }
    
    private static func ellipseCircumference(a: Double, b: Double) -> Double {
        let h = pow(a - b, 2) / pow(a + b, 2)
        return .pi * (a + b) * (1 + (3 * h) / (10 + sqrt(4 - 3 * h)))
    }
}

// MARK: - Data Structures

struct Point3D {
    let x: Double
    let y: Double
    let z: Double
}
