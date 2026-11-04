## Why

Code review of `add-output-side` found that `CropImageView.init` checks only the upper
bound of `outputSide`. A zero or negative value gets through, `crop` builds a zero or
negative frame, and `onCrop` receives `nil` even though an image was shown, with nothing
telling the developer why. The review also found that no test checks what a crop with
`outputSide` contains, only its size.

## What Changes

- `CropImageView.init` also requires `outputSide` to be greater than 0. The precondition
  message names both bounds.
- Add a test that checks the content of a panned and zoomed crop with `outputSide`
  against the same crop without it, on a patterned image.
- Add the missing `///` doc comments to two existing tests.

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `crop-output`: the Output Size Limit requirement also rejects `outputSide` values of 0
  or less, and its precondition message changes.

## Impact

- Public API: no signature change. An app passing `outputSide` of 0 or less now stops
  with a precondition failure instead of receiving `nil`. Medal Wall, the only app using
  CropImage, passes 840.
- Code: `CropImageView.init`, `Tests/CropImageTests/CropImageViewModelTests.swift`.
