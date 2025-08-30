#!/bin/bash

# Build script for creating macOS DMG release
# This script should be run on macOS

set -e

APP_NAME="iFakeLocation"
APP_VERSION="1.7"
BUILD_DIR="build"
PUBLISH_DIR="publish/osx-x64"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${APP_VERSION}-macOS.dmg"

echo "Building iFakeLocation for macOS..."

# Clean previous builds
rm -rf ${BUILD_DIR}
rm -rf ${PUBLISH_DIR}

# Build the self-contained application
echo "Publishing .NET application..."
dotnet publish iFakeLocation/iFakeLocation.csproj \
    -c Release \
    -f net6.0 \
    -r osx-x64 \
    --self-contained true \
    -o ${PUBLISH_DIR}

# Create app bundle structure
echo "Creating app bundle..."
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy the published application
cp -r ${PUBLISH_DIR}/* "${APP_BUNDLE}/Contents/MacOS/"

# Create Info.plist
cat > "${APP_BUNDLE}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>iFakeLocation</string>
    <key>CFBundleIdentifier</key>
    <string>com.master131.ifakelocation</string>
    <key>CFBundleName</key>
    <string>iFakeLocation</string>
    <key>CFBundleDisplayName</key>
    <string>iFakeLocation</string>
    <key>CFBundleVersion</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024 master131. All rights reserved.</string>
    <key>CFBundleDocumentTypes</key>
    <array/>
    <key>LSEnvironment</key>
    <dict>
        <key>DYLD_LIBRARY_PATH</key>
        <string>\$DYLD_LIBRARY_PATH:\@executable_path</string>
    </dict>
</dict>
</plist>
EOF

# Make the executable file executable
chmod +x "${APP_BUNDLE}/Contents/MacOS/iFakeLocation"

echo "App bundle created at: ${APP_BUNDLE}"

# Create DMG if running on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Creating DMG..."
    
    # Use the enhanced DMG creation script
    ./create-dmg.sh
else
    echo "DMG creation skipped (not running on macOS)"
    echo "App bundle is ready for manual DMG creation"
    echo "To create DMG on macOS, run: ./create-dmg.sh"
fi

echo "Build complete!"