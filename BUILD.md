# Building iFakeLocation DMG for macOS

This directory contains scripts and workflows for building iFakeLocation releases, particularly the macOS DMG distribution format.

## Files

- **`build-macos.sh`** - Main build script that creates the macOS app bundle and initiates DMG creation
- **`create-dmg.sh`** - Enhanced DMG creation script with styling (macOS only)
- **`.github/workflows/release.yml`** - GitHub Actions workflow for automated releases

## Building Locally

### Prerequisites

- macOS (for DMG creation)
- .NET 6.0 SDK
- Xcode command line tools

### Steps

1. **Build the app bundle:**
   ```bash
   ./build-macos.sh
   ```
   This will:
   - Build the self-contained .NET application for macOS (osx-x64)
   - Create the proper macOS app bundle structure in `build/iFakeLocation.app`
   - Generate `Info.plist` with proper metadata
   - Create DMG if running on macOS

2. **Create styled DMG (macOS only):**
   ```bash
   ./create-dmg.sh
   ```
   This creates a styled DMG with:
   - Custom window size and positioning
   - App and Applications folder positioned for easy drag-and-drop
   - Compressed read-only format for distribution

## Automated Releases

The GitHub Actions workflow (`.github/workflows/release.yml`) automatically:

- **Triggers on:**
  - Git tags starting with `v*` (e.g., `v1.7`, `v2.0`)
  - Manual workflow dispatch

- **Creates:**
  - macOS DMG file (built on macOS runner)
  - Cross-platform archives (Windows, Linux, macOS) built on Ubuntu runner
  - GitHub release with all artifacts

### Triggering a Release

1. **Tag-based release:**
   ```bash
   git tag v1.7
   git push origin v1.7
   ```

2. **Manual release:**
   - Go to Actions tab on GitHub
   - Select "Build and Release DMG" workflow
   - Click "Run workflow"
   - Enter version tag

## Output Structure

```
build/
├── iFakeLocation.app/              # macOS app bundle
│   ├── Contents/
│   │   ├── Info.plist             # Bundle metadata
│   │   ├── MacOS/                 # Executable and dependencies
│   │   │   ├── iFakeLocation      # Main executable
│   │   │   ├── *.dll              # .NET libraries
│   │   │   ├── *.dylib            # macOS native libraries
│   │   │   └── Resources/         # Application resources
│   │   └── Resources/             # Bundle resources
└── iFakeLocation-1.7-macOS.dmg   # Distributable DMG
```

## DMG Installation

Users can install by:
1. Opening the DMG file
2. Dragging iFakeLocation.app to the Applications folder
3. Running the app from Applications or Launchpad

## Notes

- The app bundle includes all dependencies for self-contained deployment
- Native libraries for iOS device communication are included
- DMG creation requires macOS due to dependencies on `hdiutil` and `osascript`
- The build process targets .NET 6.0 for broad compatibility