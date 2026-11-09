## MODIFIED Requirements

### Requirement: Confirm Delivers the Crop
Tapping the confirm button of `CropImageView` SHALL call `onCrop` exactly once with the
cropped image, then dismiss the view. The confirm button SHALL be disabled while `image`
is `nil` or has no pixels, so `onCrop` SHALL receive `nil` only when rendering fails.
After the first tap, the confirm button SHALL be disabled and `onCrop` SHALL NOT be
called again for as long as the view stays on screen.

#### Scenario: Confirm with an image
- **WHEN** the user taps the confirm button while an image is shown
- **THEN** `onCrop` receives the cropped image and the view is dismissed

#### Scenario: Confirm without an image
- **WHEN** `image` is `nil`
- **THEN** the confirm button is disabled, `onCrop` is not called, and the close button still dismisses the view

#### Scenario: Confirm with an image without pixels
- **WHEN** `image` has no pixels, such as `UIImage()`
- **THEN** the confirm button is disabled and `onCrop` is not called, as without an image

#### Scenario: Confirm tapped again before the view closes
- **WHEN** the user taps the confirm button a second time before the view has closed, for example while a large `outputSide` is rendering
- **THEN** `onCrop` has been called once, and the confirm button is disabled

### Requirement: Crop From the App's Own Screen
`CropAreaViewModel.crop(outputSide:)` SHALL return the image its `CropArea` frames, as
described by the Crop Content, Output Size and Fixed Output Size requirements, with
`outputSide` meaning the same as for `CropImageView`. It SHALL use the zoom and pan as of
the last finished gesture, and SHALL NOT dismiss or change anything on screen. It SHALL
return `nil` when the area has no image, its image has no pixels, it has not appeared
yet, or rendering fails.

#### Scenario: App's own Confirm button
- **WHEN** the user has framed an image in a `CropArea` and the app calls `crop(outputSide: 840)`
- **THEN** it returns an 840 × 840 pixel image of the framed region, and the `CropArea` stays on screen with the same framing

#### Scenario: Same output as the ready-made screen
- **WHEN** a `CropArea` and a `CropImageView` of the same size show the same image with the same zoom and pan
- **THEN** `crop(outputSide:)` and `onCrop` deliver the same image for the same `outputSide`

#### Scenario: No image
- **WHEN** the `CropArea`'s image is `nil`
- **THEN** `crop(outputSide:)` returns `nil`

#### Scenario: Image without pixels
- **WHEN** the `CropArea`'s image has no pixels, such as `UIImage()`
- **THEN** `crop(outputSide:)` returns `nil`

#### Scenario: Before the area appears
- **WHEN** the app calls `crop(outputSide:)` before its `CropArea` has appeared
- **THEN** it returns `nil`
