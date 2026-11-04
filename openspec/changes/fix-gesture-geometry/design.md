## Context

`CropImageViewModel` stores live gesture values directly in `scale` and `offset`, updated
on every gesture change, with `lastScale` and `lastOffset` as bookkeeping. Pinching sets
`scale = value + lastScale` with `lastScale = clampedScale - 1`, which only behaves like
multiplication at zoom 1. Corrections run only in a gesture's `onEnded`, which SwiftUI
skips when it cancels a gesture, and nothing re-runs them when the view or image changes.
The crop region's size is computed in `CropImageView.body` from the width alone.

## Goals / Non-Goals

**Goals:**
- The zoom and pan the user sees, and the ones `crop` renders, always describe an image
  that covers the crop region once no gesture is in progress.
- Pinching behaves like a standard pinch: proportional, never flipping.
- The crop region fits inside the view in any orientation.
- The geometry and gesture math are covered by plain unit tests.

**Non-Goals:**
- Panning and pinching at the same time, or zooming around the pinch point (A6 in the
  review). Medal Wall's users have no problem with the current gestures.
- A maximum zoom.
- Right-to-left layouts. The review's concern is unconfirmed and gets its own change if
  confirmed.

## Decisions

- **Settled framing in the view model, in-flight gesture values in `@GestureState`.**
  `scale` and `offset` hold only the settled framing. The view keeps the current drag
  translation and pinch magnification in `@GestureState`, which SwiftUI resets on both end
  and cancellation, and shows `scale × magnification` and `offset + translation`. On end,
  the view model folds the gesture into the settled framing and corrects it. On
  cancellation it does nothing, so the image returns to the settled framing. Both
  `@GestureState` values reset with the same spring as the correction, so a cancelled
  gesture springs back rather than jumping. Alternative:
  keep live values in the view model and detect cancellation separately, which needs
  extra state and still leaves a window where `crop` sees unsettled values.
- **One correction for every trigger.** A single `settle` raises the zoom to the smallest
  zoom that covers the crop region, then limits the pan. It runs when a drag or pinch
  ends and when the view changes size, always with the existing spring. Previously the
  end of a drag limited the pan without checking the zoom, which is how the pan limit
  could go negative.
- **Commit the gesture without animation, correct with animation, reset with the same
  spring.** On end, the view model first adds the gesture to the settled values, which
  matches what is on screen as the `@GestureState` resets, then animates the correction.
  The reset and the correction land in the same frame, and SwiftUI doesn't document how
  it orders their transactions; giving the reset the same spring (`Animation.cropSettle`)
  makes every order end on the same smooth spring instead of a possible jump.
- **Pan limit never negative.** `CropGeometry.clampOffset` treats a negative limit as 0,
  centering the image on that axis. After `settle` raises the zoom first this cannot
  happen, but the function stays correct on its own.
- **Crop region from the smaller side**: `min(min(width, height) × 0.75, 400)`, moved into
  `CropGeometry` so it can be tested. Portrait iPhone (402 × 724 pt) still gives 301.5 pt.
- **Settle when the image's size changes, not when its object changes.** An app may build
  a new `UIImage` for the same picture on every render (for example `UIImage(data:)` in
  its body), and a freed image's address can be reused for a new one, so object identity
  would both reset the user's framing mid-crop and miss real swaps. The size is what the
  framing depends on: a different size is corrected by `settle`, and the same size needs
  no change. Alternative considered first: resetting to the initial framing on a new
  object, dropped for those reasons after code review.
- **`settle` skips an empty view or image.** It now also runs when the view changes size,
  and a view without a size yet, or a `UIImage()` placeholder, would make it compute an
  aspect ratio from 0 / 0. NaN then leaks into the framing through Swift's `max`, which
  keeps or drops NaN depending on argument order. So `settle` returns early when the view
  or the image has no area.
- **`MagnifyGesture`** replaces the deprecated `MagnificationGesture`; its `magnification`
  value has the same meaning.

## Risks / Trade-offs

- [Gesture wiring has no unit-testable surface] → The math it calls is unit tested; the
  wiring is checked by hand in Medal Wall.
- [Pinching feels faster at high zoom than before] → That is the fix: at 3×, spreading the
  fingers to twice their distance now gives 6× rather than 4×, proportional as in Photos.
  Zooming still centers on the image rather than the pinch point (A6, out of scope).
- [A different photo of the same size keeps the old framing] → It still covers the crop
  region; apps that want a fresh framing for a new photo can give the view a new
  identity with `.id(...)`.
