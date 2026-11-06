## 1. Tests first

- [x] 1.1 Add edge tests to `CropAreaViewModelTests`: an opaque square image at the smallest zoom in a 428 × 926 pt area, and an opaque 4:3 image at the smallest zoom and the pan limit in a 400 × 800 pt area, give fully opaque crops (they fail, with alphas of 128 and 244)
- [x] 1.2 Add an HDR test: a PQ image's crop keeps a linear value above 4 at its center (it fails, with 0.99)
- [x] 1.3 Add guard tests that already pass: a Display P3 red image's crop is still Display P3 red, and the crop differs by under 3 levels on average from a rendered `CropArea`'s crop region, rendered at 4 pixels per point, at three framings, for an image with `.right` orientation, and in a 402 × 874 pt area
- [x] 1.4 Add a test that a decoded JPEG's crop has an alpha channel (it fails once the crop is drawn in the JPEG's own opaque format), and keep the format's `opaque` false

## 2. Draw directly

- [x] 2.1 In `crop(outputSide:)`, replace `ImageRenderer` with `UIGraphicsImageRenderer`, drawing the image with `UIImage.draw(in:)` at the computed rectangle, in the image's `imageRendererFormat` at scale 1, with high-quality interpolation; the new tests and the full suite pass
- [x] 2.2 Drop the pan from the rectangle on purpose and confirm the area comparison test fails; undo it

## 3. Docs

- [x] 3.1 Rewrite the Rendering note in `CLAUDE.md`: the drawn rectangle, the comparison test in place of the copied chain, and why the 8192 px limit stays; reword the pixel-content advice in `.claude/rules/development-workflow.md` so it doesn't name `ImageRenderer`

## 4. Verify and finish

- [x] 4.1 Build and run the full test suite on an iOS simulator
- [x] 4.2 Code review against this change's spec delta
- [x] 4.3 Commit on `develop`, then archive this change
