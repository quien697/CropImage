## Context

`CropAreaViewModel.crop(outputSide:)` lays the image out as on screen, scaled by
`outputSide / cropSize.width` when `outputSide` is set, then clips it to a square frame
of `outputSide` points, or of the crop region's side when it's `nil`, and renders that
frame with `ImageRenderer` at scale 1. `ImageRenderer` sizes the image by rounding the
frame up to whole pixels, but SwiftUI's layout rounds the clipped frame to the nearest
pixel. When the side's fraction is under .5, the clip ends one pixel short of the image,
and the last row and column stay empty.

Measured with an opaque source image, alpha of the last column and last row:

| Side (pt) | Pixels | Last row and column |
|---|---|---|
| 300 | 300 | 255 |
| 300.15, 300.3, 300.45, 300.49 | 301 | 0 |
| 300.51, 300.6, 300.9 | 301 | 255 |
| 301.5 (402 pt wide view) | 302 | 255 |
| 305.4 (407.2 pt wide view) | 306 | 0 |
| `outputSide` 840.4 | 841 | 0 |
| `outputSide` 840.6 | 841 | 255 |

A 375 pt wide iPhone's crop region is 281.25 pt, so its crops have the empty edge when
`outputSide` is `nil`. A whole-number `outputSide` was never affected, because its frame
is whole.

## Goals / Non-Goals

**Goals:**
- Every pixel of a crop shows the framed image, for any crop region size and any
  `outputSide`.
- Output sizes stay as they are, for `nil` and for whole-number `outputSide` values.
- A test that fails on the empty edge, for both a fractional crop region and a fractional
  `outputSide`.

**Non-Goals:**
- Changing the crop region's size or position on screen.
- Changing how the content test compares crops with and without `outputSide`.
- The faint edge at the minimum zoom or the pan limit (see Risks), which has a different
  cause and was there before this change.

## Decisions

- **Render a whole-pixel side, scaled to fit** *(my call)*. `crop` picks the side it
  renders, `outputSide` or else the crop region's side, rounded up to whole pixels. It
  scales the layout by that side over the crop region's side, the way it already scales
  for `outputSide`. The clipped frame is then a whole number of points, which layout
  doesn't round, so it fills the image. Leaving `outputSide` `nil` now takes the same
  path as setting it, and that path already comes out exact at whole sizes.
  - *Alternative:* round the side down, or to the nearest pixel, to match layout.
    305.4 pt would give 305 pixels, which changes output sizes the spec promises and
    that apps may already depend on.
  - *Alternative:* clip to the rounded-up side without scaling. The image fills it, but
    the crop then shows up to a point of the image beyond the crop region, and the spec
    says it holds exactly what is inside the region.
- **A fractional `outputSide` rounds up** (the user's call), the same way as the crop
  region's side, rather than a precondition requiring whole numbers. A precondition would
  stop apps that pass a fractional value today and get a usable image.
- **The tests check every pixel.** A new helper reads the whole crop of an opaque source
  image through `colorSamples`, which fails the test if it can't create its drawing
  context, and returns the lowest alpha. Two tests expect 255: a 375 pt wide area
  without `outputSide`, and `outputSide` 840.4. Both get 0 before the fix.
  `centerAlpha` stays as it is.

## Risks / Trade-offs

- [The crop is enlarged by under one pixel] → At most 1 pixel over the side, under 0.4%
  at a 281.25 pt crop region, the same kind of scaling `outputSide` already applies.
- [Floating-point error puts a whole side a hair over a whole number, so rounding up adds
  a pixel] → Whole sides on 2x and 3x pixel grids compute exactly: checked for every
  ½ pt and ⅓ pt view size from 300 pt to 1800 pt.
- [The fix depends on layout leaving a whole frame alone] → The tests check every pixel,
  so a change in how SwiftUI rounds would fail them.
- [A faint edge remains at the minimum zoom or the pan limit] → There the image's edge
  lines up exactly with the crop's. Layout rounds the image's position and size to whole
  pixels before zoom and pan apply, so the edge can land up to half a pixel inside the
  crop, for whole sides and with `outputSide` too. Measured across phone sizes, the
  lowest alpha is 203 to 254, and 128 in a 428 × 926 pt view, before and after this
  change. In every case measured, this change leaves the lowest alpha the same or
  higher. Fixing it means computing the image's rectangle without layout, which is a
  change of its own.
