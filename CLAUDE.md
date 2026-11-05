# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

CropImage is a SwiftUI Swift package (iOS 26+, Swift 6 language mode, swift-tools 6.0, no dependencies) that provides an interactive pan/zoom image cropper. It is a public library consumed by multiple apps: changes must stay general-purpose, and the public API surface matters. The public API is `CropImageView`, `CropArea`, `CropAreaViewModel` (only `init()`, `crop(outputSide:)` and `reset()`) and `CropShape`; everything else is internal. Add new options as defaulted `init` parameters so existing call sites keep compiling.

CropImage is cropping only: which part of the photo ends up in the crop, and the output image. Rotating or straightening would belong here; effects such as filters or background removal don't. An effect starts in the app that needs it and becomes its own library once a second app needs it.

The demo app lives on the `with-demo` branch, not `main`. A local `CropImageDemo/` folder on `main` holds only git-ignored Xcode user data.

## Development Workflow
Features and non-trivial fixes follow the OpenSpec + Superpowers loop in
`.claude/rules/development-workflow.md`, which loads automatically. The living specs are
`openspec/specs/crop-interaction` and `openspec/specs/crop-output`. Work branches from
`develop` and returns to it through PRs; `main` holds only released, tagged code.

## Commands

The package imports UIKit, so `swift build` / `swift test` on macOS fail. Build and test through `xcodebuild` against an iOS simulator:

```bash
# Build
xcodebuild build -scheme CropImage -destination 'generic/platform=iOS Simulator'

# Run all tests (Swift Testing)
xcodebuild test -scheme CropImage -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Run a single test: Swift Testing IDs need the trailing `()`; without it nothing runs and the result is still "TEST SUCCEEDED"
xcodebuild test -scheme CropImage -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  '-only-testing:CropImageTests/CropAreaViewModelTests/cropWithOutputSideIsThatManyPixelsSquare()'
```

There is no SwiftLint or swift-format config in the repo. Sources use 2-space indentation.

## Architecture

- **`CropArea`** (public) is the crop area apps build their own screens around: a `GeometryReader` with the image, its gestures, `CropMaskView` and, with `showsGrid`, `CropGridView`. The crop region is a square whose side is 75% of the area's smaller side, capped at 400 pt (`CropGeometry.cropSize`), centered in the area. Drag translation and pinch magnification live in `@GestureState` while a gesture lasts, and reset with the same `.cropSettle` spring that `settle` uses; the image is shown at the view model's settled framing combined with them. The area reports its size and image to the view model (`areaSizeChanged`, `imageChanged`, by object identity because `UIImage`'s `==` compares pixel data), and both again when the app swaps in another view model. It computes the mask's crop region from its current layout rather than reading the view model's copy, which updates only after layout. `CropMaskView` dims the area and punches the hole using a `.destinationOut` blend inside a `.compositingGroup()`.
- **`CropImageView`** (public) is the ready-made screen: a `NavigationStack` around a `CropArea` and its own `CropAreaViewModel`, with a `title`, a close button, and a Confirm button (disabled while `image` is `nil`) that calls `viewModel.crop(outputSide:)`, passes the result to `onCrop`, then dismisses.
- **`CropAreaViewModel`** (public, `@MainActor @Observable`) holds the settled framing (`scale`, `offset`), which is what `crop` renders, plus the image and area size its `CropArea` reports. One view model serves one area. `dragEnded`/`pinchEnded` fold a finished gesture in (pan adds, zoom multiplies) without animation, then `settle` corrects it with a spring: raise the zoom to the minimum that covers the crop region, then limit the pan. `settle` also runs when the area's size or the image's size changes. A cancelled gesture never reaches `onEnded`, so the `@GestureState` reset returns the image to the settled framing. `reset()` returns to zoom 1 and no pan. Only `init()`, `crop(outputSide:)` and `reset()` are public; tests reach the rest through `@testable import`, and `PublicAPITests` imports the module without it to catch a lost `public`.
- **`CropGeometry`** contains pure CoreGraphics math: the crop region's size, the `scaledToFill` rendered size, the minimum zoom, and pan clamping (a negative limit counts as 0, centering that axis). It and the view model's gesture math are unit tested without a view.
- **Rendering (`crop`)** rebuilds the same modifier chain the view uses on screen (`resizable → scaledToFill → scaleEffect → offset → frame(container)`), then renders only the centered crop region with `ImageRenderer` at scale 1. **Keep this chain in sync with `CropArea.body`**, or the output won't match what the user framed. With `outputSide`, the whole layout is scaled by `outputSide / cropSize.width`, so the frame is exactly `outputSide` points and pixel sizes come out exact. Don't use `renderer.scale` instead: floating-point error adds a pixel. Above 8192 px per side, `ImageRenderer` silently returns a transparent image, which is why `CropImageView.init` and `crop(outputSide:)` have a precondition. The output is always a square image, even for `.circle`.
- **Previews**: `previewImage(...)` is `#if DEBUG`-only, so any `#Preview` that uses it must also be wrapped in `#if DEBUG`.

## Swift Coding Style

### Naming
- `isPresenting` prefix for state that shows/dismisses a sheet or modal
- `final class` for repositories, services, and managers
- **View suffix** for screens and sheets: `LoginView`, `ProfileView`
- **Component suffixes** by role: `Card`, `Section`, `Header`, `Row`
- File suffixes: `ViewModel.swift`, `Repository.swift`, `+Computed.swift`, `+SampleData.swift`

### Formatting
- `// MARK:` sections: blank line **before**, no blank line **after**
- Annotate every closing brace in `body` with the container name (two spaces before):
  ```swift
  VStack {
    ...
  }  // VStack
  ```

### Comments
- `///` triple-slash on all functions
- `// MARK:` for section organization (skip if fewer than 5 members)

### Patterns
- `defer { isLoading = false }` for loading state cleanup
- `[weak self]` in closures that capture reference types
- No logic or computed properties in views; all derived values belong in the ViewModel

### Don'ts
- No force unwrap (`!`)
- No side effects inside `body`
- No direct Singleton access; use dependency injection

### View Structure
`// MARK:` order: `Environment` → `State` → `Namespace` → `Properties` → `Init` → `Body`

Omit empty sections. Skip `// MARK:` entirely for views with only `body` or fewer than 5 properties.

### ViewModel Structure
`// MARK:` order: `Data` → `State` → `Dependencies` → `Init` → `Computed` → `Functions`

Use `// MARK: - Properties` when ≤ 5 members; split into semantic sections beyond that.

### Previews
Every View file must include a `#Preview` at the bottom. Use `@Previewable @State` for bindings. Add named previews for multiple distinct states.
