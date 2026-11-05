## Context

`CropImageView` is CropImage's only view: a `NavigationStack` around a `GeometryReader`
that shows the image, its gestures and the mask, with a hard-coded title and close and
confirm buttons. `CropImageViewModel` holds the settled zoom and pan and renders the
crop. The view passes the image and its own size into every view model call.

The app using the library today presents `CropImageView` as a sheet on four screens. It
ships in English and zh-TW with an in-app language setting, and types its own
components' titles as `LocalizedStringKey`, because a `String` title skips the strings
catalog. It plans its own crop screen later, with a thirds grid, a hint and a Reset
button, built from pieces this library offers.

## Goals / Non-Goals

**Goals:**
- An app can build its own crop screen around CropImage's crop area, with its own
  navigation, title, buttons and hint.
- The ready-made `CropImageView` keeps working for every existing call site and is built
  from the same pieces, so both paths behave the same.
- Every change is additive, shipping as 1.1.0 together with `outputSide`.

**Non-Goals:**
- **Effects** (filters, brightness, background removal). CropImage stays cropping only:
  which part of the photo ends up in the crop, and the output image. An effect starts in
  the app that needs it and becomes its own library once a second app needs it.
- An `onCancel` callback. A sheet's `onDismiss` covers it.
- An app's own styling of its crop screen, or a grid option on `CropImageView`.
- Shipping translations of the default title.
- Exposing the crop region's frame to the app, for example to place a hint next to it.
  This can be added later if an app needs it.
- Crop shapes beyond circle and square.
- Guarding Confirm against a double tap (C1 in the library review). Rebuilding the screen
  leaves that behavior as it is, and it gets its own small fix.

## Decisions

- **Building blocks plus a ready-made screen.** `CropArea` and `CropAreaViewModel` are
  public, and `CropImageView` becomes a navigation stack, title and two buttons around
  them.
  - *Alternative:* keep one screen and add options for the title, buttons, grid, cancel
    and push. Every new app need would become another option.
  - *Alternative:* remove `CropImageView`. That breaks every app that only wants a
    sheet.
- **`CropAreaViewModel` is the view model made public.** `CropImageViewModel` is renamed
  `CropAreaViewModel`, a `public final class` that stays `@MainActor @Observable`. Its
  public API is `init()`, `crop(outputSide:) -> UIImage?` and `reset()`. The settled
  framing and gesture math stay internal, so an app can't put the framing in a state
  the specs rule out, and the unit tests reach them through `@testable import`. Its
  test files are renamed to match.
  - *Alternative:* a public wrapper around the internal view model. That's a second
    type with nothing to do.
  - *Alternative:* a value the app binds, like `ScrollPosition`. Cropping needs the
    image and the area's size, and a value would make the view write its layout into
    the app's state.
- **`CropArea` reports its image and size to the view model.** The view model now stores
  the image and the area's size, and derives the crop region from the size. `CropArea`
  updates them when it appears and when they change. As today, the framing is
  corrected only when the area's size or the image's size changes. The gesture and
  correction methods read the stored values instead of taking them as arguments.
  `crop` returns `nil` until the area has appeared with an image. One view model serves
  one `CropArea`.
  - The area sends a new image by object identity, because `UIImage`'s `==` compares
    pixel data. It sends both values again when the app swaps in a different view model
    (found in code review).
  - The area computes the crop region for its mask from its current layout, with the same
    `CropGeometry.cropSize` the view model uses, instead of reading the view model's copy.
    That copy only updates after layout, so the hole would lag a frame on rotation and
    start at zero size.
- **The framing belongs to the view model.** An area given a view model that already
  framed an image keeps that framing until the app calls `reset()`, so an app can bring
  the user back to where they left off. The docs and the preview keep the view model in
  the crop screen's `@State`, so each visit starts at the initial framing and the photo
  is released with the screen (found in code review).
- **The output tests set the view model up as `CropArea` does**, so every crop region
  comes from an area size. That shows the scenario "a 300.5 pt crop region in a 402 pt
  wide view" can't happen, because a 402 pt view has a 301.5 pt crop region. It becomes
  a 407.2 pt wide view, whose 305.4 pt crop region still catches 1.0.0's outward
  rounding (307 px instead of 306).
