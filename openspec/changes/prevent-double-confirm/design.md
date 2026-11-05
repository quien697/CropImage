## Context

`CropImageView` holds a `CropAreaViewModel` in its `@State`. Its Confirm button calls
`onCrop(viewModel.crop(outputSide:))`, then `dismiss()`. `crop` renders synchronously on
the main thread, which can take a noticeable moment at a large `outputSide`, and nothing
stops the button's action from running again before the sheet has closed. A double tap
can't be unit tested, and the package has no UI test target, so the second call hasn't
been reproduced. The spec already says `onCrop` is called exactly once.

The content test compares crops with and without `outputSide` by reading both into
64 × 64 RGBA byte arrays with `colorSamples`. That helper writes into an array of zeros
through `context?`. If `CGContext` returns `nil`, both arrays stay zero, the mean
difference is 0, and the test passes without comparing anything. `centerAlpha` has the
same shape, but its tests expect 255, so a missing context already fails them.

## Goals / Non-Goals

**Goals:**
- `onCrop` runs at most once per `CropImageView` on screen, however fast the taps come.
- The guard has a unit test that fails without it.
- The content test fails when it can't read pixels.

**Non-Goals:**
- Guarding `CropAreaViewModel.crop(outputSide:)`. An app's own screen may crop more than
  once on purpose, and its buttons are the app's to guard.
- Rendering off the main thread, or showing progress while a large crop renders.
- Changing `centerAlpha`.

## Decisions

- **A `CropImageViewModel` for the ready-made screen** *(my call)*. It is internal,
  `@MainActor @Observable`, and owns the screen's `CropAreaViewModel`. Its
  `confirm(outputSide:onCrop:)` returns at once if Confirm was already tapped. Otherwise
  it marks Confirm as tapped, then calls `onCrop` with the crop. Its `canConfirm` is
  true while the area shows an image and Confirm wasn't tapped yet. `CropImageView` keeps
  it in `@State`, passes its area view model to `CropArea`, disables Confirm when
  `canConfirm` is false, and dismisses from the closure it passes to `confirm`, so an
  ignored tap doesn't dismiss again.
  - *Alternative:* a `@State` flag in `CropImageView`. It's a smaller change, but it puts
    logic in the view, which the project's style rules keep in view models, and it can't
    be unit tested, so the fix would rest on a check by hand.
  - *Alternative:* a flag on `CropAreaViewModel`. That would stop apps that build their
    own screen from cropping twice, which they may do on purpose.
- **Disable Confirm as well as guarding it.** The guard is what keeps `onCrop` to one
  call. Disabling the button also shows the tap was taken. `canConfirm` is unit tested,
  and the button can be checked in a preview: an unpresented `CropImageView` can't be
  dismissed, so the button stays on screen, greyed out.
- **`canConfirm` reads the image the area reported**, rather than the view's `image`, so
  the rule lives in the view model and can be tested. The two agree once the area has
  appeared, which happens before the user can tap.
- **The flag is set before `onCrop` runs**, so an `onCrop` that triggers another confirm
  while it runs still gets one call.
- **`colorSamples` throws.** It unwraps the context with `try #require`, so a missing
  context fails the test with a message, and its caller adds `try`. The test is already
  `throws`.
- **No new test for `colorSamples` itself.** It is test code, so the check is to break
  it on purpose: with a context that can't be created, the content test passes before
  the change and fails after it. Then the break is undone.

## Risks / Trade-offs

- [The double tap stays unreproduced] → The unit test proves the guard. The preview
  check shows that Confirm greys out after one tap.
- [An app shows `CropImageView` without presenting it, for example as a tab's root] →
  `dismiss()` can't close it, so it now delivers one crop and keeps Confirm disabled.
  Showing it without presenting it was never described, and an app that needs repeated
  crops can build its screen from `CropArea`.
- [`CropImageView` holds a view model inside a view model] → `@Observable` tracks the
  nested one through the reference, so the area still updates.
