## 1. Output size limit

- [x] 1.1 Extend the precondition in `CropImageView.init` to `outputSide > 0 && outputSide <= 8192` with the message "outputSide must be greater than 0 and at most 8192 pixels" (no unit test: Swift Testing exit tests aren't available on iOS)
- [x] 1.2 Update the `outputSide` doc comment in `CropImageView.init` to state both bounds

## 2. Crop content test

- [x] 2.1 Add a test that crops a patterned image with zoom and pan, without `outputSide` and with it at 3×, and requires the mean difference on a sampled grid to stay under 10
- [x] 2.2 Confirm the test fails when the pan is left unscaled in `crop`, then restore the code

## 3. Doc comments

- [x] 3.1 Add `///` doc comments to `cropWithoutOutputSideIsTheCropSideAtScaleOne` and `cropWithOutputSideIsThatManyPixelsSquare`

## 4. Verify and archive

- [x] 4.1 Build and run the full test suite on an iOS simulator
- [ ] 4.2 Commit, then archive this change so the delta lands in `openspec/specs/crop-output`
