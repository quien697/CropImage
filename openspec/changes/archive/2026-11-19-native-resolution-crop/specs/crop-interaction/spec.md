## MODIFIED Requirements

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
- **THEN** the image returns to the initial framing, and the new view model's `crop()` returns the framed image

#### Scenario: Same framing as the ready-made screen
- **WHEN** a `CropArea` and a `CropImageView` of the same size show the same image
- **THEN** both have the same crop region and the same initial framing
