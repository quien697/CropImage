## MODIFIED Requirements

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
