## Context

`CropArea` shows the image with `.offset(viewModel.shownOffset(drag:))`, and `crop`
draws it at the view model's pan, with positive x to the right. In a right-to-left
layout SwiftUI flips a view's horizontal offset, so the two disagree.

Measured by rendering `CropArea` with `ImageRenderer` at 4 pixels per point in a
400 × 800 pt area at zoom 1.7, and comparing its crop region with `crop` (mean
difference per byte; correct framings give 0.2 to 1.5):

| Area shows | `crop` at | Difference |
|---|---|---|
| left-to-right, no pan | no pan | 0.00 |
| right-to-left, no pan | no pan | 0.00 |
| left-to-right, pan (40, −65) | (40, −65) | 0.21 |
| right-to-left, pan (40, −65) | (40, −65) | 35.50 |
| right-to-left, pan (40, −65) | (−40, −65) | 0.21 |

The image itself isn't mirrored on screen in a right-to-left layout, even one flagged
with `imageFlippedForRightToLeftLayoutDirection()`, and `crop` doesn't mirror it either.
A template image is drawn the same way on screen and in the crop (0.00). Neither needs
a change.

Whether the drag's translation is mirrored in a right-to-left layout today, so that the
image follows the finger, couldn't be measured: that needs a real touch, and the project
has no UI tests.

## Goals / Non-Goals

**Goals:**
- In a right-to-left layout, the crop is what the area shows.
- Dragging moves the image with the finger in either layout direction.

**Non-Goals:**
- Mirroring the photo for right-to-left layouts. A photo's left and right are where
  the camera saw them.
- Changing anything in a left-to-right layout.

## Decisions

- **Keep the image and its gestures left-to-right** (my call). `CropArea` sets the
  layout direction to left-to-right on the image after its gestures, so SwiftUI's
  right-to-left handling touches neither the pan shown nor the drag's translation, and
  the image behaves as in a left-to-right app, which `crop` already matches. This holds
  whether or not the drag is mirrored today.
  - *Alternative:* `CropArea` passes its layout direction to the view model and `crop`
    mirrors the pan in right-to-left layouts. The stored pan would mean different things
    in different layouts, and whether the image followed the finger would rest on the
    drag being mirrored, which is unmeasured.
  - *Alternative:* negate the offset's x on screen in right-to-left layouts. That undoes
    SwiftUI's flip by hand for the offset but leaves the drag in the mirrored layout.
- **Only the image changes direction.** The mask, grid and crop region are centered and
  symmetric, and `CropImageView`'s toolbar keeps following the app's layout.
- **Tests:** a right-to-left framing in `cropShowsWhatTheAreaShows` fails first (35.5).
  The drag has no unit-testable surface, so its direction is checked by hand in a
  "Right-to-left" preview of `CropArea`, which stays for later checks.

## Risks / Trade-offs

- [A modifier added later reads the layout direction outside the override] → The
  override wraps the whole image chain, and the right-to-left framing in the comparison
  test fails if the pan shown and `crop` disagree again.
- [The drag direction is checked only by hand] → Gestures have no unit-testable surface
  in this project. The "Right-to-left" preview keeps the check a drag away.
