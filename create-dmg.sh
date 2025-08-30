#!/bin/bash

# Enhanced DMG creation script with styling
# This script should be run on macOS after the app bundle is created

set -e

APP_NAME="iFakeLocation"
APP_VERSION="1.7"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${APP_VERSION}-macOS.dmg"
DMG_DIR="${BUILD_DIR}/dmg"

if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "This script must be run on macOS to create DMG files"
    exit 1
fi

if [ ! -d "${APP_BUNDLE}" ]; then
    echo "App bundle not found at ${APP_BUNDLE}"
    echo "Please run build-macos.sh first"
    exit 1
fi

echo "Creating styled DMG for ${APP_NAME}..."

# Clean previous DMG builds
rm -rf "${DMG_DIR}"
rm -f "${BUILD_DIR}/${DMG_NAME}"

# Create temporary DMG directory
mkdir -p "${DMG_DIR}"

# Copy app bundle to DMG directory
cp -r "${APP_BUNDLE}" "${DMG_DIR}/"

# Create symbolic link to Applications folder
ln -s /Applications "${DMG_DIR}/Applications"

# Create a temporary DMG
TEMP_DMG="${BUILD_DIR}/temp-${DMG_NAME}"
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${DMG_DIR}" \
    -ov \
    -format UDRW \
    "${TEMP_DMG}"

# Mount the temporary DMG
MOUNT_DIR=$(hdiutil attach "${TEMP_DMG}" | grep Volumes | awk '{print $3}')

echo "Styling DMG..."

# Set DMG window properties
osascript << EOF
tell application "Finder"
    tell disk "${APP_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 600, 400}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set background picture of viewOptions to file ".background:background.png"
        set position of item "${APP_NAME}.app" of container window to {150, 200}
        set position of item "Applications" of container window to {350, 200}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Unmount the temporary DMG
hdiutil detach "${MOUNT_DIR}"

# Convert to compressed read-only DMG
hdiutil convert "${TEMP_DMG}" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "${BUILD_DIR}/${DMG_NAME}"

# Clean up
rm -f "${TEMP_DMG}"
rm -rf "${DMG_DIR}"

echo "Styled DMG created: ${BUILD_DIR}/${DMG_NAME}"

# Show file size
echo "DMG size: $(du -h "${BUILD_DIR}/${DMG_NAME}" | cut -f1)"