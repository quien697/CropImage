## 1. Crop shape

- [x] 1.1 Write a test that passes a `CropShape` where `Sendable` is required (it fails to compile); then make `CropShape` `Sendable`

## 2. CropAreaViewModel

- [x] 2.1 Rename `CropImageViewModel` to `CropAreaViewModel`, and its test files to match, and make it `public final` with a public `init()`; the full suite passes with no behavior change
- [x] 2.2 Change the output tests to give the view model its image and area size, then call `crop(outputSide:)` (they fail to compile); then store both on the view model, derive the crop region from the size, and make the gesture and correction methods read the stored values
- [x] 2.3 Test that `crop(outputSide:)` returns `nil` without an image and before an area size is known; then guard it
- [x] 2.4 Test that `reset()` returns to zoom 1 with no pan and keeps the image; then implement it with the `.cropSettle` spring
- [x] 2.5 Add the `outputSide` precondition to `crop(outputSide:)` (no unit-testable surface: a precondition failure stops the test process, and exit tests don't run on iOS)

## 3. Views

- [x] 3.1 Move the crop area out of `CropImageView` into the public `CropArea(image:cropShape:viewModel:showsGrid:)`, which reports its image and size to the view model; add a `#Preview` of an app's own screen pushed onto a navigation stack, with its own title and Reset and Confirm buttons
- [x] 3.2 Add the thirds grid, clipped to the crop shape and ignoring touches; add `#Preview`s with the grid on a circle and on a square
- [x] 3.3 Rebuild `CropImageView` on `CropArea` and its own `CropAreaViewModel`, add the `title` parameter, and disable Confirm while `image` is `nil`; add `#Preview`s with a custom title and with no image
- [x] 3.4 Check by hand (no unit-testable surface): in the previews, the app's own screen, the grid on both shapes, Reset, the custom title, and the disabled Confirm; in Medal Wall, that its crop sheets work as before, and that passing `title: "Edit Photo"` (already in its catalog) shows the zh-TW translation with the app set to zh-TW

## 4. Docs

- [x] 4.1 Update the README: building your own screen with `CropArea` and `CropAreaViewModel`, the `title` parameter, the features and folder structure, and `from: "1.1.0"` in the installation snippet
- [x] 4.2 Update `CLAUDE.md`: cropping only as the library's scope, the public types, and the architecture notes

## 5. Verify and archive

- [x] 5.1 Build and run the full test suite on an iOS simulator
- [x] 5.2 Code review
- [ ] 5.3 Commit, archive this change, update both specs' Purpose to mention `CropArea` and `CropAreaViewModel`, then open the PR into `develop`
