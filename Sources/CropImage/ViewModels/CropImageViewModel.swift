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
  func crop(image: UIImage?, cropSize: CGSize, containerSize: CGSize) -> UIImage? {
    guard let image else { return nil }

    let view = Image(uiImage: image)
      .resizable()
      .scaledToFill()
      .scaleEffect(scale)
      .offset(offset)
      .frame(width: containerSize.width, height: containerSize.height)
      .clipped()
    let renderer = ImageRenderer(content: view)

    guard let full = renderer.uiImage, let cgImage = full.cgImage else {
      return nil
    }

    let fullScale = full.scale
    let rect = CGRect(
      x: (containerSize.width - cropSize.width) / 2 * fullScale,
      y: (containerSize.height - cropSize.height) / 2 * fullScale,
      width: cropSize.width * fullScale,
      height: cropSize.height * fullScale
    )
    guard let cropped = cgImage.cropping(to: rect) else { return nil }
    return UIImage(
      cgImage: cropped,
      scale: fullScale,
      orientation: full.imageOrientation
    )
  }
}
