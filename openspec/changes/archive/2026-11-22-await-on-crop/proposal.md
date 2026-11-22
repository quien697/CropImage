## Why

Apps often need to finish something with a crop before they can use it: check its size,
encode it, or upload it. Today `CropImageView` calls `onCrop` synchronously and closes as
soon as it returns, so any async work runs after the screen is gone. Meanwhile the user
can act on the app's screen (remove the photo, crop again, save), so the app has to guard
against results that arrive late. And a crop the app refuses, for example one too large
to upload, can only be reported after the screen has closed, so trying a tighter crop
means picking the photo again.

## What Changes

- `onCrop` becomes `@escaping (UIImage?) async throws -> Void`. CropImage still calls it
  from the main actor, so a closure written in a view can update that view's state, as
  today. Existing synchronous, non-throwing closures, and stored functions of the old
  type, still compile, with no new warnings, and behave as before.
- While `onCrop` runs, Confirm shows a progress indicator in place of its label, Close is
  disabled, swipe-to-dismiss is disabled, and the crop area ignores pan and pinch.
- When `onCrop` returns, the screen closes, as it does today.
- When `onCrop` throws, the screen stays open with the framing as the user left it, and
  Confirm is enabled again. The user can adjust the crop and confirm again, or close.
  CropImage shows no message of its own: the app presents its own error UI over the crop
  screen.
- One Confirm still delivers one crop: a tap while `onCrop` runs does nothing, and after
  `onCrop` returns Confirm stays disabled.
- `onCrop` must finish. While it runs, the user can't leave the screen.

Not included:
- An error alert or fallback message from CropImage. It can't know whether the app has
  already shown one, it would need its own localized strings, and it wouldn't match each
  app's error UI.
- Cancelling or timing out `onCrop`.
- Changes to `CropArea` or `CropAreaViewModel`. Apps that build their own screen already
  decide when it closes.

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `crop-output`: Confirm Delivers the Crop waits for `onCrop` before dismissing, keeps
  the view open when it throws, and allows another Confirm after a throw.
- `crop-interaction`: Crop Screen locks Close, swipe-to-dismiss and the crop area's
  gestures while `onCrop` runs, and shows progress in place of Confirm.

## Impact

- Public API: `CropImageView.init`'s `onCrop` parameter changes type. Nothing here is
  **BREAKING**: closure literals and function values of the old type convert to the new
  one, so existing call sites compile unchanged. It ships as a minor version, 2.1.0.
- Behavior: with a synchronous `onCrop`, the screen closes as before, after one hop to
  the next turn of the main actor.
- Code: `CropImageView`, `CropImageViewModel`, and their documentation.
- Tests: `CropImageViewModelTests`, `PublicAPITests`.
- Docs: README (the `CropImageView` section) and CLAUDE.md (the `CropImageView`
  architecture note).
