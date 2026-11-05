# crop-interaction Specification

## Purpose
Let the user frame an image inside a fixed circle or square crop region by panning and
pinch-zooming, with the image always snapping back to cover the crop region, either in
the ready-made `CropImageView` or in an app's own screen built around `CropArea` and its
`CropAreaViewModel`.
## Requirements
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

### Requirement: Crop Region
The crop region SHALL be a square whose side is 75% of the smaller of the view's width
and height, capped at 400 pt, centered in the view. Everything outside the crop region
SHALL be dimmed with black at 50% opacity, and the hole SHALL take the shape given by
`cropShape`: a circle inscribed in the square for `.circle`, the full square for
`.square`. The dimming SHALL NOT intercept touches.

#### Scenario: Crop region on a phone
- **WHEN** the view is 402 pt wide and 724 pt tall
- **THEN** the crop region is 301.5 × 301.5 pt, centered in the view

#### Scenario: Crop region on a phone in landscape
- **WHEN** the view is 874 pt wide and 340 pt tall
- **THEN** the crop region is 255 × 255 pt, centered in the view, and fits inside it

#### Scenario: Crop region on a wide screen
- **WHEN** the view is 1032 pt wide and 1376 pt tall
- **THEN** the crop region is capped at 400 × 400 pt, centered in the view

#### Scenario: Circle shape
- **WHEN** `cropShape` is `.circle`
- **THEN** the undimmed hole is a circle with the crop region's side as its diameter

### Requirement: Initial Framing
The image SHALL initially be scaled to fill the whole view (not just the crop region),
centered, with no extra zoom or pan. An image that becomes available after the view is
created SHALL appear when it arrives.

#### Scenario: Image loads after the view appears
- **WHEN** `CropImageView` is created with a `nil` image and later receives a non-nil image
- **THEN** the image is shown, filling the view

### Requirement: Pan
Dragging the image SHALL move it with the drag, continuing from its current position.
When the drag ends, the zoom SHALL be raised to the smallest zoom at which the image
covers the crop region, if it is below that, and the pan SHALL be limited so the image
covers the whole crop region, both animated with a spring. Where the image is narrower or
shorter than the crop region, the pan limit SHALL center it on that axis.

#### Scenario: Drag past the edge
- **WHEN** the user drags the image so that an edge moves inside the crop region, then lifts the finger
- **THEN** the image springs back until that edge lines up with the crop region's edge

### Requirement: Pinch to Zoom
Pinching SHALL multiply the current zoom by the change in distance between the fingers,
so the zoom stays above zero and a single pinch can zoom in or out from any level. When
the pinch ends, the zoom SHALL be raised with a spring animation to the smallest zoom at
which the image covers the crop region, if it is below that, and the pan SHALL be
adjusted so the image still covers the crop region. There SHALL be no maximum zoom.

#### Scenario: Zoom out too far
- **WHEN** the user pinches the image smaller than the crop region, then lifts their fingers
- **THEN** the image springs back to the smallest zoom that covers the crop region

#### Scenario: Pinch again at the smallest zoom
- **WHEN** the image is at its smallest zoom and the user pinches their fingers to a quarter of their starting distance
- **THEN** while the fingers are down the image is shown at a quarter of that zoom, the right way up, and it springs back to the smallest zoom when they lift

#### Scenario: Zoom out from far in
- **WHEN** the zoom is 5× and the user pinches their fingers to half their starting distance, then lifts them
- **THEN** the zoom is 2.5×

#### Scenario: Zoom in
- **WHEN** the zoom is 3× and the user spreads their fingers to twice their starting distance, then lifts them
- **THEN** the zoom is 6×, and the pan is adjusted only if the crop region would otherwise be uncovered

### Requirement: Framing After a Size Change
When the view changes size, for example on rotation or an iPad window resize, or the app
passes an image of a different size, the zoom and pan SHALL be corrected as at the end of
a gesture: the zoom raised to the smallest zoom that covers the crop region if below it,
and the pan limited so the image covers it, animated with the same spring. Passing a new
image object of the same size SHALL leave the framing unchanged.

#### Scenario: Rotate after panning to an edge
- **WHEN** the user has panned the image to an edge of the crop region and the view then changes size
- **THEN** the image springs to cover the new crop region completely, with no gesture needed

#### Scenario: App passes a differently shaped image
- **WHEN** the user has zoomed out to the smallest zoom and the app then passes a taller image
- **THEN** the zoom rises until the new image covers the crop region

#### Scenario: App re-creates the same image
- **WHEN** the app passes a new image object with the same size, for example by decoding the same data again
- **THEN** the zoom and pan stay as the user left them

### Requirement: Interrupted Gesture
If the system cancels a drag or pinch before the user lifts their fingers, for example
for an incoming alert, the image SHALL spring back to the zoom and pan it had before that
gesture began.

#### Scenario: Alert interrupts a drag
- **WHEN** the user is dragging the image and a system alert cancels the gesture
- **THEN** the image springs back to where it was before the drag, and confirming crops that framing

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

