//
//  CropGeometryTests.swift
//  CropImage
//
//  Created by Quien on 2026-11-04.
//

import CoreGraphics
import Testing

@testable import CropImage

struct CropGeometryTests {
  /// The crop region's side is 75% of the view's smaller side, capped at 400 pt, so it fits
  /// in portrait, in landscape, and on large screens.
  @Test(
    arguments: [
      (CGSize(width: 402, height: 724), 301.5),
      (CGSize(width: 874, height: 340), 255),
      (CGSize(width: 1032, height: 1376), 400),
    ] as [(CGSize, CGFloat)])
  func cropSizeFitsTheSmallerSide(containerSize: CGSize, expectedSide: CGFloat) {
    #expect(
      CropGeometry.cropSize(containerSize: containerSize)
        == CGSize(width: expectedSide, height: expectedSide))
  }

  /// Where the image is shorter than the crop region, the pan limit centers it on that axis
  /// instead of pushing it to one side.
  @Test func clampOffsetCentersAnAxisWhereTheImageIsSmaller() {
    let clamped = CropGeometry.clampOffset(
      CGSize(width: 80, height: 30),
      scale: 1,
      cropSize: CGSize(width: 300, height: 300),
      renderedSize: CGSize(width: 400, height: 200))

    #expect(clamped == CGSize(width: 50, height: 0))
  }

  /// A pan inside the limits is left alone.
  @Test func clampOffsetKeepsAPanWithinTheLimits() {
    let clamped = CropGeometry.clampOffset(
      CGSize(width: 20, height: -10),
      scale: 1,
      cropSize: CGSize(width: 300, height: 300),
      renderedSize: CGSize(width: 600, height: 600))

    #expect(clamped == CGSize(width: 20, height: -10))
  }

  /// The smallest zoom that covers the crop region is set by the image's shorter side
  /// relative to the crop region.
  @Test func minimumScaleCoversTheCropRegionOnBothAxes() {
    let minimum = CropGeometry.minimumScale(
      cropSize: CGSize(width: 300, height: 300),
      renderedSize: CGSize(width: 600, height: 400))

    #expect(minimum == 0.75)
  }

  /// A 1200 × 1200 px source rendered at 800 × 800 pt shows 1.5 source pixels per point
  /// at zoom 1, so the 300 pt crop region covers 450 of them. Zooming out until the image
  /// just covers the crop region gives the whole source, and an extreme zoom one pixel.
  @Test(
    arguments: [
      (1, CGSize.zero, CGRect(x: 375, y: 375, width: 450, height: 450)),
      (1, CGSize(width: 40, height: -60), CGRect(x: 315, y: 465, width: 450, height: 450)),
      (0.375, CGSize.zero, CGRect(x: 0, y: 0, width: 1200, height: 1200)),
      (10000, CGSize.zero, CGRect(x: 600, y: 600, width: 1, height: 1)),
    ] as [(CGFloat, CGSize, CGRect)])
  func sourcePixelCropRectCoversTheCropRegion(
    scale: CGFloat, offset: CGSize, expectedRect: CGRect
  ) {
    let rect = CropGeometry.sourcePixelCropRect(
      imagePixelSize: CGSize(width: 1200, height: 1200),
      renderedSize: CGSize(width: 800, height: 800),
      scale: scale,
      offset: offset,
      cropSize: CGSize(width: 300, height: 300))

    #expect(rect == expectedRect)
  }

  /// An iPhone 17 Pro's 301.5 pt crop region over a 1200 px source rendered at 874 pt
  /// covers about 413.96 source pixels, which rounds to 414, on whole pixels.
  @Test func sourcePixelCropRectRoundsToWholePixels() {
    let rect = CropGeometry.sourcePixelCropRect(
      imagePixelSize: CGSize(width: 1200, height: 1200),
      renderedSize: CGSize(width: 874, height: 874),
      scale: 1,
      offset: .zero,
      cropSize: CGSize(width: 301.5, height: 301.5))

    #expect(rect == CGRect(x: 393, y: 393, width: 414, height: 414))
  }

  /// Zoomed out as far as it goes, a 1200 × 900 px source gives its full height,
  /// centered horizontally.
  @Test func sourcePixelCropRectOfAWideSourceUsesItsShorterSide() {
    let rect = CropGeometry.sourcePixelCropRect(
      imagePixelSize: CGSize(width: 1200, height: 900),
      renderedSize: CGSize(width: 3200.0 / 3, height: 800),
      scale: 0.375,
      offset: .zero,
      cropSize: CGSize(width: 300, height: 300))

    #expect(rect == CGRect(x: 150, y: 0, width: 900, height: 900))
  }

  /// A pan past the limit, or a zoom just under the smallest, would reach outside the
  /// source; the rectangle stays inside it.
  @Test(
    arguments: [
      (1, CGSize(width: 260, height: -260), CGRect(x: 0, y: 750, width: 450, height: 450)),
      (0.374, CGSize.zero, CGRect(x: 0, y: 0, width: 1200, height: 1200)),
    ] as [(CGFloat, CGSize, CGRect)])
  func sourcePixelCropRectStaysInsideTheSource(
    scale: CGFloat, offset: CGSize, expectedRect: CGRect
  ) {
    let rect = CropGeometry.sourcePixelCropRect(
      imagePixelSize: CGSize(width: 1200, height: 1200),
      renderedSize: CGSize(width: 800, height: 800),
      scale: scale,
      offset: offset,
      cropSize: CGSize(width: 300, height: 300))

    #expect(rect == expectedRect)
  }
}
