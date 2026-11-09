## 1. Image without pixels

- [x] 1.1 Add `cropOfAnImageWithoutPixelsIsNil` to `CropAreaViewModelTests`: a view model showing `UIImage()` in a 400 × 800 pt area returns `nil` from `crop()` and `crop(outputSide: 840)` (it fails, getting a blank square)
- [x] 1.2 Add `confirmIsUnavailableForAnImageWithoutPixels` to `CropImageViewModelTests` (it fails, with Confirm enabled)
- [x] 1.3 Store an image without pixels as `nil` in `imageChanged(to:)`, remove `settle`'s own check, and update the documentation of `crop(outputSide:)` and `CropImageView.init`; the new tests pass, and so does the full suite

## 2. Verify and finish

- [x] 2.1 Build and run the full test suite on an iOS simulator
- [x] 2.2 Code review against this change's spec delta
- [ ] 2.3 Commit on `develop`, then archive this change
