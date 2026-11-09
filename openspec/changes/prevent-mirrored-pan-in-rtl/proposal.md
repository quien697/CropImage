## Why

In a right-to-left layout, such as an app running in Arabic or Hebrew, `CropArea` shows
the pan mirrored: SwiftUI flips a view's horizontal offset for right-to-left layouts.
`crop` draws the pan as it is stored, so a photo panned 40 pt one way on screen comes
out panned 40 pt the other way, and the crop isn't what the user framed. Measured in a
400 × 800 pt area at zoom 1.7, the area shows a pan of (40, −65) where `crop` draws one
of (−40, −65). Left-to-right apps aren't affected.

## What Changes

- `CropArea` keeps the image and its gestures left-to-right in every layout direction,
  so the image is shown at the pan `crop` draws, and dragging moves it as in a
  left-to-right layout. A photo's left and right don't swap for right-to-left languages.
- In a right-to-left layout, the crop is what the area shows.
- The test that compares the crop with the area as shown gains a right-to-left framing.
- Nothing else in the area changes direction: the mask, grid and crop region are
  centered and symmetric, and `CropImageView`'s toolbar still follows the app's layout.

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `crop-output`: Crop Content gains a right-to-left scenario.
- `crop-interaction`: Pan gains a right-to-left scenario.

## Impact

- Public API: no change. Nothing here is **BREAKING**: left-to-right apps see no
  change, and right-to-left apps now get the crop the user framed, as Crop Content
  already requires. It ships in the next release with the rest of the review's fixes.
- Behavior: in a right-to-left layout, the crop's pan matches the screen.
- Code: `Sources/CropImage/Views/CropArea.swift` and
  `Tests/CropImageTests/CropAreaViewModelTests.swift`.
- Docs: the `CropArea` note in `CLAUDE.md`.
