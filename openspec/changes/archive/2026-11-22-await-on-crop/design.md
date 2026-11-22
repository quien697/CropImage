## Context

`CropImageView` keeps an internal `CropImageViewModel` in `@State`. Its Confirm button
calls `viewModel.confirm { croppedImage in onCrop(croppedImage); dismiss() }`. `confirm`
returns at once if Confirm was already tapped; otherwise it sets `isConfirmed`, crops
synchronously with `areaViewModel.crop()`, and calls the closure. `canConfirm` is true
while the area has an image and `isConfirmed` is false, and disables Confirm. So the
screen closes in the same tap that delivers the crop, and anything the app starts from
`onCrop` finishes after the screen is gone.

`onCrop` is `(UIImage?) -> Void`. The package builds in Swift 6 language mode.

## Goals / Non-Goals

**Goals:**
- An app can do async work with the crop, and refuse it by throwing, before the screen
  closes.
- The screen is locked while that work runs: no second Confirm, no Close, no
  swipe-to-dismiss, no pan or pinch.
- A refused crop leaves the screen as the user left it, ready for another try.
- Every existing call site compiles unchanged and behaves as before.

**Non-Goals:**
- An error message from CropImage, cancelling `onCrop`, or a timeout.
- Changes to `CropArea` or `CropAreaViewModel`.
- Showing progress while the crop itself renders. It still renders synchronously at the
  tap, before the progress indicator can appear.

## Decisions

- **`onCrop: @escaping (UIImage?) async throws -> Void`.** Returning means "done,
  close"; throwing means "refused, stay open". CropImage calls it from the main actor. A
  closure written in a view inherits the view's main-actor isolation, so it can update
  the view's state and present the app's error without `await`, as today. Checked with
  the Swift 6.4 compiler: a closure literal, a stored synchronous function formed on the
  main actor, and a stored synchronous function formed in nonisolated code all run on the
  main thread, with no diagnostics.
  - *Alternative:* `@MainActor (UIImage?) async throws -> Void`. In Swift 6 a
    global-actor function type is `@Sendable`, so passing a stored non-`Sendable`
    `(UIImage?) -> Void` warns "converting non-Sendable function value … may introduce
    data races". That is a new warning at existing call sites, for no gain over
    inherited isolation.
  - *Alternative:* return a value, such as `Bool` or an enum, to say whether to close.
    Existing `{ result in … }` closures return `Void`, so they stop compiling:
    **BREAKING**.
  - *Alternative:* a second, defaulted `async` parameter beside the synchronous
    `onCrop`. That gives two ways to deliver the crop, and apps that stay on the old one
    keep the problem.
- **Source compatibility is tested, not assumed.** `PublicAPITests` creates
  `CropImageView` with a synchronous closure literal, with a stored
  `(UIImage?) -> Void` value, and with an async throwing closure that calls a main-actor
  method without `await`. They compile with no warnings. A call site that stopped
  compiling would make the change breaking.
- **`CropImageViewModel` tracks a confirm phase** *(my call)*: `ready`, `running`, `done`,
  replacing `isConfirmed`. `confirm(onCrop:)` becomes `async`. It returns at once unless
  the phase is `ready`. Otherwise it sets `running`, crops, and awaits the closure. When the closure returns, the phase becomes `done`; when it
  throws, the phase goes back to `ready` and the error is dropped. `canConfirm` is true
  only in `ready` with an image; `isLocked` is true outside `ready`.
  - `done` keeps the lock, so the progress indicator stays while the sheet slides away,
    rather than turning back into a disabled Confirm for the length of the animation.
  - The phase is set before the crop and before the await, so a tap while the closure
    runs, or an `onCrop` that confirms again, still finds it not `ready`.
  - `done` stays locked, so a `CropImageView` shown without being presented, which
    `dismiss()` can't close, still delivers one crop. It now keeps showing progress
    there, where 2.0 showed a disabled Confirm; showing it unpresented was never
    described.
  - The error is dropped because the app threw it from its own closure, so it already
    has it.
