//
//  CropImageViewModelTests.swift
//  CropImage
//
//  Created by Quien on 2026-11-05.
//

import Testing
import UIKit

@testable import CropImage

/// Confirm on the ready-made screen delivers one crop, however often it is tapped.
@MainActor
struct CropImageViewModelTests {
  /// The first Confirm delivers the area's crop at the output side asked for.
  @Test func confirmDeliversTheAreasCrop() throws {
    let viewModel = viewModelShowingAnImage()
    var deliveredCrops: [UIImage?] = []

    viewModel.confirm(outputSide: 840) { deliveredCrops.append($0) }

    #expect(deliveredCrops.count == 1)
    let deliveredCrop = try #require(deliveredCrops.first ?? nil)
    #expect(deliveredCrop.cgImage?.width == 840)
    #expect(deliveredCrop.cgImage?.height == 840)
    #expect(
      deliveredCrop.pngData() == viewModel.areaViewModel.crop(outputSide: 840)?.pngData())
  }

  /// Confirm is available once the area shows an image, and not after the first tap.
  @Test func confirmIsUnavailableAfterTheFirstTap() {
    let viewModel = viewModelShowingAnImage()
    #expect(viewModel.canConfirm)

    viewModel.confirm(outputSide: nil) { _ in }

    #expect(!viewModel.canConfirm)
  }

  /// Confirm is unavailable while the area has no image.
  @Test func confirmIsUnavailableWithoutAnImage() {
    let viewModel = CropImageViewModel()
    viewModel.areaViewModel.areaSizeChanged(to: CGSize(width: 400, height: 800))

    #expect(!viewModel.canConfirm)
  }

  /// A second Confirm, as from a tap that lands before the sheet closes, doesn't call
  /// `onCrop` again.
  @Test func confirmingTwiceDeliversOneCrop() {
    let viewModel = viewModelShowingAnImage()
    var callCount = 0

    viewModel.confirm(outputSide: nil) { _ in callCount += 1 }
    viewModel.confirm(outputSide: nil) { _ in callCount += 1 }

    #expect(callCount == 1)
  }

  /// An `onCrop` that confirms again while it runs is still called once.
  @Test func confirmingFromOnCropDeliversOneCrop() {
    let viewModel = viewModelShowingAnImage()
    var callCount = 0

    viewModel.confirm(outputSide: nil) { _ in
      callCount += 1
      viewModel.confirm(outputSide: nil) { _ in callCount += 1 }
    }

    #expect(callCount == 1)
  }

  /// A view model whose area shows a 1000 × 1000 pixel image, blue on the left half and
  /// orange on the right, in a 400 × 800 area, as `CropArea` sets it up.
  private func viewModelShowingAnImage() -> CropImageViewModel {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let image = UIGraphicsImageRenderer(size: CGSize(width: 1000, height: 1000), format: format)
      .image { context in
        UIColor.systemBlue.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 500, height: 1000))
        UIColor.systemOrange.setFill()
        context.fill(CGRect(x: 500, y: 0, width: 500, height: 1000))
      }
    let viewModel = CropImageViewModel()
    viewModel.areaViewModel.imageChanged(to: image)
    viewModel.areaViewModel.areaSizeChanged(to: CGSize(width: 400, height: 800))
    return viewModel
  }
}
