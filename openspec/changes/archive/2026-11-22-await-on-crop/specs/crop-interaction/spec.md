## MODIFIED Requirements

### Requirement: Crop Screen
`CropImageView` SHALL present a `CropArea` in a navigation stack, titled with its `title`
parameter (inline title display). The title defaults to "Crop your photo" and SHALL be
looked up in the app's strings with the environment's locale. The screen SHALL have a
close button in the cancellation position and a confirm button in the confirmation
position, and SHALL show no thirds grid. The close button SHALL dismiss the view without
calling `onCrop`. The confirm button SHALL be disabled while `image` is `nil`. While
`onCrop` runs, the confirm button SHALL show a progress indicator in place of its label,
the close button SHALL be disabled, swiping down a sheet that presents the view SHALL NOT
dismiss it, and the crop area SHALL ignore pan and pinch. After `onCrop` returns, all of
them SHALL stay so while the view closes. When `onCrop` throws, the confirm button SHALL
show its label again, and the close button, swipe-to-dismiss, pan and pinch SHALL work
again.

#### Scenario: Close without cropping
- **WHEN** the user taps the close button
- **THEN** the view is dismissed and `onCrop` is not called

#### Scenario: Default title
- **WHEN** an app creates `CropImageView` without a `title`
- **THEN** the navigation title is "Crop your photo"

#### Scenario: Translated title
- **WHEN** an app passes the title "Frame your photo", its strings catalog has a zh-TW translation for it, and the environment's locale is zh-TW
- **THEN** the navigation title shows the zh-TW translation

#### Scenario: Screen while onCrop runs
- **WHEN** the user has tapped the confirm button of a `CropImageView` presented in a sheet, and `onCrop` is still running
- **THEN** the confirm button shows a progress indicator, the close button is disabled, swiping the sheet down doesn't dismiss it, and dragging or pinching doesn't move the image

#### Scenario: Screen after onCrop returns
- **WHEN** `onCrop` returns and the sheet starts to close
- **THEN** the confirm button keeps showing the progress indicator while the sheet slides away

#### Scenario: Screen after onCrop throws
- **WHEN** `onCrop` throws
- **THEN** the confirm button shows its label and is enabled, the close button dismisses the view, swiping the sheet down dismisses it, and the user can pan and pinch the image
