//
//  CropImageViewModel.swift
//  CropImage
//
//  Created by Quien on 2026-11-05.
//

import SwiftUI

/// Where Confirm is: waiting for a tap, waiting for `onCrop`, or done once `onCrop`
/// returned.
private enum ConfirmPhase {
  case ready
  case running
  case done
}

/// The view model of `CropImageView`: its crop area's view model, and where Confirm is,
/// so the screen waits for `onCrop` and keeps the first crop it accepts.
@MainActor
@Observable
final class CropImageViewModel {
  // MARK: - Properties
  /// The view model of the screen's `CropArea`.
  let areaViewModel = CropAreaViewModel()
  private var confirmPhase = ConfirmPhase.ready

  // MARK: - Computed
  /// Whether Confirm is enabled: the area shows an image, `onCrop` isn't running, and it
  /// hasn't accepted a crop.
  var canConfirm: Bool {
    areaViewModel.image != nil && confirmPhase == .ready
  }

  /// Whether the screen is locked: `onCrop` is running, or it returned and the screen is
  /// closing.
  var isLocked: Bool {
    confirmPhase != .ready
  }

  // MARK: - Functions
  /// Calls `onCrop` with the crop of the current framing and waits for it, unless it is
  /// running or has accepted a crop. When it returns, Confirm stays unavailable; when it
  /// throws, the error is dropped and Confirm is available again.
  func confirm(onCrop: (UIImage?) async throws -> Void) async {
    guard confirmPhase == .ready else { return }
    confirmPhase = .running
    do {
      try await onCrop(areaViewModel.crop())
      confirmPhase = .done
    } catch {
      confirmPhase = .ready
    }
  }
}
