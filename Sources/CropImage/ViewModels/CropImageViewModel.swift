//
//  CropImageViewModel.swift
//  CropImage
//
//  Created by Quien on 2026-06-01.
//

import SwiftUI

/// Owns the settled crop framing (scale + offset), the gesture math, and the
/// final image rendering. The view tracks gestures in progress and passes them in
/// when they end; the image and crop shape are passed in by the view so they always
/// reflect the latest inputs (e.g. an image that loads asynchronously).
@MainActor
@Observable
final class CropImageViewModel {
  // MARK: - Settled framing
  /// The zoom and pan once no gesture is in progress. `crop` renders these.
  var scale: CGFloat = 1.0
  var offset: CGSize = .zero

  // MARK: - Shown framing
  /// The zoom shown while a pinch of `magnification` is in progress.
  func shownScale(pinch magnification: CGFloat) -> CGFloat {
    scale * magnification
  }

  /// The pan shown while a drag of `translation` is in progress.
  func shownOffset(drag translation: CGSize) -> CGSize {
    CGSize(
      width: offset.width + translation.width,
      height: offset.height + translation.height
    )
  }

  // MARK: - Gesture ends
  /// Folds a finished drag into the settled pan, then corrects the framing.
  func dragEnded(
    translation: CGSize,
    imageSize: CGSize?,
    cropSize: CGSize,
    containerSize: CGSize
  ) {
    offset = shownOffset(drag: translation)
    settle(imageSize: imageSize, cropSize: cropSize, containerSize: containerSize)
  }

  /// Folds a finished pinch into the settled zoom, then corrects the framing.
  func pinchEnded(
    magnification: CGFloat,
    imageSize: CGSize?,
    cropSize: CGSize,
    containerSize: CGSize
  ) {
    scale = shownScale(pinch: magnification)
    settle(imageSize: imageSize, cropSize: cropSize, containerSize: containerSize)
  }

  // MARK: - Corrections
  /// Raises the zoom to the smallest zoom that covers the crop region, then limits
  /// the pan so the image covers it, animated with a spring.
  func settle(imageSize: CGSize?, cropSize: CGSize, containerSize: CGSize) {
    // A view without a size yet, or an image without pixels, has no aspect ratio to
    // compute a zoom from (0 / 0).
    guard containerSize.width > 0, containerSize.height > 0 else { return }
    if let imageSize, imageSize.width <= 0 || imageSize.height <= 0 { return }

    let rendered = renderedSize(imageSize: imageSize, in: containerSize)
    let settledScale = max(
      CropGeometry.minimumScale(cropSize: cropSize, renderedSize: rendered),
      scale
    )
    let settledOffset = CropGeometry.clampOffset(
      offset,
      scale: settledScale,
      cropSize: cropSize,
      renderedSize: rendered
    )
    withAnimation(.cropSettle) {
      scale = settledScale
      offset = settledOffset
    }
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

extension Animation {
  /// The spring the crop framing settles with, shared by the view model's corrections
  /// and the reset of gestures in progress, so every path back to a valid framing moves
  /// the same way.
  static let cropSettle = Animation.spring(response: 0.3, dampingFraction: 0.8)
}
