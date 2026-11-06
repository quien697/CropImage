## Context

`crop(outputSide:)` builds a copy of `CropArea.body`'s modifier chain
(`resizable → scaledToFill → scaleEffect → offset → frame`), scaled so the crop region
is a whole number of points, and renders it with `ImageRenderer` at scale 1. Two
problems come from that.

- **Faint edges.** Layout rounds the image's frame position and size to whole pixels.
  Zoom and pan apply afterwards, as render effects, so the rounding error moves the
  image by up to half a pixel. That only shows where the image's edge lines up with the
  crop's edge, at the smallest zoom or at the pan limit. Measured with opaque images,
  the lowest alpha is 203 to 254 across phone sizes, and 128 in a 428 × 926 pt view. It
  happens for whole sides and with `outputSide`, before and after
  `prevent-transparent-crop-edges`.
- **HDR highlights clipped.** For an image `UIImage` flags as `isHighDynamicRange`,
  such as one in the PQ color space, `ImageRenderer` returns 8-bit sRGB: a linear value
  of 4.84 comes out as 0.99. For a Display P3 image it returns 16-bit extended sRGB and
  keeps the colors.

Measured alternatives, all in the simulator:

| Source | `ImageRenderer` today | Drawn in the source's format |
|---|---|---|
| sRGB, 8-bit | 8-bit sRGB | 8-bit sRGB |
| Display P3 red, 8-bit | 16-bit extended sRGB, red kept | 8-bit Display P3, red kept |
| PQ HDR, linear 4.84 | 8-bit sRGB, 0.99 | 16-bit extended sRGB, 4.84 |

Drawn crops were opaque to every edge in all 56 crops tried: 14 view sizes, from 320 ×
568 pt to an iPad's 1032 × 1376 pt, at the smallest zoom and at the pan limit, with
and without `outputSide`.

## Goals / Non-Goals

**Goals:**
- No partly transparent edge at the smallest zoom or the pan limit.
- The crop keeps the source image's colors, including wide color and HDR highlights.
- A test that fails if the crop stops showing what `CropArea` shows.

**Non-Goals:**
- Flagging HDR crops as `isHighDynamicRange`. The highlights are kept as extended-range
  values. Marking the image as HDR is a change of its own, if an app needs it.
- Showing HDR on screen. `CropArea` displays the image as SwiftUI does by default.
- Changing the framing, the output sizes, or the 8192 px limit.

## Decisions

- **Draw the image into a computed rectangle** (agreed with the user). `crop` keeps the
  whole-pixel side and output scale from `prevent-transparent-crop-edges`. The image's
  rectangle is its `scaledToFill` size from `CropGeometry.renderedSize` times the zoom,
  centered on the crop region's center plus the pan, all multiplied by the output scale.
  That is the same math `settle` uses to limit the pan, so at the limits the rectangle's
  edge is exactly the crop's edge. `UIGraphicsImageRenderer` draws it at scale 1.
  - *Alternative:* keep `ImageRenderer` and render HDR with `.allowedDynamicRange` or a
    `colorMode`. That leaves the faint edges, which come from layout.
  - *Alternative:* keep `ImageRenderer` and round the image's frame ourselves. The
    rounding happens inside SwiftUI's layout, out of reach.
- **Draw in the source image's format** (`imageRendererFormat`, with scale set to 1),
  so an sRGB image gives 8-bit sRGB, a Display P3 image 8-bit Display P3, and an HDR
  image 16-bit extended range.
- **Keep the alpha channel** (`opaque` set to false). A photo without alpha, such as a
  decoded JPEG, has an opaque format, and drawing in it drops the crop's alpha channel.
  Crops have always had one, so they keep it.
  - *Alternative:* the renderer's `.automatic` range. It gives 16-bit extended sRGB for
    Display P3 too, twice the memory for the same colors.
- **High-quality interpolation** on the drawing context. Measured against `CropArea`
  rendered with the same framing, the crop differs by 0.2 to 1.5 levels in 255 on
  average. A lower quality would save time only at large sizes, where the drawing is
  already within a few tens of milliseconds of `ImageRenderer` (see Risks).
- **Draw through `UIImage.draw(in:)`**, which applies the image's orientation as
  `Image(uiImage:)` does on screen. Camera photos usually carry a rotation in their
  orientation, and drawing the `CGImage` directly would lose it.
- **A test compares the crop with the area as shown.** It renders `CropArea` with
  `ImageRenderer` at 4 pixels per point, takes the crop region's pixels, worked out from
  `CropGeometry.cropSize`, and compares them with `crop` at an `outputSide` of 4 times
  the crop region's side. At 4 pixels per point, a 402 pt wide view's 301.5 pt crop
  region falls on whole pixels too. Correct framings differ by 0.2 to 1.5 levels on
  average, and a pan that's off by 10 pt gives 4.4 to 16.7, so the test allows under 3.
  `CropArea.body` is then the only layout, and the test replaces the rule to keep a
  copied chain in sync with it.
- **Tests that fail first:** the smallest zoom in a 428 × 926 pt view (alpha 128 today),
  the pan limit in a 400 × 800 pt view (244 today), an HDR image (0.99 today), and a
  decoded JPEG's crop having an alpha channel (none in the source's own format). Tests
  that already pass and guard the change: a Display P3 image keeps its red, and the crop
  matches the area as shown, including for an image turned by its orientation.

## Risks / Trade-offs

- [The rectangle math drifts from `CropArea.body`'s layout] → The comparison test fails.
  Breaking the rectangle on purpose, by dropping the pan, should fail it.
- [Core Graphics resamples a little differently from SwiftUI] → 0.2 to 1.5 levels in
  255 on average, measured, most where the image is enlarged most.
- [Display P3 crops change pixel format] → Same colors in half the memory. An app that
  reads the bitmap's format sees 8-bit Display P3 instead of 16-bit extended sRGB.
- [Speed] → Measured with the pixels produced, `ImageRenderer` against drawing: 4.5 ms
  and 3.7 ms at 840 px, 43 ms and 66 ms at 4096 px, 1.4 s and 0.23 s at 8192 px.
- [An HDR crop isn't flagged as HDR] → Its highlights are kept as values. A view that
  shows only flagged images in HDR shows it in standard range.
- [An HDR crop takes twice the memory] → Its 16-bit bitmap is 512 MB at 8192 px, where
  the clipped 8-bit crop was 256 MB. That is the cost of keeping the highlights, and
  only apps that load images as HDR pay it. Display P3 crops, which are far more
  common, drop from 16-bit to 8-bit and halve.
- [The rectangle copies `CropArea.body`'s layout as math] → Placing the on-screen image
  from the same rectangle would remove the copy, but it changes how the area lays out
  and animates the image. The comparison test guards the copy instead.
