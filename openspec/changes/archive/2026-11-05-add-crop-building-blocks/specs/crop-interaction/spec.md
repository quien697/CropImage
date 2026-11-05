## MODIFIED Requirements

### Requirement: Crop Screen
`CropImageView` SHALL present a `CropArea` in a navigation stack, titled with its `title`
parameter (inline title display). The title defaults to "Crop your photo" and SHALL be
looked up in the app's strings with the environment's locale. The screen SHALL have a
close button in the cancellation position and a confirm button in the confirmation
position, and SHALL show no thirds grid. The close button SHALL dismiss the view without
calling `onCrop`. The confirm button SHALL be disabled while `image` is `nil`.

#### Scenario: Close without cropping
- **WHEN** the user taps the close button
- **THEN** the view is dismissed and `onCrop` is not called

#### Scenario: Default title
- **WHEN** an app creates `CropImageView` without a `title`
- **THEN** the navigation title is "Crop your photo"

#### Scenario: Translated title
- **WHEN** an app passes the title "Frame your photo", its strings catalog has a zh-TW translation for it, and the environment's locale is zh-TW
- **THEN** the navigation title shows the zh-TW translation

## ADDED Requirements

### Requirement: Crop Area
`CropArea` SHALL show an image for cropping, with no navigation bar, title or buttons of
its own, filling the space the app gives it. It SHALL behave as described by the Crop
Region, Initial Framing, Pan, Pinch to Zoom, Framing After a Size Change and Interrupted
Gesture requirements, where "the view" means that space. The app SHALL pass it the
`CropAreaViewModel` that crops and resets it. One view model SHALL serve one `CropArea`.
The zoom and pan SHALL belong to the view model: an area given a view model that already
framed an image SHALL keep that framing until the app calls `reset()`, and an area given
a different view model SHALL pass it the area's size and image.

#### Scenario: App builds its own crop screen
- **WHEN** an app pushes a screen onto its own navigation stack that contains a `CropArea`, its own title and its own buttons
- **THEN** the screen appears with the app's title, buttons and back button, the user can pan and pinch the image inside the crop region, and no second navigation bar appears

#### Scenario: View model kept between visits
- **WHEN** an app keeps a `CropAreaViewModel` outside its crop screen, the user zooms and pans, leaves the screen, and opens it again
- **THEN** the image is shown with the same zoom and pan, and `reset()` returns it to the initial framing

#### Scenario: App swaps in a new view model
- **WHEN** an app replaces the `CropAreaViewModel` passed to a `CropArea` that is on screen with a new one
- **THEN** the image returns to the initial framing, and the new view model's `crop(outputSide:)` returns the framed image

#### Scenario: Same framing as the ready-made screen
- **WHEN** a `CropArea` and a `CropImageView` of the same size show the same image
- **THEN** both have the same crop region and the same initial framing

### Requirement: Thirds Grid
When `showsGrid` is `true`, `CropArea` SHALL draw two vertical and two horizontal lines
that divide the crop region into thirds. The lines SHALL be clipped to the crop shape,
drawn above the dimming, and SHALL NOT intercept touches. `showsGrid` SHALL default to
`false`. The grid SHALL NOT appear in the cropped image.

#### Scenario: Grid on a square crop
- **WHEN** `showsGrid` is `true` and `cropShape` is `.square`
- **THEN** the lines divide the crop region into nine equal squares

#### Scenario: Grid on a circle crop
- **WHEN** `showsGrid` is `true` and `cropShape` is `.circle`
- **THEN** the lines appear only inside the circle

#### Scenario: Grid off by default
- **WHEN** an app creates a `CropArea` without `showsGrid`
- **THEN** no grid is drawn

#### Scenario: Grid not in the output
- **WHEN** the grid is shown and the app crops
- **THEN** the cropped image contains no grid lines

### Requirement: Reset Framing
Calling `reset()` on a `CropAreaViewModel` SHALL return its `CropArea` to the initial
framing (scaled to fill the view, centered, no extra zoom or pan), animated with the same
spring as the end of a gesture. The image SHALL stay.

#### Scenario: Reset after zooming and panning
- **WHEN** the user has zoomed to 3× and panned, and the app calls `reset()`
- **THEN** the image springs back to fill the view, centered, and cropping then gives the initial framing
