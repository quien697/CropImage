## 1. Fill the crop's edges

- [x] 1.1 Add tests to `CropAreaViewModelTests`, with a helper that returns the lowest alpha in a crop and fails the test if it can't create its drawing context: a 375 pt wide area without `outputSide` gives 282 × 282 pixels, all opaque, and `outputSide` 840.4 gives 841 × 841 pixels, all opaque (both fail with an alpha of 0)
- [x] 1.2 In `crop(outputSide:)`, render `outputSide` or else the crop region's side, rounded up to whole pixels, with the layout scaled by that side over the crop region's side; the new tests and the full suite pass

## 2. Docs

- [x] 2.1 Say that a fractional side rounds up in the `outputSide` doc comments on `crop(outputSide:)` and `CropImageView.init`, and update the Rendering note in `CLAUDE.md`

## 3. Verify and finish

- [x] 3.1 Build and run the full test suite on an iOS simulator
- [x] 3.2 Code review against this change's spec delta
- [x] 3.3 Commit on `develop`, then archive this change
