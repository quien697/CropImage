## Why

Apps that store or upload crops need a predictable pixel size. Today the cropped image is
the crop region's size in points at scale 1, so it depends on the device (302 px on an
iPhone 17 Pro, 400 px on an iPad) and is low resolution on every screen. An app
that needed crops of at least 840 px prompted this, but the option is designed for any
app.

## What Changes

- Add `outputSide: CGFloat? = nil` to `CropImageView.init`: the side, in pixels, of the
  square image `onCrop` receives.
- Render only the crop region instead of the whole view, so large outputs stay within
  `ImageRenderer`'s 8192 px limit instead of coming back as a blank image.
- Creating a `CropImageView` with `outputSide` above 8192 stops with a precondition failure.
- Without `outputSide`, the side now rounds up to whole pixels instead of outward, so a
  crop region that isn't a whole number of points can come out one pixel smaller than
  before (for example 301 px instead of 302 px for a 300.5 pt crop region in a 402 pt
  view).

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `crop-output`: adds a fixed output size and its limit; the default size rounds up
  instead of outward.

## Impact

- Public API: one new defaulted parameter on `CropImageView.init`. Existing call sites
  compile unchanged, so this is a minor version.
- Code: `CropImageViewModel.crop`, `CropImageView.init`, README usage.
- Adds the `CropImageTests` test target to `Package.swift`.
