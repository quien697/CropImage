## ADDED Requirements

### Requirement: Edges at the Zoom and Pan Limits
When the image's edge lines up with the crop region's edge, at the smallest zoom or at
the pan limit, the cropped image SHALL show the image right up to that edge, with no
partly transparent row or column.

#### Scenario: Zoomed out as far as it goes
- **WHEN** an opaque square image is zoomed out as far as it goes in a 428 × 926 pt view, so it just covers the crop region
- **THEN** every pixel of the cropped image is opaque

#### Scenario: Panned to the limit
- **WHEN** an opaque 4:3 image is zoomed out as far as it goes and panned as far as it goes in a 400 × 800 pt view
- **THEN** every pixel of the cropped image is opaque

### Requirement: Source Colors Kept
The cropped image SHALL keep the source image's colors. A wide-color image SHALL keep
its colors outside sRGB, and a high dynamic range image SHALL keep its highlights
brighter than standard white.

#### Scenario: Wide-color image
- **WHEN** the image is Display P3 and its colors are outside sRGB
- **THEN** the cropped image has the same colors

#### Scenario: High dynamic range image
- **WHEN** the image is high dynamic range, with highlights brighter than standard white
- **THEN** the cropped image keeps those highlights instead of clipping them to white
