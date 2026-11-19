//
//  CropImageView.swift
//  CropImage
//
//  Created by Quien on 2026-06-01.
//

import SwiftUI

/// A ready-made crop screen: a `CropArea` in a navigation stack with close and confirm
/// buttons, which delivers the cropped image through `onCrop` and dismisses itself.
public struct CropImageView: View {
  // MARK: - Environment
  @Environment(\.dismiss) private var dismiss

  // MARK: - State
  @State private var viewModel = CropImageViewModel()

  // MARK: - Properties
  private let image: UIImage?
  private let cropShape: CropShape
  private let title: LocalizedStringKey
  private let onCrop: (UIImage?) -> Void

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
  ///     source pixels the crop region covers, at full resolution and scale 1.
  public init(
    image: UIImage?,
    cropShape: CropShape,
    title: LocalizedStringKey = "Crop your photo",
    onCrop: @escaping (UIImage?) -> Void
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
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button(role: .close) {
              dismiss()
            }
          }  // ToolbarItem
          ToolbarItem(placement: .confirmationAction) {
            Button(role: .confirm) {
              viewModel.confirm { croppedImage in
                onCrop(croppedImage)
                dismiss()
              }
            }
            .disabled(!viewModel.canConfirm)
          }  // ToolbarItem
        }  // toolbar
    }  // NavigationStack
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
#endif
