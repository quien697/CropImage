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
  /// The first Confirm delivers the area's crop.
  @Test func confirmDeliversTheAreasCrop() async throws {
    let viewModel = viewModelShowingAnImage()
    var deliveredCrops: [UIImage?] = []

    await viewModel.confirm { deliveredCrops.append($0) }

    #expect(deliveredCrops.count == 1)
    let deliveredCrop = try #require(deliveredCrops.first ?? nil)
    #expect(deliveredCrop.pngData() == viewModel.areaViewModel.crop()?.pngData())
  }

  /// Confirm is available once the area shows an image, and not after the first tap.
  @Test func confirmIsUnavailableAfterTheFirstTap() async {
    let viewModel = viewModelShowingAnImage()
    #expect(viewModel.canConfirm)

    await viewModel.confirm { _ in }

    #expect(!viewModel.canConfirm)
  }

  /// Confirm is unavailable while the area has no image.
  @Test func confirmIsUnavailableWithoutAnImage() {
    let viewModel = CropImageViewModel()
    viewModel.areaViewModel.areaSizeChanged(to: CGSize(width: 400, height: 800))

    #expect(!viewModel.canConfirm)
  }

  /// Confirm is unavailable while the area's image has no pixels, as without an image.
  @Test func confirmIsUnavailableForAnImageWithoutPixels() {
    let viewModel = CropImageViewModel()
    viewModel.areaViewModel.imageChanged(to: UIImage())
    viewModel.areaViewModel.areaSizeChanged(to: CGSize(width: 400, height: 800))

    #expect(!viewModel.canConfirm)
  }

  /// A second Confirm, as from a tap that lands before the sheet closes, doesn't call
  /// `onCrop` again.
  @Test func confirmingTwiceDeliversOneCrop() async {
    let viewModel = viewModelShowingAnImage()
    var callCount = 0

    await viewModel.confirm { _ in callCount += 1 }
    await viewModel.confirm { _ in callCount += 1 }

    #expect(callCount == 1)
  }

  /// An `onCrop` that confirms again while it runs is still called once.
  @Test func confirmingFromOnCropDeliversOneCrop() async {
    let viewModel = viewModelShowingAnImage()
    var callCount = 0

    await viewModel.confirm { _ in
      callCount += 1
      await viewModel.confirm { _ in callCount += 1 }
    }

    #expect(callCount == 1)
  }

  /// While `onCrop` runs, the screen is locked and Confirm does nothing; once it returns,
  /// the screen stays locked while it closes.
  @Test(.timeLimit(.minutes(1))) func confirmIsUnavailableWhileOnCropRuns() async {
    let viewModel = viewModelShowingAnImage()
    var callCount = 0
    var onCropGate: CheckedContinuation<Void, Never>?

    let confirmTask = Task {
      await viewModel.confirm { _ in
        callCount += 1
        await withCheckedContinuation { onCropGate = $0 }
      }
    }
    while onCropGate == nil {
      await Task.yield()
    }

    #expect(viewModel.isLocked)
    #expect(!viewModel.canConfirm)
    await viewModel.confirm { _ in callCount += 1 }
    #expect(callCount == 1)

    onCropGate?.resume()
    await confirmTask.value

    #expect(viewModel.isLocked)
    #expect(!viewModel.canConfirm)
    await viewModel.confirm { _ in callCount += 1 }
    #expect(callCount == 1)
  }

  /// An `onCrop` that throws unlocks the screen, leaves the framing as it was, and makes
  /// Confirm available again.
  @Test func confirmIsAvailableAgainAfterOnCropThrows() async {
    let viewModel = viewModelShowingAnImage()
    viewModel.areaViewModel.pinchEnded(magnification: 3)
    viewModel.areaViewModel.dragEnded(translation: CGSize(width: 50, height: -30))
    let scaleBeforeConfirm = viewModel.areaViewModel.scale
    let offsetBeforeConfirm = viewModel.areaViewModel.offset

    await viewModel.confirm { _ in throw RefusedCrop() }

    #expect(!viewModel.isLocked)
    #expect(viewModel.canConfirm)
    #expect(viewModel.areaViewModel.scale == scaleBeforeConfirm)
    #expect(viewModel.areaViewModel.offset == offsetBeforeConfirm)
  }

  /// Confirm after a refused crop calls `onCrop` again, with the crop of the framing at
  /// that tap: the 300 pt crop region covers 375 source pixels at zoom 1 and 125 at
  /// zoom 3.
  @Test func confirmAfterOnCropThrowsDeliversTheNewFraming() async {
    let viewModel = viewModelShowingAnImage()
    var deliveredSides: [CGFloat?] = []

    await viewModel.confirm { croppedImage in
      deliveredSides.append(croppedImage?.size.width)
      throw RefusedCrop()
    }
    viewModel.areaViewModel.pinchEnded(magnification: 3)
    await viewModel.confirm { deliveredSides.append($0?.size.width) }

    #expect(deliveredSides == [375, 125])
  }

  /// A stored synchronous `onCrop`, as apps passed it before it could be async, still runs
  /// on the main thread, where it can update UI state. `CropImageView` calls it through a
  /// closure of the async type, as here. This checks the compiler rather than CropImage:
  /// Swift 6 won't let `confirm` send `onCrop` off the main actor, so the test fails only
  /// on a compiler that runs a converted synchronous function off the caller's actor.
  @Test func storedSynchronousOnCropRunsOnTheMainThread() async {
    let viewModel = viewModelShowingAnImage()
    var ranOnMainThread: Bool?
    let storedOnCrop: (UIImage?) -> Void = { _ in ranOnMainThread = Thread.isMainThread }
    let onCrop: (UIImage?) async throws -> Void = storedOnCrop

    await viewModel.confirm { croppedImage in try await onCrop(croppedImage) }

    #expect(ranOnMainThread == true)
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

/// The error an `onCrop` throws to refuse a crop.
private struct RefusedCrop: Error {}
