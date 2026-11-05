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

    #expect(viewModel.crop(outputSide: 840) == nil)
  }
}
