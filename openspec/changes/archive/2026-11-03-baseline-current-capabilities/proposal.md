## Why

CropImage is a public library used by several apps, but there is no written record of
the behavior those apps rely on, so a future change has nothing to diff against and a
behavior change can slip through review unnoticed. This change records the current,
already-implemented behavior as the starting baseline. It does not change any code.

## What Changes

- Document the behavior on `main` of the two capabilities `CropImageView` provides as
  OpenSpec specs. The in-progress `outputSide` option is not part of the baseline; it is
  its own change.
- No code changes. No behavior changes. This is a documentation-only baseline.

## Capabilities

### New Capabilities
- `crop-interaction`: Presenting the cropper and framing the image: the crop region and
  its circle or square mask, pan and pinch-to-zoom, and snapping back so the crop
  region is always covered.
- `crop-output`: The image `onCrop` receives: when it is `nil`, what it contains, its
  size, and its scale.

### Modified Capabilities
(none — no existing specs to modify; this is the first baseline)

## Impact

None to running code or to the public API. Establishes
`openspec/specs/{crop-interaction,crop-output}` as the baseline that future changes
diff against.
