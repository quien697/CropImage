## Context

`crop` checks that there is an image and that the area has a size, then draws the image
at its `scaledToFill` size times the zoom. For an image of size zero, such as `UIImage()`,
`CropGeometry.renderedSize` divides 0 by 0, the rectangle is NaN, nothing is drawn, and
`crop` returns a blank, transparent square. `settle` has its own check and returns early
for such an image. `CropImageViewModel.canConfirm` checks only that the area's image
isn't `nil`, so Confirm is enabled.

## Goals / Non-Goals

**Goals:**
- An image without pixels behaves as no image: `crop` returns `nil`, and Confirm is
  disabled.
- One check decides what counts as an image without pixels.

**Non-Goals:**
- Images whose size is huge but finite, such as a `CIImage` of infinite extent, which
  `UIImage` reports as 1.8 × 10³⁰⁸ points. They don't produce NaN, and an `isFinite`
  check wouldn't catch them.

## Decisions

- **`imageChanged(to:)` stores an image without pixels as `nil`** (suggested in code
  review). `settle`, `crop` and `canConfirm` all read the stored image, so they treat it
  as no image without checks of their own, and `settle`'s own check is removed.
  - *Alternative:* check the size in `crop`'s guard. It was the first fix, but it left
    Confirm enabled, so `onCrop` got `nil` without a rendering failure, against Confirm
    Delivers the Crop, and it repeated `settle`'s check.
  - *Alternative:* check the size in `CropGeometry.renderedSize`. It returns a size, not
    an optional, so every caller would need a second way of saying "nothing to frame".
- **Tests that fail first:** `cropOfAnImageWithoutPixelsIsNil` (a blank square today)
  and `confirmIsUnavailableForAnImageWithoutPixels` (Confirm enabled today).
  `anEmptyImageLeavesTheFramingAlone` already passes and keeps guarding the framing
  against 0 / 0.

## Risks / Trade-offs

- [An app passes `UIImage()` as a placeholder and taps Confirm before the image loads]
  → Confirm is disabled until the real image arrives, as it is for `nil`.
- [An app reads the blank square `crop` used to return] → It gets `nil`, which `crop`'s
  documentation has always promised when there is nothing to render.
