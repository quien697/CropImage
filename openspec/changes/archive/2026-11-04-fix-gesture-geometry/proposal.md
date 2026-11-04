## Why

A review of the whole library found five bugs in how zoom, pan and the crop region are
calculated. One reaches Medal Wall today: after zooming all the way out, pinching inward
again flips the image upside down, because the pinch adds to the zoom instead of
multiplying it. The others appear in landscape, on iPad, after a resize, or when a gesture
is interrupted. Medal Wall avoids them for now, but any app that allows landscape or runs
on iPad would hit them, and fixing them while one app uses the library is cheapest.

## What Changes

- **Pinch zoom multiplies.** Spreading the fingers to twice their distance doubles the
  zoom from any starting level. The zoom can never reach zero or flip, and a single pinch
  can zoom out from any level. There is still no maximum zoom.
- **The crop region fits the view.** Its side becomes 75% of the smaller of the view's
  width and height, still capped at 400 pt. Portrait iPhone keeps the same crop region.
- **Size changes keep the framing valid.** When the view changes size, or the app passes
  an image of a different size, zoom and pan are corrected as at the end of a gesture.
- **Small images stay centered.** Where the image is narrower or shorter than the crop
  region, pan limiting centers it on that axis instead of pushing it off-center.
- **Interrupted gestures spring back.** A drag or pinch the system cancels returns the
  image to the zoom and pan it had before that gesture.
- Replace the deprecated `MagnificationGesture` with `MagnifyGesture`.

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `crop-interaction`: the crop region's size, how pinching and panning correct the
  framing, and new requirements for size changes and interrupted gestures.

## Impact

- Public API: no change. Behavior changes are fixes, so this is a patch version.
- Users of Medal Wall notice only that pinching works properly; portrait iPhone keeps the
  same crop region and framing.
- Code: `CropGeometry`, `CropImageViewModel` (gesture state and its corrections),
  `CropImageView` (gesture wiring, view and image size handling).
- Tests: new unit tests for the geometry and the view model's gesture math.
