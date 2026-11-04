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
  @State private var viewModel = CropImageViewModel()

  // MARK: - Properties
  private let image: UIImage?
  private let cropShape: CropShape
  private let outputSide: CGFloat?
  private let onCrop: (UIImage?) -> Void

  // MARK: - Init
  /// Creates a crop view for `image`.
  ///
  /// - Parameter outputSide: The side length, in pixels, of the square image `onCrop`
  ///   receives, greater than 0 and at most 8192. If the selected area has fewer source
  ///   pixels, it is upscaled. When `nil`, the image is the crop region's size in points,
  ///   at scale 1.
  public init(
    image: UIImage?,
    cropShape: CropShape,
    outputSide: CGFloat? = nil,
    onCrop: @escaping (UIImage?) -> Void
  ) {
    if let outputSide {
      precondition(
        outputSide > 0 && outputSide <= 8192,
        "outputSide must be greater than 0 and at most 8192 pixels")
    }
    self.image = image
    self.cropShape = cropShape
    self.outputSide = outputSide
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
            if let image {
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

            CropMaskView(shape: cropShape, cropSize: cropSize)
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
                viewModel.crop(
                  image: image,
                  cropSize: cropSize,
                  containerSize: containerSize,
                  outputSide: outputSide
                )
              )
              dismiss()
            }
          }  // ToolbarItem
        }  // toolbar
      }  // GeometryReader
    }  // NavigationStack
  }

  // MARK: - Gestures
  private func dragGesture(
    cropSize: CGSize,
    containerSize: CGSize
  ) -> some Gesture {
    DragGesture()
      .onChanged { viewModel.dragChanged($0) }
      .onEnded { _ in
        viewModel.dragEnded(
          imageSize: image?.size,
          cropSize: cropSize,
          containerSize: containerSize
        )
      }
  }

  private func magnificationGesture(
    cropSize: CGSize,
    containerSize: CGSize
  ) -> some Gesture {
    MagnificationGesture()
      .onChanged { viewModel.magnificationChanged($0) }
      .onEnded { _ in
        viewModel.magnificationEnded(
          imageSize: image?.size,
          cropSize: cropSize,
          containerSize: containerSize
        )
      }
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
#endif