- **`crop` uses the settled framing.** A gesture in progress lives in `CropArea`'s
  `@GestureState`, so a crop requested mid-gesture leaves that gesture out. That is the
  framing the user returns to if the gesture is cancelled. A Confirm tap can't happen
  mid-gesture with one hand, so the ready-made screen is unaffected.
- **`crop(outputSide:)` checks `outputSide`** with the same precondition and message as
  `CropImageView.init`, which keeps its own check, so a bad value still stops when the
  screen is created.
- **`reset()` returns to the initial framing**, zoom 1 and no pan, with the
  `.cropSettle` spring. The initial framing always covers the crop region, so it needs
  no correction. The image stays.
- **Thirds grid** *(my call on the look)*: `CropArea(showsGrid:)`, off by default. Two
  vertical and two horizontal one-pixel white lines at 50% opacity divide the crop
  region into thirds. The lines are clipped to the crop shape, drawn above the
  dimming, ignore touches, and stay visible the whole time. The grid is never part of
  the cropped image, because `crop` renders the image alone.
- **The title is a `LocalizedStringKey`**, default "Crop your photo", passed to
  `navigationTitle`. SwiftUI looks it up in the app's strings with the environment's
  locale, just like a title on one of the app's own screens. That also matches the
  title convention of the app using the library today. The default title stays English unless the
  app's catalog has that key, as today.
  - *Alternative:* `String`, which skips the catalog.
  - *Alternative:* translations bundled in the package, which would have to cover every
    app's languages.
- **Confirm is disabled while `image` is `nil`.** `onCrop` keeps the type
  `(UIImage?) -> Void`, so existing `if let` call sites compile, and its `nil` now
  means only that rendering failed.
- **Names**: `CropArea` is the area inside a crop screen rather than a screen, so it
  takes no `View` suffix *(my call)*. Its view model is `CropAreaViewModel`, named as a
  view and its view model, MVVM style *(the user's call, over `CropController`)*.
  `CropArea(image:cropShape:viewModel:showsGrid:)` uses the same `cropShape:` label as
  `CropImageView` *(my call)*.
- **`CropShape` becomes `Sendable`, and stays an enum.** Public types don't get
  `Sendable` inferred, so it has to be declared. Adding a case later breaks apps that
  `switch` over it, which means a major version. That's accepted: no app needs another
  shape yet, and a non-square shape would change the crop region and `outputSide`
  anyway.
  - *Alternative:* a struct with static members, to prepare for shapes no app has asked
    for.

## Risks / Trade-offs

- [An app calls `crop` before the area appears, or shares one view model between two
  areas] → `crop` returns `nil` before the area appears. One view model per area is
  documented on both types.
- [An app keeps the view model outside its crop screen] → It keeps the framing on
  purpose, and it holds the photo for as long as the app holds the view model. The docs,
  the README and the preview keep the view model in the crop screen's state.
- [An app sets a new photo and crops in the same action, before the area updates] →
  `crop` still sees the previous photo, as when cropping before the area appears. Users
  frame a new photo before confirming, so this needs an unusual sequence. Making the
  view model own the image would close it, at the cost of a bigger API (raised in code
  review, not changed).
- [The grid's look is fixed] → It's a framing aid, not styling. An app that wants
  another look turns it off. Exposing the crop region's frame would let it draw its
  own, but that's left until an app asks.
- [The default title is English unless the app translates it] → Same as today. Apps pass
  `title`, or add the key to their catalog.
- [Renaming the view model touches most test files] → The changes are mechanical, and
  the full suite runs after the rename, before any behavior changes.
- [Gestures, the grid and the screens have no unit-testable surface] → The view model is
  unit tested. The views are checked in `#Preview`s, and the ready-made screen is
  checked in an app.

## Migration Plan

No app migration is needed. After this merges into `develop`, release 1.1.0 from
`develop` into `main` with the tag `1.1.0`. It includes `outputSide`. Apps then move
to 1.1.0.
