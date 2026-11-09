## Why

A review of the whole library suspected that a crop region whose side isn't a whole number
of points leaves the crop's last pixel row and column partly transparent. Measured, it's
worse: when the side's fraction is under .5, the last row and column are fully
transparent. A 407.2 pt wide area has a 305.4 pt crop region and gives a 306 × 306 pixel
crop whose last row and column have alpha 0. A 375 pt wide iPhone gives 281.25 pt and the
same empty edge. A fractional `outputSide` does the same: 840.4 gives 841 pixels with an
empty last row and column. The crop is the right size, so the existing size tests pass.

## What Changes

- The crop region fills every pixel of the cropped image. A side that is rounded up to
  whole pixels no longer leaves its last row and column empty.
- A fractional `outputSide` rounds up to whole pixels, filled the same way: 840.4 gives
  841 × 841 pixels.
- Output sizes stay as they are, for `outputSide` set to a whole number and for
  `outputSide` left `nil`.

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `crop-output`: the Output Size requirement says the crop region fills the whole image,
  with a scenario for a 375 pt wide view. The Fixed Output Size requirement says a
  fractional `outputSide` rounds up to whole pixels and is filled, with a scenario for
  840.4.

## Impact

- Public API: no change. Nothing here is **BREAKING**, and it ships in the next release
  with the rest of the review's fixes.
- Behavior: a crop whose side was rounded up now shows exactly the crop region, enlarged
  by under one pixel to fill the image. That includes common sides such as 301.5 pt,
  whose crops were already fully opaque.
- Code: `CropAreaViewModel.crop(outputSide:)`, the `outputSide` doc comments on it and on
  `CropImageView.init`, and `Tests/CropImageTests/CropAreaViewModelTests.swift`.
- Docs: the Rendering note in `CLAUDE.md`.
