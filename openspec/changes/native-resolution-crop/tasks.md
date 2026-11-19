## 1. Remove `outputSide`

- [x] 1.1 Remove `outputSide` from `CropImageView` (stored property, `init` parameter, precondition, documentation), make `CropImageViewModel.confirm(outputSide:onCrop:)` `confirm(onCrop:)`, and make `CropAreaViewModel.crop(outputSide:)` `crop()` without its precondition. The default size stays as today for now. Update the `CropArea` preview (`crop(outputSide: 840)`) and the doc comments in `CropArea` and `CropAreaViewModel` that name `crop(outputSide:)`
- [x] 1.2 Delete the tests of `outputSide` in `CropAreaViewModelTests`: `cropWithOutputSideIsThatManyPixelsSquare`, `cropWithOutputSideIsExactOnAFractionalCropSide`, `cropWithAFractionalOutputSideRoundsUpAndFillsIt`, `cropWithALargeOutputSideOnAnIPadIsNotBlank` and `cropWithOutputSideFramesTheSameContentAsWithout`. Drop the `crop(outputSide: 840)` checks from the three `nil` tests. Make `cropShowsWhatTheAreaShows` call `crop()`, `CropImageViewModelTests` call `confirm(onCrop:)` and compare with `crop()`, and `PublicAPITests` call `crop()`
- [x] 1.3 Build and run the full suite: it passes, with no `outputSide` left in `Sources/`, and in `Tests/` only in the names of the three size tests 3.1 replaces

## 2. Crop rectangle in source pixels

- [x] 2.1 Add tests to `CropGeometryTests` for a pure `CropGeometry` function that takes the source's pixel size, the rendered size, the zoom, the pan and the crop region, and returns the crop's rectangle in whole source pixels (they fail: the function doesn't exist). Cases for a 1200 × 1200 px source rendered at 800 × 800 pt with a 300 pt crop region:
  - zoom 1 and no pan gives side 450 at origin (375, 375)
  - pan (40, −60) gives origin (315, 465)
  - zoom 0.375 gives the whole source, (0, 0, 1200, 1200)
  - a side covering 413.96 px rounds to 414
  - zoom 10000 gives side 1
  - an origin that rounding would push past the source's edge is clamped inside it
- [x] 2.2 Implement the function as `design.md` describes; the new tests pass

## 3. Full-resolution crop

- [x] 3.1 In `CropAreaViewModelTests`, replace `cropWithoutOutputSideIsTheCropSideAtScaleOne`, `cropWithoutOutputSideRoundsAFractionalSideUp` and `cropWithoutOutputSideFillsAFractionalSidesEdges` with the Output Size scenarios. A 1200 × 1200 px image gives 450 px at the initial framing in a 400 × 800 pt area, 225 px at twice that zoom, 1200 px zoomed out as far as it goes, and 414 px in a 402 × 874 pt area (opaque to its edges). A 400 × 400 pt image at scale 3 gives 450 px. Extreme zoom gives 1 × 1 px. Every crop is at scale 1. They fail against today's crop
- [x] 3.2 Add a test where a single-pixel black-and-white checkerboard, zoomed and panned, crops to pixels that are all pure black or white, with every horizontal and vertical neighbor different (it fails: today's crop resamples)
- [x] 3.3 Rewrite `crop()` to draw the whole image at its pixel size, offset by the snapped origin from 2.2, on a `side × side` canvas at scale 1 with `interpolationQuality` `.none`, as `design.md` describes. The new tests pass, and so do the content, edge, alpha, wide color, HDR and `cropShowsWhatTheAreaShows` tests
- [x] 3.4 Update the documentation of `crop()` and `CropImageView.init` (the `onCrop` image) to describe the full-resolution output

## 4. Docs

- [x] 4.1 README:
  - The feature list's "Fixed output size" becomes full resolution
  - The comparison table's `crop(outputSide:)` becomes `crop()`
  - Replace the output size section and its `outputSide: 1024` example with full resolution, noting that apps which upload or store crops should resize them
  - Fix the `CropArea` section's `crop(outputSide:)` mentions and its `crop(outputSide: 840)` example
- [x] 4.2 CLAUDE.md:
  - The public API list (`crop()`)
  - `CropImageView` ("crops with `outputSide`")
  - The Rendering paragraph: source pixels snapped to whole pixels and drawn 1:1, no `outputSide`, no 8192 px precondition
  - `.claude/rules/development-workflow.md`'s `crop(outputSide:)` mention

## 5. Verify and finish

- [x] 5.1 Build and run the full test suite on an iOS simulator
- [x] 5.2 Code review against this change's spec delta
- [ ] 5.3 Commit on `feature/native-resolution-crop`, archive this change, and rewrite the `crop-output` spec's Purpose, which still names `outputSide` and the 8192 limit
- [ ] 5.4 Open a PR into `develop`
