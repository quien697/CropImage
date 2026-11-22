# crop-output Specification

## Purpose
Deliver the framed crop to the app as a square image at scale 1, through `onCrop` on
`CropImageView` or `CropAreaViewModel.crop()` on an app's own screen, at the source
image's full resolution: the source pixels the crop region covers, copied as they are.
## Requirements
### Requirement: Confirm Delivers the Crop
Tapping the confirm button of `CropImageView` SHALL call `onCrop` once, from the main
actor, with the cropped image of the framing at the moment of the tap, and SHALL dismiss
the view when `onCrop` returns. `onCrop` is asynchronous and throwing, and the view SHALL
stay on screen for as long as it runs. The confirm button SHALL be disabled while
`image` is `nil` or has no pixels, so `onCrop` SHALL receive `nil` only when rendering
fails. While `onCrop` runs, the confirm button SHALL be disabled and `onCrop` SHALL NOT
be called again. When `onCrop` throws, the view SHALL stay on screen with the zoom and
pan as the user left them, SHALL show no message of its own, and SHALL enable the confirm
button again, so the next tap calls `onCrop` with the crop of the framing at that tap.
After `onCrop` returns, the confirm button SHALL stay unavailable and `onCrop` SHALL NOT
be called again for as long as the view stays on screen.

#### Scenario: Confirm with an image
- **WHEN** the user taps the confirm button while an image is shown, and `onCrop` returns
- **THEN** `onCrop` receives the cropped image and the view is dismissed

#### Scenario: Synchronous onCrop
- **WHEN** an app passes a synchronous, non-throwing closure, such as `{ result in croppedImage = result }`
- **THEN** the call site compiles unchanged, and the view is dismissed after the closure returns, as before

#### Scenario: onCrop that waits
- **WHEN** `onCrop` awaits work, such as an upload, before it returns
- **THEN** the view stays on screen until `onCrop` returns, and is dismissed then

#### Scenario: onCrop throws
- **WHEN** `onCrop` throws
- **THEN** the view stays on screen with the same zoom and pan, CropImage shows no message, and the confirm button is enabled

#### Scenario: Confirm again after onCrop throws
- **WHEN** `onCrop` has thrown, and the user zooms in and taps the confirm button again
- **THEN** `onCrop` is called again, with the crop of the new framing

#### Scenario: Confirm without an image
- **WHEN** `image` is `nil`
- **THEN** the confirm button is disabled, `onCrop` is not called, and the close button still dismisses the view

#### Scenario: Confirm with an image without pixels
- **WHEN** `image` has no pixels, such as `UIImage()`
- **THEN** the confirm button is disabled and `onCrop` is not called, as without an image

#### Scenario: Confirm tapped again while onCrop runs
- **WHEN** the user taps the confirm button a second time while `onCrop` is still running
- **THEN** `onCrop` has been called once

#### Scenario: Confirm tapped again before the view closes
- **WHEN** `onCrop` has returned, and the user taps the confirm button again before the view has closed
- **THEN** `onCrop` has been called once, and the confirm button still shows a progress indicator

### Requirement: Crop Content
The cropped image SHALL contain what is inside the crop region as the user framed it at
the moment of confirming, including their pan and zoom, to the nearest whole source
pixel as the Full-Resolution Output requirement describes. The image SHALL be square for every
`cropShape`: a `.circle` crop is not masked, so the area outside the circle is included.

#### Scenario: Circle crop output
- **WHEN** the user confirms a `.circle` crop
- **THEN** `onCrop` receives the full square around the circle, with no transparent corners

#### Scenario: Right-to-left layout
- **WHEN** the app's layout is right-to-left and the user has panned the image
- **THEN** the cropped image shows what the crop region shows, panned the same way

### Requirement: Crop From the App's Own Screen
`CropAreaViewModel.crop()` SHALL return the image its `CropArea` frames, as described by
the Crop Content and Full-Resolution Output requirements. It SHALL use the zoom and pan as of the
last finished gesture, and SHALL NOT dismiss or change anything on screen. It SHALL
return `nil` when the area has no image, its image has no pixels, it has not appeared
yet, or rendering fails.

#### Scenario: App's own Confirm button
- **WHEN** the user has framed an image in a `CropArea` and the app calls `crop()`
- **THEN** it returns the framed region at the source image's full resolution, and the `CropArea` stays on screen with the same framing

