## 1. Geometry

- [x] 1.1 Test `CropGeometry.cropSize(containerSize:)`: 402 × 724 gives 301.5, 874 × 340 gives 255, 1032 × 1376 gives 400; then implement it and use it in `CropImageView`
- [x] 1.2 Test that `CropGeometry.clampOffset` centers an axis where the image is smaller than the crop region; then make a negative limit count as 0
- [x] 1.3 Test `CropGeometry.minimumScale(cropSize:renderedSize:)` with hand-computed values; then move the calculation out of the view model into it

## 2. View model gesture math

- [x] 2.1 Test that ending a pinch multiplies the settled zoom (3 × 2 gives 6, 5 × 0.5 gives 2.5) and that the shown zoom stays above zero at the smallest zoom; then replace `lastScale` with multiplication
- [x] 2.2 Test that ending a drag adds the translation to the settled pan and limits it; then replace `lastOffset` with settled values plus a translation
- [x] 2.3 Test that `settle` raises a zoom below the minimum and limits the pan for new view sizes (a portrait framing checked against a landscape view)
- [x] 2.4 Test that `settle` leaves the framing alone for an empty view or image; then guard it

## 3. View wiring

- [x] 3.1 Track the drag translation and pinch magnification in `@GestureState`, reset with the settle spring, and show the settled framing combined with them
- [x] 3.2 Replace `MagnificationGesture` with `MagnifyGesture`
- [x] 3.3 Call `settle` when the view's size or the image's size changes (reset on a new image object was dropped after code review)
- [x] 3.4 Update the architecture notes in `CLAUDE.md` (crop region formula, gesture state)
- [x] 3.5 Check the gestures by hand in an app (no unit-testable surface): pinch again at the smallest zoom, zoom out from far in, drag past an edge, and interrupt a drag

## 4. Verify and archive

- [x] 4.1 Build and run the full test suite on an iOS simulator
- [x] 4.2 Code review
- [x] 4.3 Commit, archive this change, then open the PR into `develop`
