## Why

`CropImageView` is a whole screen: its own navigation stack, an English title, and fixed
buttons. An app can't push it onto its own navigation stack, translate or change its
title, or put its own controls around the crop, such as the thirds grid, hint and Reset
button in Medal Wall's framing mock. Settling who owns the screen now, while Medal Wall
is the only app using the library, keeps every change in this proposal additive.

## What Changes

- **CropImage offers the pieces of a crop screen, and apps build their own screens from
  them:**
  - `CropArea`: the image with pinch and drag, the dimmed surround, and the circle or
    square hole. It fills the space the app gives it and has no navigation bar or
    buttons.
  - An optional thirds grid over the crop region (`showsGrid`).
  - `CropAreaViewModel`, an object the app creates and passes to `CropArea`. The app calls
    `crop(outputSide:)` from its own Confirm button to get the cropped image, and
    `reset()` from its own Reset button to return to the initial framing.
- **`CropImageView` stays** as the ready-made screen, built from the same pieces:
  - A new `title` parameter (`LocalizedStringKey`, default "Crop your photo"), looked
    up in the app's strings like SwiftUI's own titles.
  - Confirm is disabled until there is an image, so `onCrop` receives `nil` only when
    rendering fails. Its type stays `(UIImage?) -> Void`.
- **`CropShape` becomes `Sendable`.** It stays an enum.
- Not added: an `onCancel` callback (a sheet's `onDismiss` covers it, and apps that need
  more build their own screen), effects such as filters or background removal, and
  Medal Wall's mock styling.

Nothing here is **BREAKING**. Existing call sites compile unchanged. Disabling Confirm
without an image removes a tap that only ever delivered `nil`, so it ships as a minor
version: **1.1.0**, together with `outputSide`.

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `crop-interaction`: the crop screen's title and its Confirm button without an image;
  new requirements for `CropArea`, the thirds grid, and resetting the framing.
- `crop-output`: Confirm without an image; cropping through `CropAreaViewModel`, including
  the `outputSide` limit.

## Impact

- **Public API, all additive:** `CropArea`, `CropAreaViewModel`, `CropImageView`'s `title`
  parameter, and `Sendable` on `CropShape`.
- **Scope:** CropImage stays cropping only, meaning which part of the photo ends up in
  the crop and the output image. Effects live outside the library: in the app that needs
  them first, then in a library of their own once a second app does.
- **Code:** `CropImageViewModel` becomes the public `CropAreaViewModel`. `CropImageView`'s
  crop area moves into `CropArea`, and a grid view is added.
- **Medal Wall:** MW-38 moves to 1.1.0 after this change. Its current `CropImageView`
  call sites keep working. It can pass a translated title or build its framing screen
  from `CropArea`.
- **Docs:** README usage, and the overview and architecture notes in `CLAUDE.md`.
