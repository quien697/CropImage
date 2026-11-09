//
//  CropAreaViewModel.swift
//  CropImage
//
//  Created by Quien on 2026-06-01.
//

import SwiftUI

/// The view model of a `CropArea`, which an app holds to crop and reset it.
///
/// Keep one in the `@State` of the screen that shows its `CropArea`, and pass it to the
/// area. Call `crop(outputSide:)` from your confirm button and `reset()` from a reset
/// button. The framing belongs to the view model, so a view model kept in the screen's
/// state starts each visit at the initial framing and lets go of the image with the
/// screen. A gesture in progress stays in the area until it ends.
@MainActor
@Observable
public final class CropAreaViewModel {
  // MARK: - Settled framing
  /// The zoom and pan once no gesture is in progress. `crop` renders these.
  var scale: CGFloat = 1.0
  var offset: CGSize = .zero

  // MARK: - Area
  /// The image the area shows and the area's size, which the area keeps current.
  private(set) var image: UIImage?
  private(set) var areaSize: CGSize = .zero

  // MARK: - Init
  /// Creates a view model at the initial framing.
  public init() {}

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

  // MARK: - Area changes
  /// Stores the image the area shows, correcting the framing if its size changed. An
  /// image without pixels, such as `UIImage()`, has nothing to frame or crop, so it is
  /// stored as no image.
  func imageChanged(to newImage: UIImage?) {
    var newImage = newImage
    if let size = newImage?.size, size.width <= 0 || size.height <= 0 {
      newImage = nil
    }
    let sizeChanged = newImage?.size != image?.size
    image = newImage
    if sizeChanged {
      settle()
    }
  }

  /// Stores the area's size and corrects the framing for it.
  func areaSizeChanged(to newSize: CGSize) {
    areaSize = newSize
    settle()
  }

  // MARK: - Gesture ends
  /// Folds a finished drag into the settled pan, then corrects the framing.
  func dragEnded(translation: CGSize) {
    offset = shownOffset(drag: translation)
    settle()
  }

  /// Folds a finished pinch into the settled zoom, then corrects the framing.
  func pinchEnded(magnification: CGFloat) {
    scale = shownScale(pinch: magnification)
    settle()
  }

  // MARK: - Corrections
  /// Raises the zoom to the smallest zoom that covers the crop region, then limits
  /// the pan so the image covers it, animated with a spring.
  func settle() {
    // An area without a size yet has no aspect ratio to compute a zoom from (0 / 0).
    guard areaSize.width > 0, areaSize.height > 0 else { return }
    let imageSize = image?.size

    let cropSize = CropGeometry.cropSize(containerSize: areaSize)
    let rendered = renderedSize(imageSize: imageSize, in: areaSize)
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

  /// Returns to the initial framing, zoom 1 and no pan, with the spring the framing
  /// settles with. The image stays.
  public func reset() {
    withAnimation(.cropSettle) {
      scale = 1
      offset = .zero
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

  /// The image inside the crop region, framed as the user left it at the end of their
  /// last gesture, or `nil` if there is no image, the image has no pixels, the area
  /// hasn't appeared yet, or rendering fails.
  ///
  /// - Parameter outputSide: The side length, in pixels, of the square image returned,
  ///   greater than 0 and at most 8192; a fraction rounds up. If the framed area has
  ///   fewer source pixels, it is upscaled. When `nil`, the image is the crop region's
  ///   size in points, rounded up to whole pixels, at scale 1.
  public func crop(outputSide: CGFloat? = nil) -> UIImage? {
    if let outputSide {
      precondition(
        outputSide > 0 && outputSide <= 8192,
        "outputSide must be greater than 0 and at most 8192 pixels")
    }
    guard let image, areaSize.width > 0, areaSize.height > 0 else { return nil }
    let cropSize = CropGeometry.cropSize(containerSize: areaSize)

    // Draw the image where `CropArea` shows it: at its `scaledToFill` size times the
    // zoom, centered on the crop region's center plus the pan. The output side is
    // `outputSide`, or else the crop region's side, rounded up to whole pixels, and
    // everything is scaled to it. Laying the image out with SwiftUI instead rounds its
    // frame to whole pixels before zoom and pan apply, which leaves a faint edge where
    // the image's edge meets the crop's, and ImageRenderer clips HDR highlights.
    let renderSide = (outputSide ?? cropSize.width).rounded(.up)
    let outputScale = renderSide / cropSize.width
    let rendered = renderedSize(imageSize: image.size, in: areaSize)
    let drawnSize = CGSize(
      width: rendered.width * scale * outputScale,
      height: rendered.height * scale * outputScale
    )
    let drawnCenter = CGPoint(
      x: (cropSize.width / 2 + offset.width) * outputScale,
      y: (cropSize.height / 2 + offset.height) * outputScale
    )
    // The image's own format keeps its colors, wide color and HDR highlights included.
    // Crops keep an alpha channel even when the image has none, as they always had.
    let format = image.imageRendererFormat
    format.scale = 1
    format.opaque = false
    return UIGraphicsImageRenderer(
      size: CGSize(width: renderSide, height: renderSide),
      format: format
    ).image { context in
      context.cgContext.interpolationQuality = .high
      // `UIImage.draw` applies the image's orientation, as `Image(uiImage:)` does.
      image.draw(
        in: CGRect(
          x: drawnCenter.x - drawnSize.width / 2,
          y: drawnCenter.y - drawnSize.height / 2,
          width: drawnSize.width,
          height: drawnSize.height
        )
      )
    }
  }
}

extension Animation {
  /// The spring the crop framing settles with, shared by the view model's corrections
  /// and the reset of gestures in progress, so every path back to a valid framing moves
  /// the same way.
  static let cropSettle = Animation.spring(response: 0.3, dampingFraction: 0.8)
}
