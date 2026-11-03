# crop-interaction Specification

## Purpose
Let the user frame an image inside a fixed circle or square crop region by panning and
pinch-zooming, with the image always snapping back to cover the crop region.
## Requirements
### Requirement: Crop Screen
`CropImageView` SHALL present its content in a navigation stack titled "Crop your photo"
(inline title display), with a close button in the cancellation position and a confirm
button in the confirmation position. The close button SHALL dismiss the view without
calling `onCrop`.

#### Scenario: Close without cropping
- **WHEN** the user taps the close button
- **THEN** the view is dismissed and `onCrop` is not called

### Requirement: Crop Region
The crop region SHALL be a square whose side is 75% of the view's width, capped at
400 pt, centered in the view. Everything outside the crop region SHALL be dimmed with
black at 50% opacity, and the hole SHALL take the shape given by `cropShape`: a circle
inscribed in the square for `.circle`, the full square for `.square`. The dimming SHALL
NOT intercept touches.

#### Scenario: Crop region on a phone
- **WHEN** the view is 402 pt wide
- **THEN** the crop region is 301.5 × 301.5 pt, centered in the view

#### Scenario: Crop region on a wide screen
- **WHEN** the view is 1032 pt wide
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
When the drag ends, the image SHALL animate back with a spring so that it covers the
whole crop region, if the drag left any part of the crop region uncovered.

#### Scenario: Drag past the edge
- **WHEN** the user drags the image so that an edge moves inside the crop region, then lifts the finger
- **THEN** the image springs back until that edge lines up with the crop region's edge

### Requirement: Pinch to Zoom
Pinching SHALL zoom the image, continuing from its current zoom. When the pinch ends,
the zoom SHALL be raised with a spring animation to the smallest zoom at which the image
covers the crop region, if it is below that, and the pan SHALL be adjusted so the image
still covers the crop region. There SHALL be no maximum zoom.

#### Scenario: Zoom out too far
- **WHEN** the user pinches the image smaller than the crop region, then lifts their fingers
- **THEN** the image springs back to the smallest zoom that covers the crop region

#### Scenario: Zoom in
- **WHEN** the user pinches to enlarge the image, then lifts their fingers
- **THEN** the zoom is kept, and the pan is adjusted only if the crop region would otherwise be uncovered

