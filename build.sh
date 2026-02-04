#!/bin/bash

# TyAu-TubeCity Build Script
# Builds the plugin in Debug configuration and registers it with the system

set -e  # Exit on error

echo "🎸 Building TyAu-TubeCity plugin..."

# Build in Debug configuration
xcodebuild -project TubeCity.xcodeproj \
    -scheme TubeCity \
    -configuration Debug \
    build \
    -allowProvisioningUpdates

echo "✅ Build succeeded!"

# Register the Audio Unit extension
echo "📝 Registering Audio Unit extension..."
open /Users/taylorpage/Library/Developer/Xcode/DerivedData/TubeCity-*/Build/Products/Debug/TubeCity.app

echo "🎸 TubeCity is ready! Load it in Logic Pro."
