//
//  CropAreaViewModelTests.swift
//  CropImage
//
//  Created by Quien on 2026-11-03.
//

import SwiftUI
import Testing
import UIKit

@testable import CropImage

@MainActor
struct CropAreaViewModelTests {
  /// A 1200 × 1200 pixel image, larger than any crop the tests ask for.
  private let sourceImage: UIImage = {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    return UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 1200), format: format)
      .image { context in
        UIColor.systemTeal.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 1200, height: 1200))
      }
  }()

  /// A 1200 × 900 pixel grid of 100 px squares in which neighboring squares never share
  /// a color, so a crop shifted by part of a square changes many sampled colors.
  private let patternImage: UIImage = {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let colors: [UIColor] = [.red, .green, .blue, .yellow, .cyan, .magenta, .orange, .purple]
    return UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 900), format: format)
      .image { context in
        for row in 0..<9 {
          for column in 0..<12 {
            colors[(row * 12 + column * 5) % colors.count].setFill()
            context.fill(CGRect(x: column * 100, y: row * 100, width: 100, height: 100))
          }
        }
      }
  }()

  /// A 400 × 800 pt area has a 300 × 300 pt crop region.
  private let areaSize = CGSize(width: 400, height: 800)

  /// Without `outputSide`, a whole-number crop region comes out at its size in points,
  /// one pixel per point.
  @Test func cropWithoutOutputSideIsTheCropSideAtScaleOne() throws {
    let cropped = try #require(
      viewModel(showing: sourceImage, areaSize: areaSize).crop())
    let cgImage = try #require(cropped.cgImage)

    #expect(cgImage.width == 300)
    #expect(cgImage.height == 300)
  }

  /// A crop region off whole points rounds up to whole pixels. A 407.2 pt wide area has a
  /// 305.4 pt crop region starting 50.9 pt in; rounding both of its edges outward, as
  /// 1.0.0 did, gave 307 px here.
  @Test func cropWithoutOutputSideRoundsAFractionalSideUp() throws {
    let cropped = try #require(
      viewModel(showing: sourceImage, areaSize: CGSize(width: 407.2, height: 874)).crop())
    let cgImage = try #require(cropped.cgImage)

    #expect(cgImage.width == 306)
    #expect(cgImage.height == 306)
    #expect(cropped.scale == 1)
  }

  /// A side rounded up from under half a pixel still fills its last row and column: a
  /// 375 pt wide area's 281.25 pt crop region left them empty.
  @Test func cropWithoutOutputSideFillsAFractionalSidesEdges() throws {
    let cropped = try #require(
      viewModel(showing: sourceImage, areaSize: CGSize(width: 375, height: 667)).crop())
    let cgImage = try #require(cropped.cgImage)

    #expect(cgImage.width == 282)
    #expect(cgImage.height == 282)
    #expect(try lowestAlpha(of: cgImage) == 255)
  }

  /// With `outputSide`, the crop is exactly that many pixels on each side, at scale 1.
  @Test func cropWithOutputSideIsThatManyPixelsSquare() throws {
    let cropped = try #require(
      viewModel(showing: sourceImage, areaSize: areaSize).crop(outputSide: 840))
    let cgImage = try #require(cropped.cgImage)

    #expect(cgImage.width == 840)
    #expect(cgImage.height == 840)
    #expect(cropped.scale == 1)
  }

  /// An iPhone 17 Pro's crop: 0.75 of a 402 pt wide screen is a fractional side.
  @Test func cropWithOutputSideIsExactOnAFractionalCropSide() throws {
    let cropped = try #require(
      viewModel(showing: sourceImage, areaSize: CGSize(width: 402, height: 874))
        .crop(outputSide: 840))
    let cgImage = try #require(cropped.cgImage)

    #expect(cgImage.width == 840)
    #expect(cgImage.height == 840)
  }

  /// A fractional `outputSide` rounds up to whole pixels and fills them: 840.4 left the
  /// last row and column of 841 empty.
  @Test func cropWithAFractionalOutputSideRoundsUpAndFillsIt() throws {
    let cropped = try #require(
      viewModel(showing: sourceImage, areaSize: areaSize).crop(outputSide: 840.4))
    let cgImage = try #require(cropped.cgImage)

    #expect(cgImage.width == 841)
    #expect(cgImage.height == 841)
    #expect(try lowestAlpha(of: cgImage) == 255)
  }

  /// Zoomed out as far as it goes, a square image just covers the crop region, and the
  /// crop is opaque to its edges. Laying the image out left a half-transparent edge in a
  /// 428 × 926 pt area.
  @Test func cropAtTheSmallestZoomIsOpaqueToItsEdges() throws {
    let viewModel = viewModel(showing: sourceImage, areaSize: CGSize(width: 428, height: 926))
    viewModel.pinchEnded(magnification: 0.01)
    let cgImage = try #require(viewModel.crop()?.cgImage)

    #expect(try lowestAlpha(of: cgImage) == 255)
  }

  /// A photo without alpha, such as a decoded JPEG, still crops to an image with an alpha
  /// channel, as crops always had. Drawing in the photo's own opaque format dropped it.
  @Test func cropOfAPhotoWithoutAlphaHasAnAlphaChannel() throws {
    let jpegData = try #require(sourceImage.jpegData(compressionQuality: 0.9))
    let jpegImage = try #require(UIImage(data: jpegData))
    let cgImage = try #require(
      viewModel(showing: jpegImage, areaSize: areaSize).crop()?.cgImage)

    #expect(![.none, .noneSkipFirst, .noneSkipLast].contains(cgImage.alphaInfo))
  }

  /// Panned as far as it goes, the image's edge is the crop's edge, and the crop is
  /// opaque to its edges, even on a whole-number crop side.
  @Test func cropAtThePanLimitIsOpaqueToItsEdges() throws {
    let viewModel = viewModel(showing: patternImage, areaSize: areaSize)
    viewModel.pinchEnded(magnification: 0.01)
    viewModel.dragEnded(translation: CGSize(width: 1000, height: 0))
    let cgImage = try #require(viewModel.crop()?.cgImage)

    #expect(try lowestAlpha(of: cgImage) == 255)
  }

  /// An iPad Pro 13-inch's crop: the side is capped at 400 pt inside a 1032 × 1376 pt
  /// container. A large output must still contain the image, not come back blank.
  @Test func cropWithALargeOutputSideOnAnIPadIsNotBlank() throws {
    let cropped = try #require(
      viewModel(showing: sourceImage, areaSize: CGSize(width: 1032, height: 1376))
        .crop(outputSide: 4096))
    let cgImage = try #require(cropped.cgImage)

    #expect(cgImage.width == 4096)
    #expect(cgImage.height == 4096)
    #expect(centerAlpha(of: cgImage) == 255)
  }

  /// A zoomed and panned crop with `outputSide` shows the same part of the image as the
  /// same crop without it. Antialiasing where squares meet keeps the mean difference per
  /// byte under 1; a pan left unscaled with the output pushes it above 50.
  @Test func cropWithOutputSideFramesTheSameContentAsWithout() throws {
    let viewModel = viewModel(showing: patternImage, areaSize: areaSize)
    viewModel.scale = 1.7
    viewModel.offset = CGSize(width: 40, height: -65)

    let withoutOutputSide = try #require(viewModel.crop()?.cgImage)
    let withOutputSide = try #require(viewModel.crop(outputSide: 900)?.cgImage)

    let samplesWithout = try colorSamples(of: withoutOutputSide, gridSide: 64)
    let samplesWith = try colorSamples(of: withOutputSide, gridSide: 64)
    let totalDifference = zip(samplesWithout, samplesWith).reduce(0) { total, pair in
      total + abs(Int(pair.0) - Int(pair.1))
    }
    let meanDifference = Double(totalDifference) / Double(samplesWithout.count)

    #expect(meanDifference < 10)
  }

  /// A high dynamic range image keeps its highlights: a PQ image whose linear value is
  /// about 4.8 came out clipped to 1.
  @Test func cropKeepsHighDynamicRangeHighlights() throws {
    let hdrImage = try filledImage(
      colorSpaceName: CGColorSpace.itur_2100_PQ, components: [0.75, 0.75, 0.75, 1],
      isHalfFloat: true)
    let cgImage = try #require(viewModel(showing: hdrImage, areaSize: areaSize).crop()?.cgImage)

    #expect(try centerColor(of: cgImage, in: CGColorSpace.extendedLinearSRGB)[0] > 4)
  }

  /// A Display P3 image keeps the colors outside sRGB: its pure red isn't pulled in to
  /// sRGB's red.
  @Test func cropKeepsWideColors() throws {
    let wideColorImage = try filledImage(
      colorSpaceName: CGColorSpace.displayP3, components: [1, 0, 0, 1])
    let cgImage = try #require(
      viewModel(showing: wideColorImage, areaSize: areaSize).crop()?.cgImage)
    let color = try centerColor(of: cgImage, in: CGColorSpace.displayP3)

    #expect(color[0] > 0.99)
    #expect(color[1] < 0.01)
    #expect(color[2] < 0.01)
  }

  /// The crop shows what its `CropArea` shows in the crop region: zoomed, panned, for an
  /// image turned by its orientation, in a 402 pt wide area whose crop region is
  /// 301.5 pt, and in a right-to-left layout. Both are rendered at 4 pixels per point,
  /// where that region falls on whole pixels. Resampling differences keep the mean
  /// difference per byte between 0.2 and 1.5; a pan off by 10 pt gives 4.4 to 16.7, so
  /// the test allows under 3.
  @Test func cropShowsWhatTheAreaShows() throws {
    let turnedImage = try UIImage(
      cgImage: #require(patternImage.cgImage), scale: 1, orientation: .right)
    let framings:
      [(
        image: UIImage, areaSize: CGSize, scale: CGFloat, offset: CGSize,
        layoutDirection: LayoutDirection
      )] = [
        (patternImage, areaSize, 1, .zero, .leftToRight),
        (patternImage, areaSize, 1.7, CGSize(width: 40, height: -65), .leftToRight),
        (patternImage, areaSize, 2.3, CGSize(width: -120, height: 90), .leftToRight),
        (turnedImage, areaSize, 1.7, CGSize(width: 40, height: -65), .leftToRight),
        (
          patternImage, CGSize(width: 402, height: 874), 1.7, CGSize(width: 40, height: -65),
          .leftToRight
        ),
        (patternImage, areaSize, 1.7, CGSize(width: 40, height: -65), .rightToLeft),
      ]
    let pixelsPerPoint: CGFloat = 4
    for framing in framings {
      let viewModel = viewModel(showing: framing.image, areaSize: framing.areaSize)
      viewModel.scale = framing.scale
      viewModel.offset = framing.offset
      let renderer = ImageRenderer(
        content: CropArea(image: framing.image, cropShape: .square, viewModel: viewModel)
          .frame(width: framing.areaSize.width, height: framing.areaSize.height)
          .environment(\.layoutDirection, framing.layoutDirection))
      renderer.scale = pixelsPerPoint
      let cropSide = CropGeometry.cropSize(containerSize: framing.areaSize).width
      let cropRegion = CGRect(
        x: (framing.areaSize.width - cropSide) / 2 * pixelsPerPoint,
        y: (framing.areaSize.height - cropSide) / 2 * pixelsPerPoint,
        width: cropSide * pixelsPerPoint,
        height: cropSide * pixelsPerPoint)
      let shownRegion = try #require(renderer.cgImage?.cropping(to: cropRegion))
      let cropped = try #require(
        viewModel.crop(outputSide: cropSide * pixelsPerPoint)?.cgImage)

      let samplesShown = try colorSamples(of: shownRegion, gridSide: 64)
      let samplesCropped = try colorSamples(of: cropped, gridSide: 64)
      let totalDifference = zip(samplesShown, samplesCropped).reduce(0) { total, pair in
        total + abs(Int(pair.0) - Int(pair.1))
      }
      let meanDifference = Double(totalDifference) / Double(samplesShown.count)

      #expect(
        meanDifference < 3,
        """
        area \(framing.areaSize), zoom \(framing.scale), pan \(framing.offset), \
        \(framing.layoutDirection)
        """)
    }
  }

  /// Without an image there is nothing to crop.
  @Test func cropWithoutAnImageIsNil() {
    let viewModel = CropAreaViewModel()
    viewModel.areaSizeChanged(to: areaSize)

    #expect(viewModel.crop() == nil)
    #expect(viewModel.crop(outputSide: 840) == nil)
  }

  /// Before its area appears, the view model doesn't know the area's size, so there is no
  /// crop region to render yet.
  @Test func cropBeforeTheAreaAppearsIsNil() {
    let viewModel = CropAreaViewModel()
    viewModel.imageChanged(to: sourceImage)

    #expect(viewModel.crop() == nil)
    #expect(viewModel.crop(outputSide: 840) == nil)
  }

  /// A view model whose area is `areaSize` and shows `image`, as `CropArea` sets it up.
  private func viewModel(showing image: UIImage, areaSize: CGSize) -> CropAreaViewModel {
    let viewModel = CropAreaViewModel()
    viewModel.imageChanged(to: image)
    viewModel.areaSizeChanged(to: areaSize)
    return viewModel
  }

  /// The RGBA bytes of `image` scaled to `gridSide` × `gridSide` without smoothing. Fails
  /// the test if its drawing context can't be created, rather than returning zeros.
  private func colorSamples(of image: CGImage, gridSide: Int) throws -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: gridSide * gridSide * 4)
    try bytes.withUnsafeMutableBytes { buffer in
      let context = try #require(
        CGContext(
          data: buffer.baseAddress,
          width: gridSide,
          height: gridSide,
          bitsPerComponent: 8,
          bytesPerRow: gridSide * 4,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
      context.interpolationQuality = .none
      context.draw(image, in: CGRect(x: 0, y: 0, width: gridSide, height: gridSide))
    }
    return bytes
  }

  /// The lowest alpha of any pixel in the square `image`; an empty row or column is 0.
  private func lowestAlpha(of image: CGImage) throws -> UInt8 {
    let bytes = try colorSamples(of: image, gridSide: image.width)
    return stride(from: 3, to: bytes.count, by: 4).lazy.map { bytes[$0] }.min() ?? 0
  }

  /// A 1200 × 1200 pixel image filled with `components` in the color space named
  /// `colorSpaceName`, with 16-bit float components when `isHalfFloat`, else 8-bit.
  private func filledImage(
    colorSpaceName: CFString, components: [CGFloat], isHalfFloat: Bool = false
  ) throws -> UIImage {
    let colorSpace = try #require(CGColorSpace(name: colorSpaceName))
    let bitmapInfo =
      isHalfFloat
      ? CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.floatComponents.rawValue
        | CGBitmapInfo.byteOrder16Little.rawValue
      : CGImageAlphaInfo.premultipliedLast.rawValue
    let context = try #require(
      CGContext(
        data: nil,
        width: 1200,
        height: 1200,
        bitsPerComponent: isHalfFloat ? 16 : 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo))
    context.setFillColor(try #require(CGColor(colorSpace: colorSpace, components: components)))
    context.fill(CGRect(x: 0, y: 0, width: 1200, height: 1200))
    return UIImage(cgImage: try #require(context.makeImage()))
  }

  /// The red, green and blue of the pixel at the center of `image` in the color space
  /// named `colorSpaceName`, as floats that can go past 0 and 1 in an extended space.
  private func centerColor(of image: CGImage, in colorSpaceName: CFString) throws -> [Float] {
    let colorSpace = try #require(CGColorSpace(name: colorSpaceName))
    var components: [Float] = [0, 0, 0, 0]
    try components.withUnsafeMutableBytes { buffer in
      let context = try #require(
        CGContext(
          data: buffer.baseAddress,
          width: 1,
          height: 1,
          bitsPerComponent: 32,
          bytesPerRow: 16,
          space: colorSpace,
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            | CGBitmapInfo.floatComponents.rawValue | CGBitmapInfo.byteOrder32Little.rawValue))
      context.draw(
        image,
        in: CGRect(
          x: -CGFloat(image.width) / 2,
          y: -CGFloat(image.height) / 2,
          width: CGFloat(image.width),
          height: CGFloat(image.height)))
    }
    return Array(components.prefix(3))
  }

  /// The alpha of the pixel at the center of `image`; a blank render is 0.
  private func centerAlpha(of image: CGImage) -> UInt8 {
    var pixel: [UInt8] = [0, 0, 0, 0]
    pixel.withUnsafeMutableBytes { buffer in
      let context = CGContext(
        data: buffer.baseAddress,
        width: 1,
        height: 1,
        bitsPerComponent: 8,
        bytesPerRow: 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
      context?.draw(
        image,
        in: CGRect(
          x: -CGFloat(image.width) / 2,
          y: -CGFloat(image.height) / 2,
          width: CGFloat(image.width),
          height: CGFloat(image.height)))
    }
    return pixel[3]
  }
}
