//
//  CropAreaViewModelGestureTests.swift
//  CropImage
//
//  Created by Quien on 2026-11-04.
//

import Testing
import UIKit

@testable import CropImage

/// A 1000 × 1000 image in a 400 × 800 area fills 800 × 800 pt, so with its 300 pt crop region
/// the smallest zoom is 300 / 800 = 0.375 and, at zoom 1, the pan limit is (800 - 300) / 2
/// = 250 on both axes.
@MainActor
struct CropAreaViewModelGestureTests {
  private let imageSize = CGSize(width: 1000, height: 1000)
  private let areaSize = CGSize(width: 400, height: 800)

  /// Ending a pinch multiplies the settled zoom by the pinch, from any starting zoom.
  @Test(arguments: [(3.0, 2.0, 6.0), (5.0, 0.5, 2.5)] as [(CGFloat, CGFloat, CGFloat)])
  func pinchEndedMultipliesTheZoom(
    startScale: CGFloat, magnification: CGFloat, expectedScale: CGFloat
  ) {
    let viewModel = viewModel(imageSize: imageSize, areaSize: areaSize)
    viewModel.scale = startScale

    viewModel.pinchEnded(magnification: magnification)

    #expect(viewModel.scale == expectedScale)
  }

  /// Pinching to a quarter of the finger distance at the smallest zoom shows a quarter of
  /// that zoom, never zero or below, and lifting springs back to the smallest zoom.
  @Test func pinchingAtTheSmallestZoomNeverFlips() {
    let viewModel = viewModel(imageSize: imageSize, areaSize: areaSize)
    viewModel.scale = 0.375

    #expect(viewModel.shownScale(pinch: 0.25) == 0.09375)

    viewModel.pinchEnded(magnification: 0.25)

    #expect(viewModel.scale == 0.375)
  }

  /// The image is shown at the settled pan plus the drag in progress.
  @Test func shownOffsetAddsTheDragToTheSettledPan() {
    let viewModel = CropAreaViewModel()
    viewModel.offset = CGSize(width: 10, height: 0)

    #expect(viewModel.shownOffset(drag: CGSize(width: 30, height: -20)) == CGSize(width: 40, height: -20))
  }

  /// Ending a drag adds it to the settled pan, and limits the result so the image covers the
  /// crop region.
  @Test(
    arguments: [
      (CGSize(width: 30, height: -20), CGSize(width: 40, height: -20)),
      (CGSize(width: 1000, height: 0), CGSize(width: 250, height: 0)),
    ] as [(CGSize, CGSize)])
  func dragEndedAddsTheDragAndLimitsThePan(translation: CGSize, expectedOffset: CGSize) {
    let viewModel = viewModel(imageSize: imageSize, areaSize: areaSize)
    viewModel.offset = CGSize(width: 10, height: 0)

    viewModel.dragEnded(translation: translation)

    #expect(viewModel.offset == expectedOffset)
  }

  /// Ending a drag also raises a zoom that is below the smallest zoom, so the pan limit is
  /// never computed for an image smaller than the crop region.
  @Test func dragEndedRaisesAZoomBelowTheMinimum() {
    let viewModel = viewModel(imageSize: imageSize, areaSize: areaSize)
    viewModel.scale = 0.2

    viewModel.dragEnded(translation: CGSize(width: 40, height: 40))

    #expect(viewModel.scale == 0.375)
    #expect(viewModel.offset == .zero)
  }

  /// Resetting after zooming and panning returns to the initial framing, zoom 1 and no
  /// pan, with the same image to crop.
  @Test func resetReturnsToTheInitialFraming() {
    let viewModel = viewModel(imageSize: imageSize, areaSize: areaSize)
    viewModel.scale = 3
    viewModel.offset = CGSize(width: 40, height: -20)

    viewModel.reset()

    #expect(viewModel.scale == 1)
    #expect(viewModel.offset == .zero)
    #expect(viewModel.image?.size == imageSize)
  }

