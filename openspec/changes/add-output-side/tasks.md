## 1. Fixed output size

- [x] 1.1 Add `outputSide` to `CropImageView.init` and pass it to `CropImageViewModel.crop`
- [x] 1.2 Test that `outputSide` 840 gives exactly 840 × 840 px at scale 1, including on a 301.5 pt crop region
- [x] 1.3 Write a failing test that 4096 px on an iPad-sized view is not blank, then render only the crop region with a scaled layout to pass it
- [x] 1.4 Confirm the new rendering frames the same content as `main`'s, on a patterned image with zoom and pan

## 2. Output size limit

- [x] 2.1 Add the 8192 precondition to `CropImageView.init` (no unit test: Swift Testing exit tests aren't available on iOS)

## 3. Default output size

- [x] 3.1 Test that a 300.5 pt crop region in a 402 pt view gives 301 × 301 px (302 px on `main`)

## 4. Docs

- [x] 4.1 Document `outputSide` in the `CropImageView.init` doc comment and the README

## 5. Verify and archive

- [x] 5.1 Build and run the full test suite on an iOS simulator
- [ ] 5.2 Commit, then archive this change so the delta lands in `openspec/specs/crop-output`
