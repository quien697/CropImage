## 1. Content test helper (D)

- [x] 1.1 Break `colorSamples` on purpose so its context can't be created, and confirm `cropWithOutputSideFramesTheSameContentAsWithout` still passes
- [x] 1.2 Make `colorSamples` throw, unwrapping its context with `try #require`, and add `try` at its call sites; with the break still in, the test now fails with a message; undo the break and the full suite passes

## 2. Confirm once (C1)

- [x] 2.1 Add `CropImageViewModelTests`: a second `confirm(outputSide:onCrop:)` doesn't call `onCrop` again, the first one delivers the area's crop, an `onCrop` that confirms again while it runs is still called once, and `canConfirm` is false without an image and after the first tap (they fail to compile)
- [x] 2.2 Add the internal `CropImageViewModel` in `ViewModels/CropImageViewModel.swift`: it owns a `CropAreaViewModel`, `confirm(outputSide:onCrop:)` delivers only the first time, and `canConfirm` says whether Confirm is enabled; the new tests pass
- [x] 2.3 Rebuild `CropImageView` on `CropImageViewModel`: pass its area view model to `CropArea`, call `confirm` from Confirm and dismiss from its closure, and disable Confirm when `canConfirm` is false; the full suite passes
- [x] 2.4 Check by hand (no unit-testable surface for a tap): in the "Circle crop" preview, which isn't presented, tap Confirm and see it grey out; in an app, confirming a crop sheet still delivers the crop and closes it

## 3. Docs

- [x] 3.1 Update the `CropImageView` architecture note in `CLAUDE.md`, and list `CropImageViewModel` among the internal types in `.claude/rules/development-workflow.md`

## 4. Verify and finish

- [x] 4.1 Build and run the full test suite on an iOS simulator
- [x] 4.2 Code review against this change's spec delta
- [ ] 4.3 Commit on `develop`, then archive this change
