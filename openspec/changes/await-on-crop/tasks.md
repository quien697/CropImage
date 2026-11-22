## 1. Async `onCrop` for every call site

- [x] 1.1 In `PublicAPITests`, create `CropImageView` with a stored `(UIImage?) -> Void` value and with an async throwing closure that calls a main-actor method without `await`, beside today's synchronous closure literal (the async one fails to compile against today's `onCrop`)
- [x] 1.2 Make `onCrop` `@escaping (UIImage?) async throws -> Void`. Make `CropImageViewModel.confirm(onCrop:)` `async`, taking a closure of that type and dropping its error. Make Confirm start a main-actor `Task` that awaits `confirm` with a closure that awaits `onCrop`, then dismisses. Add `await` to `CropImageViewModelTests`. The full suite passes, and the call sites from 1.1 build with no warnings

## 2. Confirm phase

- [x] 2.1 Add `CropImageViewModelTests` (they fail): while `onCrop` waits on a gate the test opens, `isLocked` is true, `canConfirm` is false, and a second `confirm` doesn't call `onCrop`; after `onCrop` returns, `isLocked` stays true and `canConfirm` false, and another `confirm` doesn't call it; after `onCrop` throws, `isLocked` is false, `canConfirm` is true, and the area's `scale` and `offset` are unchanged; after a throw and a pinch to three times the zoom, `confirm` calls `onCrop` again with the crop of the new framing (375 px, then 125 px, worked out by hand)
- [x] 2.2 Replace `isConfirmed` with the `ready` / `running` / `done` phase that `design.md` describes, and add `isLocked`, true outside `ready`. The new tests pass, and so does `confirmingFromOnCropDeliversOneCrop`

## 3. Lock the screen

- [x] 3.1 Drive `CropImageView` from `isLocked`: Confirm's toolbar item shows a `ProgressView` in place of the button, Close gets `.disabled`, the `NavigationStack` gets `.interactiveDismissDisabled`, and the `CropArea` gets `.allowsHitTesting(false)`. No unit-testable surface: checked in 3.3
- [x] 3.2 Add two `#if DEBUG` previews that present `CropImageView` in a sheet from a button: "Slow confirm", whose `onCrop` waits two seconds and returns, and "Refused crop", whose `onCrop` waits two seconds, then throws. The previews show no error UI: that belongs to the app
- [x] 3.3 Check by hand, in the previews or a throwaway demo app outside the repo: while `onCrop` waits, Confirm shows a progress indicator, Close is disabled, swiping the sheet down doesn't close it, and drag and pinch don't move the image. "Slow confirm" closes after the wait. After "Refused crop" throws, the framing is unchanged, Confirm, Close, swipe, drag and pinch work again, and confirming again waits again. A pinch still in progress when Confirm is tapped doesn't move the framing that was cropped

## 4. Docs

- [x] 4.1 Update the documentation of `CropImageView` and its `onCrop` parameter: it runs on the main actor, the screen stays open and locked until it returns, throwing keeps the screen open for another try, the app shows its own error by attaching it to `CropImageView`, and it must finish, so an app waiting on the network sets its own timeout
- [x] 4.2 README: in the `CropImageView` section, add an example whose `onCrop` checks or uploads the crop and throws to refuse it, leaving the error UI to the app, with a note that UI attached to `CropImageView` appears over the crop screen
- [x] 4.3 CLAUDE.md: update the `CropImageView` architecture note (the confirm phase, the lock, and dismissing when `onCrop` returns)

## 5. Verify and finish

- [x] 5.1 Build and run the full test suite on an iOS simulator
- [x] 5.2 Code review against this change's spec delta
- [x] 5.2.1 From the review: keep the lock after `onCrop` returns, so progress stays while the sheet closes; fix the README example so every thrown error gets a message; say that a `nonisolated` async `onCrop` runs with its own isolation; add a time limit to the gated test; add a characterization test that a stored synchronous `onCrop` runs on the main thread
- [x] 5.2.2 From the second review: test that a synchronous `onCrop` closure still calls an app's synchronous overload, check that Confirm after `onCrop` returns does nothing, rewrap the `onCrop` documentation, and record in `design.md` the risks left as they are (an image swapped while `onCrop` runs, VoiceOver focus on the progress indicator)
- [ ] 5.3 Commit on `feature/await-on-crop`, then archive this change
- [ ] 5.4 Open a PR into `develop`
