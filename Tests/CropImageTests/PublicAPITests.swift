//
//  PublicAPITests.swift
//  CropImage
//
//  Created by Quien on 2026-11-05.
//

import CropImage
import SwiftUI
import Testing

/// Uses only what an app sees: this file imports `CropImage` without `@testable`, so it
/// stops compiling if any of these lose their `public`.
@MainActor
struct PublicAPITests {
  /// An app can build its own crop screen from `CropArea` and `CropAreaViewModel`, and give
  /// the ready-made screen its own title.
  @Test func anAppCanBuildItsOwnCropScreen() {
    let viewModel = CropAreaViewModel()
    _ = CropArea(image: nil, cropShape: .square, viewModel: viewModel, showsGrid: true)
    _ = CropImageView(image: nil, cropShape: .circle, title: "Frame your photo") { _ in }

    viewModel.reset()

    #expect(viewModel.crop() == nil)
  }

  /// `onCrop` takes a stored synchronous function, as well as an async closure that throws
  /// to keep the screen open and updates the app's main-actor state without `await`.
  @Test func onCropTakesSynchronousAndAsyncThrowingClosures() {
    let viewModel = CropAreaViewModel()
    let storedOnCrop: (UIImage?) -> Void = { _ in }
    _ = CropImageView(image: nil, cropShape: .square, onCrop: storedOnCrop)
    _ = CropImageView(image: nil, cropShape: .square) { _ in
      try await Task.sleep(for: .milliseconds(1))
      viewModel.reset()
    }
  }

  /// A synchronous `onCrop` closure stays synchronous, so a function the app also has an
  /// async version of still resolves to the synchronous one, without `await`.
  @Test func synchronousOnCropKeepsCallingSynchronousOverloads() {
    _ = CropImageView(image: nil, cropShape: .square) { croppedImage in
      saveCrop(croppedImage)
    }
  }
}

/// An app's function with a synchronous and an async version.
private func saveCrop(_ image: UIImage?) {}

/// The async version of `saveCrop`, which a synchronous `onCrop` must not pick.
private func saveCrop(_ image: UIImage?) async {}
