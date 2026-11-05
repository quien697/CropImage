//
//  CropImageViewModel.swift
//  CropImage
//
//  Created by Quien on 2026-11-05.
//

import SwiftUI

/// The view model of `CropImageView`: its crop area's view model, and whether Confirm
/// was tapped, so the screen delivers one crop.
@MainActor
@Observable
final class CropImageViewModel {
  /// The view model of the screen's `CropArea`.
  let areaViewModel = CropAreaViewModel()
  private var isConfirmed = false

  /// Whether Confirm is enabled: the area shows an image, and Confirm wasn't tapped yet.
  var canConfirm: Bool {
    areaViewModel.image != nil && !isConfirmed
  }

  /// Calls `onCrop` with the crop the first time Confirm is tapped, and does nothing
  /// after that.
  func confirm(outputSide: CGFloat?, onCrop: (UIImage?) -> Void) {
    guard !isConfirmed else { return }
    isConfirmed = true
    onCrop(areaViewModel.crop(outputSide: outputSide))
  }
}
