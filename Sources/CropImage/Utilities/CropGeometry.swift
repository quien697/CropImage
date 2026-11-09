//
//  CropGeometry.swift
//  CropImage
//
//  Created by Quien on 2026-06-01.
//

import CoreGraphics

/// Pure geometry helpers shared by the crop view and view model.
///
/// These functions are platform-agnostic (CoreGraphics only), so they can be
/// reused as-is when the library expands to iPad or macOS.
enum CropGeometry {
  /// The square crop region centered in `containerSize`.
  /// Its side is 75% of the container's smaller side, capped at 400 pt, so it fits in
  /// portrait, landscape, and short windows.
  static func cropSize(containerSize: CGSize) -> CGSize {
    let side = min(min(containerSize.width, containerSize.height) * 0.75, 400)
    return CGSize(width: side, height: side)
  }

  /// The smallest zoom at which an image rendered at `renderedSize` covers `cropSize`.
  static func minimumScale(cropSize: CGSize, renderedSize: CGSize) -> CGFloat {
    max(cropSize.width / renderedSize.width, cropSize.height / renderedSize.height)
  }

  /// The size `scaledToFill` renders an image at inside `containerSize`.
  /// scaledToFill picks the axis whose scale factor is larger, so one dimension
  /// matches the container and the other overflows.
  static func renderedSize(imageSize: CGSize, containerSize: CGSize) -> CGSize {
    let imageRatio = imageSize.width / imageSize.height
    let containerRatio = containerSize.width / containerSize.height
    if imageRatio > containerRatio {
      return CGSize(width: containerSize.height * imageRatio, height: containerSize.height)
    } else {
      return CGSize(width: containerSize.width, height: containerSize.width / imageRatio)
    }
  }

  /// Returns `offset` clamped so the image never exposes empty space inside the crop hole.
  /// maxOffset = (renderedSize * scale - cropSize) / 2, and 0 on an axis where the image is
  /// smaller than the crop hole, which centers it there.
  static func clampOffset(
    _ offset: CGSize,
    scale: CGFloat,
    cropSize: CGSize,
    renderedSize: CGSize
  ) -> CGSize {
    let maxX = max(0, (renderedSize.width * scale - cropSize.width) / 2)
    let maxY = max(0, (renderedSize.height * scale - cropSize.height) / 2)
    return CGSize(
      width: min(maxX, max(-maxX, offset.width)),
      height: min(maxY, max(-maxY, offset.height))
    )
  }
}
