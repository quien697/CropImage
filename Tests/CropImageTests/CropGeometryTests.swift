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
}
