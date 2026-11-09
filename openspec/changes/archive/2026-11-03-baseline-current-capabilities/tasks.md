## 1. Verify crop-interaction spec against code

- [x] 1.1 Confirm title, toolbar buttons, and close-without-`onCrop` match `CropImageView.body`
- [x] 1.2 Confirm crop region size (`min(width * 0.75, 400)`) and centering match `CropImageView.body`
- [x] 1.3 Confirm 50% black dimming, shaped hole, and no hit testing match `CropMaskView` and `CropShapeView`
- [x] 1.4 Confirm a late-arriving image shows, since `CropImageViewModel` does not store the image
- [x] 1.5 Confirm pan and zoom clamping on gesture end match `dragEnded`, `magnificationEnded`, and `CropGeometry`

## 2. Verify crop-output spec against code

- [x] 2.1 Confirm confirm-then-dismiss and `nil` results match `CropImageView.body` and `CropImageViewModel.crop`
- [x] 2.2 Confirm scale 1, outward rounding, and square output match `crop` on `main` (`cgImage.cropping(to:)`)

## 3. Finalize baseline

- [x] 3.1 Run `openspec validate baseline-current-capabilities` and resolve any errors
- [x] 3.2 Archive the change so specs land in `openspec/specs/`
