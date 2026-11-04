# crop-output Specification

## Purpose
Deliver the framed crop to the app through `onCrop` as a square image at scale 1, either
the size of the crop region or a fixed pixel size set with `outputSide` (at most 8192).
## Requirements
### Requirement: Confirm Delivers the Crop
Tapping the confirm button SHALL call `onCrop` exactly once with the cropped image, then
dismiss the view. `onCrop` SHALL receive `nil` when there is no image or rendering fails.

#### Scenario: Confirm with an image
- **WHEN** the user taps the confirm button while an image is shown
- **THEN** `onCrop` receives the cropped image and the view is dismissed

#### Scenario: Confirm without an image
- **WHEN** the user taps the confirm button while `image` is `nil`
- **THEN** `onCrop` receives `nil` and the view is dismissed

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
to whole pixels.

#### Scenario: Whole-number crop region
- **WHEN** the crop region is 300 × 300 pt
- **THEN** the cropped image is 300 × 300 pixels at scale 1

#### Scenario: Fractional crop region
- **WHEN** the crop region is 301.5 × 301.5 pt in a 402 pt wide view
- **THEN** the cropped image is 302 × 302 pixels at scale 1

#### Scenario: Fractional crop region that used to gain a pixel
- **WHEN** the crop region is 300.5 × 300.5 pt in a 402 pt wide view
- **THEN** the cropped image is 301 × 301 pixels at scale 1

### Requirement: Fixed Output Size
When `outputSide` is set to a whole number, the cropped image SHALL be exactly
`outputSide` × `outputSide` pixels at scale 1, on every device and for every crop region
size, with the same content as without `outputSide`. If the framed part of the source
image has fewer pixels than that, it SHALL be upscaled.

#### Scenario: Fixed size on a phone
- **WHEN** the crop region is 301.5 × 301.5 pt and `outputSide` is 840
- **THEN** the cropped image is exactly 840 × 840 pixels at scale 1

#### Scenario: Large fixed size on a wide screen
- **WHEN** the crop region is 400 × 400 pt in a 1032 × 1376 pt view and `outputSide` is 4096
- **THEN** the cropped image is 4096 × 4096 pixels and contains the framed image, not a blank render

### Requirement: Output Size Limit
`outputSide` SHALL be at most 8192. Creating a `CropImageView` with a larger `outputSide`
SHALL stop with a precondition failure, rather than later delivering a blank image.

#### Scenario: Output side over the limit
- **WHEN** an app creates `CropImageView` with `outputSide` 10000
- **THEN** the app stops with the precondition failure "outputSide must be at most 8192 pixels"

