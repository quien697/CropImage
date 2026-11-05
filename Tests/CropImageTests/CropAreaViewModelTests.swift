//
//  CropAreaViewModelTests.swift
//  CropImage
//
//  Created by Quien on 2026-11-03.
//

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
