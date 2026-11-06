# crop-output Specification

## Purpose
Deliver the framed crop to the app as a square image at scale 1, through `onCrop` on
`CropImageView` or `CropAreaViewModel.crop(outputSide:)` on an app's own screen, either
the size of the crop region or a fixed pixel size set with `outputSide` (greater than 0
and at most 8192).
## Requirements
### Requirement: Confirm Delivers the Crop
Tapping the confirm button of `CropImageView` SHALL call `onCrop` exactly once with the
cropped image, then dismiss the view. The confirm button SHALL be disabled while `image`
is `nil`, so `onCrop` SHALL receive `nil` only when rendering fails. After the first tap,
the confirm button SHALL be disabled and `onCrop` SHALL NOT be called again for as long
as the view stays on screen.

#### Scenario: Confirm with an image
- **WHEN** the user taps the confirm button while an image is shown
- **THEN** `onCrop` receives the cropped image and the view is dismissed

#### Scenario: Confirm without an image
- **WHEN** `image` is `nil`
- **THEN** the confirm button is disabled, `onCrop` is not called, and the close button still dismisses the view

#### Scenario: Confirm tapped again before the view closes
- **WHEN** the user taps the confirm button a second time before the view has closed, for example while a large `outputSide` is rendering
- **THEN** `onCrop` has been called once, and the confirm button is disabled

### Requirement: Crop Content
The cropped image SHALL contain exactly what is inside the crop region as the user
framed it at the moment of confirming, including their pan and zoom. The image SHALL be
square for every `cropShape`: a `.circle` crop is not masked, so the area outside the
circle is included.

#### Scenario: Circle crop output
- **WHEN** the user confirms a `.circle` crop
- **THEN** `onCrop` receives the full square around the circle, with no transparent corners

### Requirement: Output Size
When `outputSide` is `nil`, the cropped image SHALL be rendered at scale 1, so its `size`
equals its pixel size, and its side SHALL be the crop region's side in points, rounded up
to whole pixels. The crop region SHALL fill the whole image, so a side that was rounded
up leaves no empty row or column at the image's edges.

#### Scenario: Whole-number crop region
- **WHEN** the crop region is 300 × 300 pt
- **THEN** the cropped image is 300 × 300 pixels at scale 1

#### Scenario: Fractional crop region
- **WHEN** the crop region is 301.5 × 301.5 pt in a 402 pt wide view
- **THEN** the cropped image is 302 × 302 pixels at scale 1

#### Scenario: Fractional crop region that used to gain a pixel
- **WHEN** the view is 407.2 pt wide, so the crop region is 305.4 × 305.4 pt and starts 50.9 pt from the view's left edge
- **THEN** the cropped image is 306 × 306 pixels at scale 1

#### Scenario: Fractional crop region under half a pixel
- **WHEN** the view is 375 pt wide, so the crop region is 281.25 × 281.25 pt
- **THEN** the cropped image is 282 × 282 pixels at scale 1, and its last row and column show the image rather than empty pixels

### Requirement: Fixed Output Size
When `outputSide` is set to a whole number, the cropped image SHALL be exactly
`outputSide` × `outputSide` pixels at scale 1, on every device and for every crop region
size, with the same content as without `outputSide`. A fractional `outputSide` SHALL be
rounded up to whole pixels, and the crop region SHALL fill the whole image. If the framed
part of the source image has fewer pixels than that, it SHALL be upscaled.

#### Scenario: Fixed size on a phone
- **WHEN** the crop region is 301.5 × 301.5 pt and `outputSide` is 840
- **THEN** the cropped image is exactly 840 × 840 pixels at scale 1

#### Scenario: Large fixed size on a wide screen
- **WHEN** the crop region is 400 × 400 pt in a 1032 × 1376 pt view and `outputSide` is 4096
- **THEN** the cropped image is 4096 × 4096 pixels and contains the framed image, not a blank render

#### Scenario: Fractional fixed size
- **WHEN** `outputSide` is 840.4
- **THEN** the cropped image is 841 × 841 pixels at scale 1, and its last row and column show the image rather than empty pixels

### Requirement: Output Size Limit
`outputSide` SHALL be greater than 0 and at most 8192. Creating a `CropImageView`, or
calling `CropAreaViewModel.crop(outputSide:)`, with an `outputSide` outside that range SHALL
stop with a precondition failure, rather than delivering a blank image or `nil`.

#### Scenario: Output side over the limit
- **WHEN** an app creates `CropImageView` with `outputSide` 10000
- **THEN** the app stops with the precondition failure "outputSide must be greater than 0 and at most 8192 pixels"

#### Scenario: Output side of zero
- **WHEN** an app creates `CropImageView` with `outputSide` 0
- **THEN** the app stops with the precondition failure "outputSide must be greater than 0 and at most 8192 pixels"

#### Scenario: Output side over the limit on the app's own screen
- **WHEN** an app calls `crop(outputSide: 10000)` on a `CropAreaViewModel`
- **THEN** the app stops with the precondition failure "outputSide must be greater than 0 and at most 8192 pixels"

### Requirement: Crop From the App's Own Screen
`CropAreaViewModel.crop(outputSide:)` SHALL return the image its `CropArea` frames, as
described by the Crop Content, Output Size and Fixed Output Size requirements, with
`outputSide` meaning the same as for `CropImageView`. It SHALL use the zoom and pan as of
the last finished gesture, and SHALL NOT dismiss or change anything on screen. It SHALL
return `nil` when the area has no image, has not appeared yet, or rendering fails.

#### Scenario: App's own Confirm button
- **WHEN** the user has framed an image in a `CropArea` and the app calls `crop(outputSide: 840)`
- **THEN** it returns an 840 × 840 pixel image of the framed region, and the `CropArea` stays on screen with the same framing

#### Scenario: Same output as the ready-made screen
- **WHEN** a `CropArea` and a `CropImageView` of the same size show the same image with the same zoom and pan
- **THEN** `crop(outputSide:)` and `onCrop` deliver the same image for the same `outputSide`

#### Scenario: No image
- **WHEN** the `CropArea`'s image is `nil`
- **THEN** `crop(outputSide:)` returns `nil`

#### Scenario: Before the area appears
- **WHEN** the app calls `crop(outputSide:)` before its `CropArea` has appeared
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

