//
//  CropImageViewModel.swift
//  CropImage
//
//  Created by Quien on 2026-06-01.
//

import SwiftUI

/// Owns the interactive crop state (scale + offset), the gesture math, and the
/// final image rendering. It holds only mutable gesture state; the image and
/// crop shape are passed in by the view so they always reflect the latest
/// inputs (e.g. an image that loads asynchronously).
@MainActor
@Observable
final class CropImageViewModel {
  // MARK: - Live gesture state
  var scale: CGFloat = 1.0
  var offset: CGSize = .zero

  // MARK: - Gesture bookkeeping
  private var lastScale: CGFloat = 0
  private var lastOffset: CGSize = .zero

  // MARK: - Drag
  func dragChanged(_ value: DragGesture.Value) {
    offset = CGSize(
      width: value.translation.width + lastOffset.width,
      height: value.translation.height + lastOffset.height
    )
  }

  func dragEnded(imageSize: CGSize?, cropSize: CGSize, containerSize: CGSize) {
    let rendered = renderedSize(imageSize: imageSize, in: containerSize)
    let clamped = CropGeometry.clampOffset(
      offset,
      scale: scale,
      cropSize: cropSize,
      renderedSize: rendered
    )
    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
      offset = clamped
    }
    lastOffset = offset
  }

  // MARK: - Magnification
  func magnificationChanged(_ value: CGFloat) {
    scale = value + lastScale
  }

  func magnificationEnded(imageSize: CGSize?, cropSize: CGSize, containerSize: CGSize) {
    let rendered = renderedSize(imageSize: imageSize, in: containerSize)
    let minScale = max(
      cropSize.width / rendered.width,
      cropSize.height / rendered.height
    )
    let clampedScale = max(minScale, scale)
    let clampedOffset = CropGeometry.clampOffset(
      offset,
      scale: clampedScale,
      cropSize: cropSize,
      renderedSize: rendered
    )
    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
      scale = clampedScale
      offset = clampedOffset
    }
    lastScale = clampedScale - 1
    lastOffset = clampedOffset
  }

  // MARK: - Rendering
  /// The size `scaledToFill` renders the image at inside `containerSize`.
  func renderedSize(imageSize: CGSize?, in containerSize: CGSize) -> CGSize {
    guard let imageSize else { return containerSize }
    return CropGeometry.renderedSize(
      imageSize: imageSize,
      containerSize: containerSize
    )
  }

  /// Produces the cropped image for the current scale/offset, or `nil` if there
  /// is no image or rendering fails.
  ///
  /// The result has scale 1, so its size is its pixel size: `cropSize` without
  /// `outputSide`, or `outputSide` square with it.
  func crop(
    image: UIImage?,
    cropSize: CGSize,
    containerSize: CGSize,
    outputSide: CGFloat? = nil
  ) -> UIImage? {
    guard let image else { return nil }

    // Lay the image out as on screen, enlarged so the crop region is `outputSide`
    // points, and render only that region at scale 1. Rendering the whole
    // container instead exceeds ImageRenderer's size limit at large outputs and
    // comes back blank.
    let outputScale = outputSide.map { $0 / cropSize.width } ?? 1
    let outputSize = outputSide.map { CGSize(width: $0, height: $0) } ?? cropSize
    let view = Image(uiImage: image)
      .resizable()
      .scaledToFill()
      .scaleEffect(scale)
      .offset(x: offset.width * outputScale, y: offset.height * outputScale)
      .frame(
        width: containerSize.width * outputScale,
        height: containerSize.height * outputScale
      )
      .frame(width: outputSize.width, height: outputSize.height)
      .clipped()
    return ImageRenderer(content: view).uiImage
  }
}
