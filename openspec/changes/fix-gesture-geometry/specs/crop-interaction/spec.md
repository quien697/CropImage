## MODIFIED Requirements

### Requirement: Crop Region
The crop region SHALL be a square whose side is 75% of the smaller of the view's width
and height, capped at 400 pt, centered in the view. Everything outside the crop region
SHALL be dimmed with black at 50% opacity, and the hole SHALL take the shape given by
`cropShape`: a circle inscribed in the square for `.circle`, the full square for
`.square`. The dimming SHALL NOT intercept touches.

#### Scenario: Crop region on a phone in portrait
- **WHEN** the view is 402 pt wide and 724 pt tall
- **THEN** the crop region is 301.5 × 301.5 pt, centered in the view

#### Scenario: Crop region on a phone in landscape
- **WHEN** the view is 874 pt wide and 340 pt tall
- **THEN** the crop region is 255 × 255 pt, centered in the view, and fits inside it

#### Scenario: Crop region on a large screen
- **WHEN** the view is 1032 pt wide and 1376 pt tall
- **THEN** the crop region is capped at 400 × 400 pt, centered in the view

#### Scenario: Circle shape
- **WHEN** `cropShape` is `.circle`
- **THEN** the undimmed hole is a circle with the crop region's side as its diameter

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

## ADDED Requirements

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
