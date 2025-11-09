#!/bin/bash

# FitTwin Measure - Setup Script
# Prepares the iOS POC project for development

set -e

echo "🚀 FitTwin Measure - Setup"
echo "=========================="
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install Xcode from the App Store."
    exit 1
fi

echo "✅ Xcode found: $(xcodebuild -version | head -n 1)"
echo ""

# Check Xcode version
XCODE_VERSION=$(xcodebuild -version | head -n 1 | awk '{print $2}' | cut -d. -f1)
if [ "$XCODE_VERSION" -lt 15 ]; then
    echo "⚠️  Warning: Xcode 15.0+ recommended. You have Xcode $XCODE_VERSION."
fi

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This project requires macOS to build iOS apps."
    exit 1
fi

echo "✅ Running on macOS"
echo ""

# Project structure check
echo "📂 Checking project structure..."

if [ ! -f "FitTwinMeasure.xcodeproj/project.pbxproj" ]; then
    echo "❌ Xcode project file not found!"
    exit 1
fi

if [ ! -f "FitTwinMeasure/FitTwinMeasureApp.swift" ]; then
    echo "❌ App source files not found!"
    exit 1
fi

echo "✅ Project structure valid"
echo ""

# List source files
echo "📄 Source files:"
ls -1 FitTwinMeasure/*.swift
echo ""

# Check for required files
REQUIRED_FILES=(
    "FitTwinMeasure/FitTwinMeasureApp.swift"
    "FitTwinMeasure/ContentView.swift"
    "FitTwinMeasure/MeasurementViewModel.swift"
    "FitTwinMeasure/MeasurementCalculator.swift"
    "FitTwinMeasure/LiDARCameraManager.swift"
    "FitTwinMeasure/Info.plist"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Missing required file: $file"
        exit 1
    fi
done

echo "✅ All required files present"
echo ""

# Instructions
echo "📱 Next Steps:"
echo ""
echo "1. Open the project in Xcode:"
echo "   open FitTwinMeasure.xcodeproj"
echo ""
echo "2. Connect your iPhone 12 Pro or newer (with LiDAR)"
echo ""
echo "3. Select your device in Xcode toolbar"
echo ""
echo "4. Configure signing:"
echo "   - Select FitTwinMeasure target"
echo "   - Go to Signing & Capabilities"
echo "   - Select your Team"
echo ""
echo "5. Click Run (⌘R)"
echo ""
echo "6. Grant camera permission when prompted"
echo ""
echo "📖 For detailed instructions, see README.md"
echo ""
echo "✅ Setup complete!"
