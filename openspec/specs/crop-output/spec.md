# crop-output Specification

## Purpose
Deliver the framed crop to the app through `onCrop` as a square image at scale 1, the size
of the crop region.
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
The cropped image SHALL be rendered at scale 1, so its `size` equals its pixel size, and
SHALL include every pixel the crop region at least partly covers. Its side is therefore
the crop region's side in points, rounded outward to whole pixels.

#### Scenario: Whole-number crop region
- **WHEN** the crop region is 300 × 300 pt
- **THEN** the cropped image is 300 × 300 pixels at scale 1

#### Scenario: Fractional crop region
- **WHEN** the crop region is 301.5 × 301.5 pt in a 402 pt wide view
- **THEN** the cropped image is 302 × 302 pixels at scale 1
