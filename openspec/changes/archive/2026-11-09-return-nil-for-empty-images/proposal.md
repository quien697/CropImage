## Why

An image without pixels, such as `UIImage()`, gets past the checks for an image. Its
zero size makes the rectangle `crop` draws into invalid, so `crop` returns a blank,
transparent square where its documentation promises `nil` when there is nothing to
render, and an app can't tell that square from a real crop. `CropImageView` keeps
Confirm enabled for such an image, so one tap delivers the blank square and closes the
screen, for example while an app shows `UIImage()` as a placeholder before the real
image loads.

## What Changes

- An image without pixels counts as no image: `CropAreaViewModel` stores it as `nil`.
- `crop(outputSide:)` returns `nil` for it.
- `CropImageView` disables Confirm for it, as without an image, so `onCrop` still
  receives `nil` only when rendering fails.

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `crop-output`: Confirm Delivers the Crop disables Confirm for an image without pixels,
  and Crop From the App's Own Screen returns `nil` for it.

## Impact

- Public API: no change. Nothing here is **BREAKING**: only an image without pixels is
  affected, and it now behaves as `nil` does, where it used to give a blank square. It
  ships in the next release with the rest of the review's fixes.
- Code: `CropAreaViewModel.imageChanged(to:)`, `settle()` and `crop(outputSide:)`'s
  documentation, `CropImageView.init`'s documentation, and tests in
  `CropAreaViewModelTests` and `CropImageViewModelTests`.
