## Why

A review of the whole library found that `CropImageView`'s Confirm button calls `onCrop`,
then `dismiss()`, with nothing stopping a second tap. If a second tap lands before the
sheet closes, for example while a large `outputSide` is still rendering, `onCrop` runs
twice, though the spec says exactly once. It hasn't been reproduced: the package has no
UI test target. The same review found that the content test's `colorSamples` helper
ignores a drawing context it couldn't create, so both samples stay zero and the test
passes without checking anything.

## What Changes

- `CropImageView` delivers at most one crop per presentation: after the first Confirm
  tap, `onCrop` is not called again and Confirm is disabled.
- `colorSamples` in the tests fails the test when it can't create its drawing context,
  instead of returning zeros.

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `crop-output`: the Confirm Delivers the Crop requirement says Confirm is disabled after
  the first tap, with a scenario for a second tap before the view closes.

## Impact

- Public API: no change. Nothing here is **BREAKING**, and it ships in the next release
  with the rest of the review's fixes.
- Behavior: a `CropImageView` shown without being presented, which `dismiss()` can't
  close, now delivers one crop and then keeps Confirm disabled.
- Code: `CropImageView`, a new internal `CropImageViewModel`,
  `Tests/CropImageTests/CropAreaViewModelTests.swift`, and a new test file for the new
  view model.
- Docs: the `CropImageView` architecture note in `CLAUDE.md`.
