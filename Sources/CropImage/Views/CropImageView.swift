//
//  CropImageView.swift
//  CropImage
//
//  Created by Quien on 2026-06-01.
//

import SwiftUI

/// An interactive view that lets the user pan and zoom an image within a fixed
/// crop region, then returns the cropped result via `onCrop`.
public struct CropImageView: View {
  // MARK: - Environment
  @Environment(\.dismiss) private var dismiss

  // MARK: - State
  @State private var viewModel: CropImageViewModel

  // MARK: - Properties
  private let onCrop: (UIImage?) -> Void

  // MARK: - Init
  public init(
    image: UIImage?,
    cropShape: CropShape,
    onCrop: @escaping (UIImage?) -> Void
  ) {
    _viewModel = State(
      initialValue: CropImageViewModel(image: image, cropShape: cropShape)
    )
    self.onCrop = onCrop
  }

  // MARK: - Body
  public var body: some View {
    NavigationStack {
      GeometryReader { geo in
        let side = min(geo.size.width * 0.75, 400)
        let cropSize = CGSize(width: side, height: side)
        let containerSize = geo.size

        VStack {
          Spacer()

          ZStack {
            if let image = viewModel.image {
              Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .scaleEffect(viewModel.scale)
                .offset(viewModel.offset)
                .gesture(
                  dragGesture(cropSize: cropSize, containerSize: containerSize)
                )
                .gesture(
                  magnificationGesture(
                    cropSize: cropSize,
                    containerSize: containerSize
                  )
                )
            }

            CropMaskView(shape: viewModel.cropShape, cropSize: cropSize)
          }  // ZStack
          .frame(width: geo.size.width, height: geo.size.height)
          .clipped()

          Spacer()
        }  // VStack
        .navigationTitle("Crop your photo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button(role: .close) {
              dismiss()
            }
          }  // ToolbarItem
          ToolbarItem(placement: .confirmationAction) {
            Button(role: .confirm) {
              onCrop(
                viewModel.crop(cropSize: cropSize, containerSize: containerSize)
              )
              dismiss()
            }
          }  // ToolbarItem
        }  // toolbar
      }  // GeometryReader
    }  // NavigationStack
  }

  // MARK: - Gestures
  private func dragGesture(cropSize: CGSize, containerSize: CGSize)
    -> some Gesture
  {
    DragGesture()
      .onChanged { viewModel.dragChanged($0) }
      .onEnded { _ in
        viewModel.dragEnded(cropSize: cropSize, containerSize: containerSize)
      }
  }

  private func magnificationGesture(cropSize: CGSize, containerSize: CGSize)
    -> some Gesture
  {
    MagnificationGesture()
      .onChanged { viewModel.magnificationChanged($0) }
      .onEnded { _ in
        viewModel.magnificationEnded(
          cropSize: cropSize,
          containerSize: containerSize
        )
      }
  }
}

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
