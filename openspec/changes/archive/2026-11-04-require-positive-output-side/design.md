## Context

`add-output-side` added `outputSide` with a precondition of `outputSide <= 8192` in
`CropImageView.init`. Code review found two gaps: values of 0 or less pass the
precondition and silently produce `onCrop(nil)`, and the tests use a solid-color image
with no pan or zoom, so they can't tell whether a crop shows the right part of the image.

## Goals / Non-Goals

**Goals:**
- Reject every `outputSide` that can't produce an image, at the moment the view is created.
- A test that fails if the `outputSide` render frames a different region than the
  default render.

**Non-Goals:**
- Changing `outputSide` to `Int`. It stays `CGFloat`.
- Guarding a zero-width crop region inside `crop`. The view lays out before the confirm
  button can be tapped, and the result is still `nil`, as on `main`.

## Decisions

- **One precondition covering both bounds**: `outputSide > 0 && outputSide <= 8192`,
  with the message "outputSide must be greater than 0 and at most 8192 pixels". No
  separate `isFinite` check: NaN fails both comparisons and +infinity fails the upper
  bound, so the two comparisons already reject every non-finite value.
- **Content test compares two renders of the same framing.** It crops a patterned image
  with zoom and pan once without `outputSide` and once with it at 3×, scales both to the
  same small grid, and requires the colors to match. Alternative: check exact pixel
  colors at hand-computed positions, which repeats the layout math the test is meant to
  check. Comparing the two renders checks the `outputSide` scaling directly.
- **Compare the mean difference, not a count of differing samples.** Both images are
  sampled on a 64 × 64 grid and the mean difference per byte must be under 10 out of
  255. A first version counted samples that differed and failed on correct code:
  whole rows of samples landed on the antialiased edges between squares, which blend
  differently at each output size. The mean stays under 1 on correct code and rises
  to about 57 when the pan is left unscaled, so 10 leaves a wide margin either way.

## Risks / Trade-offs

- [The precondition can't be unit tested] → Swift Testing exit tests aren't available on
  iOS, so it is checked by review, as in `add-output-side`.
- [The content test only proves the `outputSide` render matches the default render] →
  The default render is checked by hand against what's on screen, and by the earlier
  comparison with `main`'s implementation.
