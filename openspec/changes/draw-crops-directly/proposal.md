## Why

After `prevent-transparent-crop-edges`, two problems remain with how `crop` renders.
When the image's edge lines up with the crop region's edge, at the smallest zoom or at
the pan limit, the crop's edge row or column can be partly transparent. Layout rounds
the image's position and size to whole pixels before zoom and pan apply, so the edge
lands up to half a pixel inside the crop. Across phone sizes the lowest alpha is 203 to
254, and 128 in a 428 × 926 pt view, for whole sides and with `outputSide` too. Separately,
a high dynamic range image (`isHighDynamicRange`, such as one in the PQ color space)
comes out as 8-bit sRGB with its highlights clipped to white: a linear value of 4.84
becomes 0.99. Wide-color Display P3 images keep their colors today, and must keep them.

## What Changes

- `crop(outputSide:)` draws the image straight into the cropped image, at a rectangle
  worked out from the framing, instead of laying it out with SwiftUI and rendering it
  with `ImageRenderer`.
- At the smallest zoom and at the pan limit, the crop shows the image up to every edge.
- The crop keeps the source image's colors. An sRGB image stays 8-bit sRGB, and a
  Display P3 image comes out as 8-bit Display P3 with the same colors. An HDR image keeps
  its highlights.
- A test renders `CropArea` and checks that the crop shows what the area shows. It
  replaces the rule to keep a copy of `CropArea.body`'s modifier chain in sync with it.

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `crop-output`: new requirements for the crop's edges at the zoom and pan limits, and
  for keeping the source image's colors, including wide color and HDR highlights.

## Impact

- Public API: no change. Nothing here is **BREAKING**: crops keep their sizes, framing,
  colors and alpha channel, and only the bitmap format of Display P3 and HDR crops
  changes. It ships in the next release with the rest of the review's fixes.
- Behavior: a crop's pixel values shift by 0.2 to 1.5 levels in 255 on average against
  the area as shown, because the image is resampled by Core Graphics rather than by
  SwiftUI. Display P3 crops come out as 8-bit Display P3 instead of
  16-bit extended sRGB, with the same colors. HDR crops keep their highlights, in 16-bit
  extended range, though `UIImage` doesn't flag them as `isHighDynamicRange`.
- Code: `CropAreaViewModel.crop(outputSide:)` and
  `Tests/CropImageTests/CropAreaViewModelTests.swift`.
- Docs: the Rendering note in `CLAUDE.md`, and the pixel-content advice in
  `.claude/rules/development-workflow.md`, which names `ImageRenderer`.
