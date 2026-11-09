## 1. Right-to-left pan

- [x] 1.1 Add a right-to-left framing to `cropShowsWhatTheAreaShows`: the pattern image at zoom 1.7 and pan (40, −65) in a 400 × 800 pt area, rendered with a right-to-left layout direction (it fails, with a difference of about 35.5)
- [x] 1.2 Keep `CropArea`'s image and its gestures left-to-right; the new framing passes, and so does the full suite
- [x] 1.3 Add a "Right-to-left" `#Preview` to `CropArea.swift` and check by hand in it (no unit-testable surface for a drag): dragging right moves the photo right

## 2. Docs

- [x] 2.1 Note in the `CropArea` architecture note in `CLAUDE.md` that the image and its gestures stay left-to-right, and why

## 3. Verify and finish

- [x] 3.1 Build and run the full test suite on an iOS simulator
- [x] 3.2 Code review against this change's spec delta
- [x] 3.3 Commit on `develop`, then archive this change
