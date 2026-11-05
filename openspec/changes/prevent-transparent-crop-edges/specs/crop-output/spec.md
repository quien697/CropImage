## MODIFIED Requirements

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
