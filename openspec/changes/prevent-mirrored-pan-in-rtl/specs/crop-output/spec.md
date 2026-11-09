## MODIFIED Requirements

### Requirement: Crop Content
The cropped image SHALL contain exactly what is inside the crop region as the user
framed it at the moment of confirming, including their pan and zoom. The image SHALL be
square for every `cropShape`: a `.circle` crop is not masked, so the area outside the
circle is included.

#### Scenario: Circle crop output
- **WHEN** the user confirms a `.circle` crop
- **THEN** `onCrop` receives the full square around the circle, with no transparent corners

#### Scenario: Right-to-left layout
- **WHEN** the app's layout is right-to-left and the user has panned the image
- **THEN** the cropped image shows what the crop region shows, panned the same way
