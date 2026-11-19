## Context

`crop(outputSide:)` draws the image with `UIGraphicsImageRenderer` at scale 1 into a
square of `outputSide` pixels, or else the crop region's side in points rounded up. The
image's rectangle is its `scaledToFill` size (`CropGeometry.renderedSize`) times the
zoom, centered on the crop region's center plus the pan, all scaled by the output side
over the crop region's side. The output size therefore depends on the screen, not on the
photo: 302 px on an iPhone 17 Pro, 400 px on an iPad. The image is always resampled,
and the result looks blurry on high-resolution screens.

`outputSide` (added in 1.1.0) and its 8192 px precondition, in `CropImageView.init` and
`crop(outputSide:)`, go away with this change. An app that needs a fixed size resizes
the crop itself.

## Goals / Non-Goals

**Goals:**
- The crop is exactly the source pixels the crop region covers, copied one to one, as
  in Apple's Photos app.
- The public API loses `outputSide`: `CropImageView.init(image:cropShape:title:onCrop:)`
  and `CropAreaViewModel.crop()`.
- The crop keeps everything it does today: what `CropArea` shows, the orientation, wide
  color and HDR highlights, the alpha channel, opaque edges at the zoom and pan limits.

**Non-Goals:**
- A size option, a maximum size, or downscaling. An app that needs a smaller image
  resizes the crop itself.
- A zoom limit. Extreme zoom gives a tiny crop, down to 1 × 1 px.
- Changing the framing, the crop region, or gestures.

## Decisions

- **Work out the crop in source pixels, then snap it to whole pixels.** The source's
  pixel size is `image.size × image.scale`, with orientation already applied by
  `UIImage.size`. On screen the image is `renderedSize × zoom` points, so the crop
  region covers `pixelsPerPoint = pixelWidth / (renderedWidth × zoom)` source pixels per
  point. In source pixels, the crop's side is `cropSide × pixelsPerPoint` and its
  origin is `((renderedSize × zoom − cropSide) / 2 − pan) × pixelsPerPoint` on each
  axis. Round the side to the nearest whole pixel, at least 1 and at most the source's
  shorter side, and round the origin to whole pixels, clamped so the square stays inside
  the source. The square stays inside the source anyway, because `settle` keeps the
  image covering the crop region. The clamp only absorbs rounding.
  - *Alternative:* keep drawing at fractional positions with high-quality
    interpolation. That resamples every pixel and softens the crop, which is what this
    change fixes.
- **Put that math in `CropGeometry`**, as a pure function from the source's pixel size,
  rendered size, zoom, pan and crop region to the crop's rectangle in source pixels.
  That's where the framing math already lives, and rounding and clamping can be tested
  there without rendering.
- **Draw the whole image at its pixel size, offset by the snapped origin.**
  `UIGraphicsImageRenderer` makes a `side × side` canvas at scale 1, in the source's
  `imageRendererFormat` with `opaque` false, as today. `image.draw(in:)` then draws at
  `(-originX, -originY, pixelWidth, pixelHeight)`. With a whole-pixel offset and the
  image at its own pixel size, each output pixel is one source pixel. Set the context's
  `interpolationQuality` to `.none`, so tiny floating-point error can't blend
  neighbors. `UIImage.draw(in:)` still applies the orientation, and the format still
  keeps wide color and HDR.
  - *Alternative:* `cgImage.cropping(to:)`. It's exact and cheap, but `cgImage` is the
    unrotated bitmap. The rectangle would need mapping through all eight orientations,
    an image without a `cgImage` would need a second path, and the output would no
    longer be upright with an alpha channel.
- **Remove `outputSide` everywhere.** That covers `CropImageView`'s stored property,
  init parameter and precondition, `CropImageViewModel.confirm(outputSide:onCrop:)`
  (which becomes `confirm(onCrop:)`), `crop(outputSide:)` (which becomes `crop()`), and
  the `CropArea` preview's `crop(outputSide: 840)`.
- **Tests compare against source pixels.** The size tests use the spec's numbers: 450,
  225 and 1200 px for a 1200 px image in a 400 × 800 pt area, 414 px in a 402 × 874 pt
  area, a scale-3 source, and 1 px at extreme zoom. A single-pixel black-and-white
  checkerboard, zoomed and panned, must come out with every pixel pure black or white
  and every pair of neighbors different. That rules out blending, and it rules out
  scaling, which would repeat pixels. `cropShowsWhatTheAreaShows` keeps comparing
  against a `CropArea` rendered at 4 pixels per point, now with `crop()`. Its
  comparison samples both images on a 64 × 64 grid, so their sizes don't need to match.

## Risks / Trade-offs

- [Large photos make large crops: a 48 MP photo zoomed out gives a 6048 px square,
  about 146 MB, or 292 MB for a 16-bit HDR source] → It is never more than the source
  the app already holds. The README tells apps that upload or store crops to resize
  them.
- [Snapping moves the crop by up to half a source pixel, which can be visible on a tiny
  source] → It is the least a crop on whole pixels can move. The spec allows it.
- [**BREAKING** change: call sites that pass `outputSide` stop compiling, and every app
  gets much larger crops] → It ships as 2.0.0. An app that resolves CropImage "up to
  next major" from 1.0.0 or 1.1.0 stays on 1.x until it moves to 2.0.0 on purpose.

## Migration Plan

Apps remove `outputSide:` from `CropImageView(...)` and change `crop(outputSide:)` to
`crop()`. To roll back, pin the app to 1.1.0.
