# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

```bash
# macOS (primary dev target — no simulator needed)
xcodebuild -project pj01.xcodeproj -scheme pj01 -destination 'platform=macOS' build

# iOS simulator (requires platform SDK installed)
xcodebuild -project pj01.xcodeproj -scheme pj01 -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Xcode must be at `/Applications/Xcode.app`. If `xcode-select -p` points to CommandLineTools, switch first:
```bash
sudo xcode-select --switch /Applications/Xcode.app
```

## Architecture

**Platform**: SwiftUI multiplatform (iOS 17+ / macOS 14+), SwiftData for persistence. Single target. Xcode 26+ with `PBXFileSystemSynchronizedRootGroup` — all `.swift` files under `pj01/` are auto-discovered, no manual pbxproj registration needed.

### Data Models (SwiftData)

- **Travel** → has many **TravelRecord** (cascade delete). Stores trip metadata: title, dates, summary, optional cover image path.
- **TravelRecord** → has many **PhotoItem** (cascade delete). Represents a "decisive moment" (Bresson-style). Stores title, description, timestamp, location, sort order.
- **PhotoItem** → the core model. Stores file paths (NOT blobs), EXIF metadata, GPS, and poster configuration (text, font, color, frame style). Has `isPoster: Bool` flag.

Relationships cascade downward: delete a Travel → all its Records and Photos are deleted. File cleanup deletes both original + thumbnail from disk.

### File Storage

Images are stored as **files** in `Documents/Originals/` and `Documents/Thumbnails/` — not as Data blobs in SwiftData. `PhotoItem.originalImagePath` holds a relative path. `FileStorageManager` resolves paths, generates thumbnails (CGImageSource), and handles cross-platform image loading (`NSImage` on macOS, `UIImage` on iOS).

### View Layer

**Two-tab root**: `ContentView` → TabView with "旅行" (TravelListView) and "回忆" (RandomReviewView).

Navigation: TravelListView (card grid) → TravelDetailView (record cards) → RecordDetailView (dual-mode: grid/poster).

`RecordDetailView` has two display modes switched via icon buttons:
- **常规 (grid)**: LazyVGrid showing only thumbnails (never originals). Thumbnails generated on-demand via `.task` if missing.
- **海报 (poster)**: Full-width `PosterCanvasView` showing only photos with `isPoster == true`, always loading original-resolution images.

### Cross-Platform

- `#if os(iOS)` / `#if os(macOS)` for platform-specific code
- `CameraPickerView` — iOS-only (UIImagePickerController wrapper via UIViewControllerRepresentable)
- `ShareSheetView` — iOS-only (UIActivityViewController wrapper)
- `ShareService.showSharePicker()` — macOS-only (NSSharingServicePicker)
- `AppCommands` — macOS-only menu bar commands

### Key Services

- `FileStorageManager.shared` — file I/O, image loading (cross-platform NSImage/UIImage → SwiftUI Image)
- `ImageProcessingService.shared` — EXIF extraction (CGImageSource), thumbnail generation (CGImageDestination)
- `LocationService.shared` — reverse geocoding (CLGeocoder)
- `PhotoLibraryService.shared` — PHPhotoLibrary authorization, PhotosPickerItem loading
- `ShareService.shared` — temp file export + platform-specific share sheet