#### Scenario: Same output as the ready-made screen
- **WHEN** a `CropArea` and a `CropImageView` of the same size show the same image with the same zoom and pan
- **THEN** `crop()` and `onCrop` deliver the same image

#### Scenario: No image
- **WHEN** the `CropArea`'s image is `nil`
- **THEN** `crop()` returns `nil`

#### Scenario: Image without pixels
- **WHEN** the `CropArea`'s image has no pixels, such as `UIImage()`
- **THEN** `crop()` returns `nil`

#### Scenario: Before the area appears
- **WHEN** the app calls `crop()` before its `CropArea` has appeared
- **THEN** it returns `nil`

### Requirement: Edges at the Zoom and Pan Limits
When the image's edge lines up with the crop region's edge, at the smallest zoom or at
the pan limit, the cropped image SHALL show the image right up to that edge, with no
partly transparent row or column.

#### Scenario: Zoomed out as far as it goes
- **WHEN** an opaque square image is zoomed out as far as it goes in a 428 × 926 pt view, so it just covers the crop region
- **THEN** every pixel of the cropped image is opaque

#### Scenario: Panned to the limit
- **WHEN** an opaque 4:3 image is zoomed out as far as it goes and panned as far as it goes in a 400 × 800 pt view
- **THEN** every pixel of the cropped image is opaque

### Requirement: Source Colors Kept
The cropped image SHALL keep the source image's colors. A wide-color image SHALL keep
its colors outside sRGB, and a high dynamic range image SHALL keep its highlights
brighter than standard white.

#### Scenario: Wide-color image
- **WHEN** the image is Display P3 and its colors are outside sRGB
- **THEN** the cropped image has the same colors

#### Scenario: High dynamic range image
- **WHEN** the image is high dynamic range, with highlights brighter than standard white
- **THEN** the cropped image keeps those highlights instead of clipping them to white

### Requirement: Full-Resolution Output
The cropped image SHALL be the source image at its full resolution: exactly the source
pixels the crop region covers, each copied to one pixel of the output without
resampling. It SHALL be rendered at scale 1, so its `size` equals its pixel size, and
its side SHALL be the number of source pixels the crop region's side covers, rounded to
the nearest whole pixel and at least 1. Source pixels SHALL be counted in pixels, not
points, so the source's `scale` doesn't change the result. The crop's edges SHALL fall on
whole source pixels inside the source image, so it may show up to half a source pixel
more or less than the crop region at each edge, and every pixel of the output SHALL come
from the source image.

#### Scenario: Initial framing
- **WHEN** a 1200 × 1200 pixel image is shown at the initial framing in a 400 × 800 pt view, so the 300 pt crop region covers 450 source pixels
- **THEN** the cropped image is 450 × 450 pixels at scale 1

#### Scenario: Zoomed in
- **WHEN** the same image is zoomed in to twice the initial framing
- **THEN** the cropped image is 225 × 225 pixels at scale 1

#### Scenario: Zoomed out as far as it goes
- **WHEN** the same image is zoomed out until it just covers the crop region
- **THEN** the cropped image is 1200 × 1200 pixels at scale 1, the whole source image

#### Scenario: Source with a scale above 1
- **WHEN** a 400 × 400 pt image at scale 3, which has 1200 × 1200 pixels, is shown at the initial framing in a 400 × 800 pt view
- **THEN** the cropped image is 450 × 450 pixels at scale 1, as for a 1200 × 1200 pixel image at scale 1

#### Scenario: Side that isn't a whole number of source pixels
- **WHEN** a 1200 × 1200 pixel image is shown at the initial framing in a 402 × 874 pt view, so the 301.5 pt crop region covers about 413.96 source pixels
- **THEN** the cropped image is 414 × 414 pixels at scale 1

#### Scenario: Pixels copied without resampling
- **WHEN** the image is a checkerboard of single black and white pixels, zoomed and panned
- **THEN** every pixel of the cropped image is pure black or pure white, matching the source pixel it was copied from

#### Scenario: Crop region smaller than one source pixel
- **WHEN** the image is zoomed in so far that the crop region covers less than half a source pixel
- **THEN** the cropped image is 1 × 1 pixel at scale 1

