//
//  CropImageView.swift
//  CropImage
//
//  Created by Quien on 2026-06-01.
//

import SwiftUI

/// A ready-made crop screen: a `CropArea` in a navigation stack with close and confirm
/// buttons, which delivers the cropped image through `onCrop` and dismisses itself once
/// `onCrop` returns.
public struct CropImageView: View {
  // MARK: - Environment
  @Environment(\.dismiss) private var dismiss

  // MARK: - State
  @State private var viewModel = CropImageViewModel()

  // MARK: - Properties
  private let image: UIImage?
  private let cropShape: CropShape
  private let title: LocalizedStringKey
  private let onCrop: (UIImage?) async throws -> Void

  // MARK: - Init
  /// Creates a crop view for `image`.
  ///
  /// - Parameters:
  ///   - image: The image to crop. Confirm stays disabled until there is one with
  ///     pixels, so `onCrop` receives `nil` only if rendering fails.
  ///   - cropShape: The shape of the hole in the dimming.
  ///   - title: The navigation title, looked up in your app's strings like any SwiftUI
  ///     title.
  ///   - onCrop: Receives the cropped image when the user confirms: a square of the
  ///     source pixels the crop region covers, at full resolution and scale 1. CropImage
  ///     calls it from the main actor, so a closure you write in a view runs there and
  ///     can update the view's state; a `nonisolated` async function runs where its own
  ///     isolation says. The screen stays open until it returns: while it runs, Confirm
  ///     shows progress, and the user can't close the screen or move the image. Throw
  ///     to refuse the crop: the screen stays open with the same framing, so the user
  ///     can adjust it and confirm again, or close. CropImage shows no message of its
  ///     own, so show yours for every error you throw, from an alert or sheet attached
  ///     to this view. `onCrop` must finish: give work that waits on the network its
  ///     own timeout.
  public init(
    image: UIImage?,
    cropShape: CropShape,
    title: LocalizedStringKey = "Crop your photo",
    onCrop: @escaping (UIImage?) async throws -> Void
  ) {
    self.image = image
    self.cropShape = cropShape
    self.title = title
    self.onCrop = onCrop
  }

  // MARK: - Body
  public var body: some View {
    NavigationStack {
      CropArea(image: image, cropShape: cropShape, viewModel: viewModel.areaViewModel)
        .allowsHitTesting(!viewModel.isLocked)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button(role: .close) {
              dismiss()
            }
            .disabled(viewModel.isLocked)
          }  // ToolbarItem
          ToolbarItem(placement: .confirmationAction) {
            if viewModel.isLocked {
              ProgressView()
            } else {
              Button(role: .confirm) {
                Task {
                  await viewModel.confirm { croppedImage in
                    try await onCrop(croppedImage)
                    dismiss()
                  }
                }
              }
              .disabled(!viewModel.canConfirm)
            }
          }  // ToolbarItem
        }  // toolbar
    }  // NavigationStack
    .interactiveDismissDisabled(viewModel.isLocked)
  }
}

#if DEBUG
  #Preview("Circle crop") {
    CropImageView(
      image: previewImage(width: 800, height: 600),
      cropShape: .circle,
      onCrop: { _ in }
    )
  }

  #Preview("Square crop") {
    CropImageView(
      image: previewImage(width: 600, height: 800),
      cropShape: .square,
      onCrop: { _ in }
    )
  }

  #Preview("Custom title") {
    CropImageView(
      image: previewImage(width: 800, height: 600),
      cropShape: .square,
      title: "Frame your photo",
      onCrop: { _ in }
    )
  }

  #Preview("No image") {
    CropImageView(
      image: nil,
      cropShape: .circle,
      onCrop: { _ in }
    )
  }

  #Preview("Slow confirm") {
    @Previewable @State var image = previewImage(width: 800, height: 600)
    @Previewable @State var isPresentingCrop = false
    @Previewable @State var croppedImage: UIImage?

    VStack {
      Button("Crop photo") {
        isPresentingCrop = true
      }

      if let croppedImage {
        Image(uiImage: croppedImage)
          .resizable()
          .scaledToFit()
          .frame(height: 160)
      }
    }  // VStack
    .sheet(isPresented: $isPresentingCrop) {
      CropImageView(image: image, cropShape: .circle) { result in
        try await Task.sleep(for: .seconds(2))
        croppedImage = result
      }
    }  // sheet
  }

  /// The error the "Refused crop" preview's `onCrop` throws.
  private struct RefusedCropPreviewError: Error {}

  #Preview("Refused crop") {
    @Previewable @State var image = previewImage(width: 800, height: 600)
    @Previewable @State var isPresentingCrop = false

    Button("Crop photo") {
      isPresentingCrop = true
    }
    .sheet(isPresented: $isPresentingCrop) {
      CropImageView(image: image, cropShape: .square) { _ in
        try await Task.sleep(for: .seconds(2))
        throw RefusedCropPreviewError()
      }
    }  // sheet
  }
#endif
