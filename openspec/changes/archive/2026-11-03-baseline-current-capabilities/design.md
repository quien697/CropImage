## Context

CropImage is a SwiftUI Swift package (iOS 26, Swift 6, MVVM, no dependencies) whose
only public API is `CropImageView` and `CropShape`. It has no OpenSpec baseline. This
change is documentation-only: it captures the behavior committed on `main` (`dcbd135`)
as specs, not new implementation.

## Goals / Non-Goals

**Goals:**
- One spec per capability that accurately reflects current behavior and can be checked
  against the code and the test suite.
- A baseline that future changes can diff against.

**Non-Goals:**
- No code changes, no bug fixes, no new features.
- No `outputSide`. It is uncommitted work, so it gets its own change and enters the
  specs when that change is archived.
- No requirements for internal types (`CropImageViewModel`, `CropGeometry`,
  `CropMaskView`, `CropShapeView`). Specs describe what an app using the library can
  observe, so internals can change without a spec delta.

## Decisions

- **Two capabilities, split at the `onCrop` boundary.** `crop-interaction` covers what
  the user sees and does; `crop-output` covers what the app receives. Changes to output
  sizing and changes to gestures or the mask tend to arrive separately, so each spec can be diffed on its own. The alternative, one `image-crop`
  spec, would put every change in one file.
- **Exact numbers are part of the contract** where an app can observe them (the crop
  region's side, scale 1 output, outward rounding to whole pixels), because apps size
  their layouts and uploads around them. Changing any of them is a spec change.

## Risks / Trade-offs

- [Spec drifts from code over time] → Any future change touching these capabilities
  must include a spec delta; review treats an undocumented behavior change as a spec
  gap.
- [Gesture behavior is specified from reading the code, not from tests] → The unit
  tests cover only `crop-output`. The `crop-interaction` requirements stick to what the
  code does directly and document nothing speculative.
