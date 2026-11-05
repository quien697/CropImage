## MODIFIED Requirements

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