- **`CropImageView` dismisses from the closure it passes to `confirm`**, as today:
  `try await onCrop(croppedImage)` then `dismiss()`. A throw skips `dismiss()`, and an
  ignored tap never runs the closure. The button starts a `Task` on the main actor that
  awaits `confirm`. The task isn't cancelled when the view goes away, since `onCrop` is
  never cancelled.
  - *Alternative:* `.task(id:)` triggered by a state change. It adds a trigger value for
    no gain, and SwiftUI would cancel it if the view disappeared.
- **The screen locks itself from outside `CropArea`**, all driven by `isLocked`:
  - Confirm's toolbar item shows a `ProgressView` in place of the `Button(role: .confirm)`.
    Swapping the item keeps the system's confirm label, its accessibility label and its
    localization when the button is shown. *Alternative:* one button whose custom label
    switches between a checkmark and a `ProgressView`. It loses the system's label.
  - Close gets `.disabled(isLocked)`.
  - The `NavigationStack` gets `.interactiveDismissDisabled(isLocked)`, which the sheet
    presenting the view honors.
  - The `CropArea` gets `.allowsHitTesting(!isLocked)`, so touches don't reach its
    gestures. *Alternative:* a parameter on `CropArea`. It adds public API that only
    this screen needs.
- **The app handles its own errors.** CropImage stays open and shows nothing, and
  neither its API nor its previews say what an app's error looks like. The docs only
  point out that an `.alert` or `.sheet` the app attaches to `CropImageView`, inside its
  sheet content, appears over the crop screen; that is SwiftUI's behavior, so no API is
  needed and the spec doesn't describe it. The "Refused crop" `#Preview` only waits and
  throws, and serves as the check for the lock and for the screen coming back ready.

## Risks / Trade-offs

- [An `onCrop` that never finishes traps the user on the screen] → Documented on
  `onCrop`: it must finish, and an app that waits on the network sets its own timeout.
- [With a synchronous `onCrop`, the screen now closes one main-actor hop after the tap,
  and the progress indicator may show for a frame] → The sheet is already closing, so
  nothing visible changes in practice.
- [The app closes the screen itself while `onCrop` runs] → `onCrop` keeps running, and
  the `dismiss()` after it finds the screen already gone.
- [Close and Confirm fire in the same touch event, for example two fingers lifting at
  once] → Confirm's `Task` starts after both actions, so the screen closes and `onCrop`
  still runs, and a throw's alert has no screen to appear over. Starting the phase
  synchronously wouldn't help, since Close's `.disabled` applies only at the next render;
  closing it fully would need Close to go through the view model and a closed phase.
  2.0 already delivered a crop in this case, so it stays a known edge.
- [A compiler runs a stored synchronous `onCrop`, converted to the async type, off the
  main actor] → Swift 6 won't let `confirm` send the non-`Sendable` `onCrop` to another
  actor, so CropImage can't cause it. Only Swift 6.4 was checked; a characterization
  test fails on a toolchain that behaves otherwise.
- [A second finger is mid-gesture when Confirm is tapped] → The crop is taken from the
  settled framing at the tap. If that gesture then ends and moves the framing, the user
  moved it, and a throw leaves it where they put it. Checked by hand: a pinch under way
  when Confirm was tapped didn't move the framing that was cropped.
- [The app passes a different `image` while `onCrop` runs] → The framing settles for the
  new image, as Framing After a Size Change describes, so a throw no longer leaves the
  framing of the refused crop. The app changed the image itself, so this stays the
  app's call.
- [VoiceOver focus leaves Confirm when it becomes a `ProgressView`, which announces only
  that something is in progress] → Labelling it would need CropImage's own localized
  strings, which this change avoids; the progress indicator sits where Confirm was.
- [The lock, the progress indicator and swipe-to-dismiss have no unit-testable surface]
  → `isLocked` and `canConfirm` are unit tested; the toolbar, swipe and gestures are
  checked by hand in the preview.
