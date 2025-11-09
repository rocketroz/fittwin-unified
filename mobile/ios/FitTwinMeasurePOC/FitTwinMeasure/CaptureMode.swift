//
//  CaptureMode.swift
//  FitTwinMeasure
//
//  Created by FitTwin Team on 11/9/25.
//

import Foundation

/// Capture mode for body measurement
enum CaptureMode: String, CaseIterable {
    case solo = "Solo Mode"
    case twoPerson = "Two Person Mode"
    
    var description: String {
        switch self {
        case .solo:
            return "Measure yourself using front camera"
        case .twoPerson:
            return "Get help from a friend for best accuracy"
        }
    }
    
    var features: [String] {
        switch self {
        case .solo:
            return [
                "Front camera (selfie mode)",
                "See yourself on screen",
                "Place phone on ground/wall",
                "Quick & easy (90 seconds)",
                "Accuracy: ±3-5 cm",
                "Works on all iPhones"
            ]
        case .twoPerson:
            return [
                "Back camera with LiDAR",
                "Helper holds phone",
                "Audio guidance",
                "Best accuracy (±1-2 cm)",
                "Takes 3 minutes",
                "Requires iPhone 12 Pro+"
            ]
        }
    }
    
    var icon: String {
        switch self {
        case .solo:
            return "📱"
        case .twoPerson:
            return "👥"
        }
    }
    
    var badge: String? {
        switch self {
        case .solo:
            return "RECOMMENDED"
        case .twoPerson:
            return "ADVANCED"
        }
    }
}

/// Phone placement mode for Solo Mode
enum PlacementMode: String, CaseIterable {
    case ground = "Ground Placement"
    case wall = "Wall/Shelf Placement"
    case upright = "Upright Placement"
    
    var description: String {
        switch self {
        case .ground:
            return "Phone flat on ground, stand 3-4 feet away"
        case .wall:
            return "Phone at 45° against wall, stand 4-5 feet away"
        case .upright:
            return "Phone standing vertical, stand 5-6 feet away"
        }
    }
    
    var targetPitch: Double {
        switch self {
        case .ground:
            return 0.0  // Flat
        case .wall:
            return 45.0  // 45 degrees
        case .upright:
            return 90.0  // Vertical
        }
    }
    
    var targetDistance: ClosedRange<Float> {
        switch self {
        case .ground:
            return 0.9...1.2  // 3-4 feet in meters
        case .wall:
            return 1.2...1.5  // 4-5 feet in meters
        case .upright:
            return 1.5...1.8  // 5-6 feet in meters
        }
    }
    
    var icon: String {
        switch self {
        case .ground:
            return "📐"
        case .wall:
            return "📚"
        case .upright:
            return "🎯"
        }
    }
    
    var badge: String? {
        switch self {
        case .ground:
            return "RECOMMENDED"
        case .wall, .upright:
            return nil
        }
    }
}
