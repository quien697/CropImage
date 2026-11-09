## MODIFIED Requirements

### Requirement: Pan
Dragging the image SHALL move it with the drag, continuing from its current position.
When the drag ends, the zoom SHALL be raised to the smallest zoom at which the image
covers the crop region, if it is below that, and the pan SHALL be limited so the image
covers the whole crop region, both animated with a spring. Where the image is narrower or
shorter than the crop region, the pan limit SHALL center it on that axis.

#### Scenario: Drag past the edge
- **WHEN** the user drags the image so that an edge moves inside the crop region, then lifts the finger
- **THEN** the image springs back until that edge lines up with the crop region's edge

#### Scenario: Drag in a right-to-left layout
- **WHEN** the app's layout is right-to-left and the user drags the image to the right
- **THEN** the image moves right with the finger, as in a left-to-right layout
