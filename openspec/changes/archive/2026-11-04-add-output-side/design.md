## Context

`CropImageViewModel.crop` on `main` renders the whole view with `ImageRenderer` at scale 1
and cuts the crop region out with `cgImage.cropping(to:)`. A fixed output size means
rendering at a higher scale, and the size has to come out exact, because apps that ask for
840 px usually store or upload exactly that.

## Goals / Non-Goals

**Goals:**
- An exact, device-independent pixel size when the app asks for one.
- Work for any app and screen, up to `ImageRenderer`'s limit, not only the size and device
  that prompted the change.
- No change for existing call sites beyond the default-rounding detail in the proposal.

**Non-Goals:**
- Output at the source image's native resolution.
- Non-square output, or masking `.circle` crops.
- Validating `outputSide` values of zero or less.

## Decisions

- **Render only the crop region.** Lay the image out in the view's size as on screen,
  wrap it in a frame the size of the crop region, clip, and render that. Alternative:
  `main`'s approach, which renders the whole view and then crops. At a high scale that
  render goes past 8192 px on its long side and comes back transparent, from about
  2380 px of output on an iPad and about 2826 px on an iPhone 17 Pro.
- **Scale the layout, not the renderer.** Multiply the view size and pan by
  `outputSide / cropSide` so the clip frame is exactly `outputSide` points, then render at
  scale 1. Alternative: set `renderer.scale = outputSide / cropSide`. Floating-point error
  makes `301.5 × (840 / 301.5)` slightly over 840, and the renderer rounds it up to
  841 px. As a side effect the result always has scale 1, so its `size` equals its pixel
  size, which matches the default output.
- **Precondition above 8192**, rather than capping the value or returning `nil`.
  `outputSide` is normally a constant, so a developer hits the precondition the first
  time they run the app. Capping would silently deliver a different size, and `nil` can't
  be told apart from "no image".
- **`CGFloat`, not `Int`**, to match how UIKit and SwiftUI express sizes.

## Risks / Trade-offs

- [A framed area with fewer source pixels than `outputSide` is upscaled and looks soft]
  → Documented on the parameter. Apps that care can check the source image's size first.
- [The default size can drop by one pixel for crop regions that aren't whole points]
  → Called out in the proposal and pinned by a test (task 3.1). Apps that read the
  default size see it get closer to the crop region's size, never larger.
- [The precondition can't be unit tested] → Swift Testing exit tests aren't available on
  iOS, so it is checked by review instead.
