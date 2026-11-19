## Why

Crops look blurry on high-resolution screens, and worse when zoomed. Without
`outputSide`, the crop is the crop region's size in points at scale 1: 302 px on an iPhone
17 Pro, where the screen shows that region with about 900 pixels, however many pixels the
photo has there. Apple's Photos app keeps the photo's own pixels when it crops, and
CropImage should too. Once it does, `outputSide` is code no app needs, so it goes.

## What Changes

- **BREAKING** The cropped image is always the source image's full resolution: exactly
  the source pixels the crop region covers, copied one to one, on whole source pixels.
  Its side follows the zoom, as in Photos: zooming in gives a smaller image. It is still
  square and at scale 1, and at least 1 × 1 pixel.
- **BREAKING** Remove `outputSide` from `CropImageView.init`, which becomes
  `init(image:cropShape:title:onCrop:)`.
- **BREAKING** Replace `CropAreaViewModel.crop(outputSide:)` with `crop()`.
- Remove the 8192 px limit and both preconditions that enforced it. A crop never has
  more pixels than its source image, which the app already holds.

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `crop-output`: Output Size becomes the source's full resolution, and Crop Content
  allows its snapping to whole source pixels; Fixed Output Size and Output Size Limit
  are removed; Confirm Delivers the Crop and Crop From the App's Own Screen no longer
  mention `outputSide`.
- `crop-interaction`: the Crop Area requirement's view model swap scenario calls
  `crop()` instead of `crop(outputSide:)`.

## Impact

- Public API: **BREAKING**. Call sites that pass `outputSide` stop compiling, and every
  app gets crops at the source's resolution instead of the crop region's size in points,
  which for a large photo is a much larger image. An app that needs a fixed or smaller
  size resizes the crop itself. The previous updates haven't reached any app, so this
  ships as 1.2.0 rather than 2.0.0, by the owner's decision.
- Code: `CropAreaViewModel.crop`, `CropImageViewModel.confirm`, `CropImageView.init`,
  the `CropArea` preview, and their documentation.
- Tests: `CropAreaViewModelTests`, `CropImageViewModelTests`, `PublicAPITests`.
- Docs: README, CLAUDE.md (the public API list, `CropImageView`, and Rendering).
