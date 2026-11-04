//
//  CropImageViewModelGestureTests.swift
//  CropImage
//
//  Created by Quien on 2026-11-04.
//

import CoreGraphics
import Testing

@testable import CropImage

/// A 1000 × 1000 image in a 400 × 800 view fills 800 × 800 pt, so with a 300 pt crop region
/// the smallest zoom is 300 / 800 = 0.375 and, at zoom 1, the pan limit is (800 - 300) / 2
/// = 250 on both axes.
@MainActor
struct CropImageViewModelGestureTests {
  private let imageSize = CGSize(width: 1000, height: 1000)
  private let cropSize = CGSize(width: 300, height: 300)
  private let containerSize = CGSize(width: 400, height: 800)

  /// Ending a pinch multiplies the settled zoom by the pinch, from any starting zoom.
  @Test(arguments: [(3.0, 2.0, 6.0), (5.0, 0.5, 2.5)] as [(CGFloat, CGFloat, CGFloat)])
  func pinchEndedMultipliesTheZoom(
    startScale: CGFloat, magnification: CGFloat, expectedScale: CGFloat
  ) {
    let viewModel = CropImageViewModel()
    viewModel.scale = startScale

    viewModel.pinchEnded(
      magnification: magnification, imageSize: imageSize, cropSize: cropSize,
      containerSize: containerSize)

    #expect(viewModel.scale == expectedScale)
  }

  /// Pinching to a quarter of the finger distance at the smallest zoom shows a quarter of
  /// that zoom, never zero or below, and lifting springs back to the smallest zoom.
  @Test func pinchingAtTheSmallestZoomNeverFlips() {
    let viewModel = CropImageViewModel()
    viewModel.scale = 0.375

    #expect(viewModel.shownScale(pinch: 0.25) == 0.09375)

    viewModel.pinchEnded(
      magnification: 0.25, imageSize: imageSize, cropSize: cropSize,
      containerSize: containerSize)

    #expect(viewModel.scale == 0.375)
  }

  /// The image is shown at the settled pan plus the drag in progress.
  @Test func shownOffsetAddsTheDragToTheSettledPan() {
    let viewModel = CropImageViewModel()
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
    let viewModel = CropImageViewModel()
    viewModel.offset = CGSize(width: 10, height: 0)

    viewModel.dragEnded(
      translation: translation, imageSize: imageSize, cropSize: cropSize,
      containerSize: containerSize)

    #expect(viewModel.offset == expectedOffset)
  }

  /// Ending a drag also raises a zoom that is below the smallest zoom, so the pan limit is
  /// never computed for an image smaller than the crop region.
  @Test func dragEndedRaisesAZoomBelowTheMinimum() {
    let viewModel = CropImageViewModel()
    viewModel.scale = 0.2

    viewModel.dragEnded(
      translation: CGSize(width: 40, height: 40), imageSize: imageSize, cropSize: cropSize,
      containerSize: containerSize)

    #expect(viewModel.scale == 0.375)
    #expect(viewModel.offset == .zero)
  }

  /// After the view changes size, settling corrects a framing that was valid before. A
  /// 1200 × 900 image fills 1066.7 × 800 pt in a 400 × 800 view (smallest zoom 0.375) but
  /// 800 × 600 pt in an 800 × 400 view (smallest zoom 0.5, pan limit 250 at zoom 1).
  @Test func settleCorrectsTheFramingForANewViewSize() {
    let landscapeContainer = CGSize(width: 800, height: 400)
    let photoSize = CGSize(width: 1200, height: 900)

    let zoomedOut = CropImageViewModel()
    zoomedOut.scale = 0.375
    zoomedOut.settle(imageSize: photoSize, cropSize: cropSize, containerSize: landscapeContainer)
    #expect(zoomedOut.scale == 0.5)

    let panned = CropImageViewModel()
    panned.offset = CGSize(width: 300, height: 0)
    panned.settle(imageSize: photoSize, cropSize: cropSize, containerSize: landscapeContainer)
    #expect(panned.scale == 1)
    #expect(panned.offset == CGSize(width: 250, height: 0))
  }

  /// A view with no size yet, as during layout, leaves the framing alone instead of
  /// computing a zoom from 0 / 0.
  @Test func settleIgnoresAnEmptyViewSize() {
    let viewModel = CropImageViewModel()
    viewModel.scale = 2
    viewModel.offset = CGSize(width: 40, height: -20)

    viewModel.settle(imageSize: imageSize, cropSize: .zero, containerSize: .zero)

    #expect(viewModel.scale == 2)
    #expect(viewModel.offset == CGSize(width: 40, height: -20))
  }

  /// An image with no size, such as a `UIImage()` placeholder, leaves the framing alone
  /// instead of computing an aspect ratio from 0 / 0.
  @Test func settleIgnoresAnEmptyImage() {
    let viewModel = CropImageViewModel()
    viewModel.scale = 2
    viewModel.offset = CGSize(width: 40, height: -20)

    viewModel.settle(imageSize: .zero, cropSize: cropSize, containerSize: containerSize)

    #expect(viewModel.scale == 2)
    #expect(viewModel.offset == CGSize(width: 40, height: -20))
  }
}