  /// When the area changes size, the framing that was valid before is corrected. A
  /// 1200 × 900 image fills 1066.7 × 800 pt in a 400 × 800 area (smallest zoom 0.375) but
  /// 800 × 600 pt in an 800 × 400 area (smallest zoom 0.5, pan limit 250 at zoom 1).
  @Test func aNewAreaSizeCorrectsTheFraming() {
    let landscapeArea = CGSize(width: 800, height: 400)
    let photoSize = CGSize(width: 1200, height: 900)

    let zoomedOut = viewModel(imageSize: photoSize, areaSize: areaSize)
    zoomedOut.scale = 0.375
    zoomedOut.areaSizeChanged(to: landscapeArea)
    #expect(zoomedOut.scale == 0.5)

    let panned = viewModel(imageSize: photoSize, areaSize: areaSize)
    panned.offset = CGSize(width: 300, height: 0)
    panned.areaSizeChanged(to: landscapeArea)
    #expect(panned.scale == 1)
    #expect(panned.offset == CGSize(width: 250, height: 0))
  }

  /// A new image of the same size, such as the same photo decoded again, keeps the zoom
  /// and pan, and is the image that gets cropped.
  @Test func aSameSizeImageKeepsTheFraming() {
    let viewModel = viewModel(imageSize: imageSize, areaSize: areaSize)
    viewModel.scale = 2
    viewModel.offset = CGSize(width: 40, height: -20)
    let sameSizeImage = plainImage(size: imageSize)

    viewModel.imageChanged(to: sameSizeImage)

    #expect(viewModel.image === sameSizeImage)
    #expect(viewModel.scale == 2)
    #expect(viewModel.offset == CGSize(width: 40, height: -20))
  }

  /// A differently shaped image corrects the framing. A 500 × 1500 image fills 400 × 1200 pt
  /// in a 400 × 800 area, so the smallest zoom rises from 0.375 to 300 / 400 = 0.75.
  @Test func aDifferentlyShapedImageCorrectsTheFraming() {
    let viewModel = viewModel(imageSize: imageSize, areaSize: areaSize)
    viewModel.scale = 0.375

    viewModel.imageChanged(to: plainImage(size: CGSize(width: 500, height: 1500)))

    #expect(viewModel.scale == 0.75)
  }

  /// An area with no size yet, as during layout, leaves the framing alone instead of
  /// computing a zoom from 0 / 0.
  @Test func anEmptyAreaSizeLeavesTheFramingAlone() {
    let viewModel = viewModel(imageSize: imageSize, areaSize: areaSize)
    viewModel.scale = 2
    viewModel.offset = CGSize(width: 40, height: -20)

    viewModel.areaSizeChanged(to: .zero)

    #expect(viewModel.scale == 2)
    #expect(viewModel.offset == CGSize(width: 40, height: -20))
  }

  /// An image with no size, such as a `UIImage()` placeholder, leaves the framing alone
  /// instead of computing an aspect ratio from 0 / 0.
  @Test func anEmptyImageLeavesTheFramingAlone() {
    let viewModel = CropAreaViewModel()
    viewModel.imageChanged(to: UIImage())
    viewModel.scale = 2
    viewModel.offset = CGSize(width: 40, height: -20)

    viewModel.areaSizeChanged(to: areaSize)

    #expect(viewModel.scale == 2)
    #expect(viewModel.offset == CGSize(width: 40, height: -20))
  }

  /// A view model whose area is `areaSize` and shows a plain image of `imageSize` pixels,
  /// as `CropArea` sets it up.
  private func viewModel(imageSize: CGSize, areaSize: CGSize) -> CropAreaViewModel {
    let viewModel = CropAreaViewModel()
    viewModel.imageChanged(to: plainImage(size: imageSize))
    viewModel.areaSizeChanged(to: areaSize)
    return viewModel
  }

  /// A blank image of `size` pixels at scale 1.
  private func plainImage(size: CGSize) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    return UIGraphicsImageRenderer(size: size, format: format).image { _ in }
  }
}
