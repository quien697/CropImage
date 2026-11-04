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
  @GestureState(resetTransaction: Transaction(animation: .cropSettle))
  private var dragTranslation: CGSize = .zero
  @GestureState(resetTransaction: Transaction(animation: .cropSettle))
  private var pinchMagnification: CGFloat = 1

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
        let cropSize = CropGeometry.cropSize(containerSize: geo.size)
        let containerSize = geo.size

        VStack {
          Spacer()

          ZStack {
            if let image {
              Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .scaleEffect(viewModel.shownScale(pinch: pinchMagnification))
                .offset(viewModel.shownOffset(drag: dragTranslation))
                .gesture(
                  dragGesture(cropSize: cropSize, containerSize: containerSize)
                )
                .gesture(
                  pinchGesture(cropSize: cropSize, containerSize: containerSize)
                )
            }

            CropMaskView(shape: cropShape, cropSize: cropSize)
          }  // ZStack
          .frame(width: geo.size.width, height: geo.size.height)
          .clipped()

          Spacer()
        }  // VStack
        .onChange(of: geo.size) {
          viewModel.settle(
            imageSize: image?.size,
            cropSize: cropSize,
            containerSize: containerSize
          )
        }
        .onChange(of: image?.size) {
          viewModel.settle(
            imageSize: image?.size,
            cropSize: cropSize,
            containerSize: containerSize
          )
        }
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
  /// Tracks a drag in `dragTranslation` while it lasts and hands it to the view model
  /// when it ends. A cancelled drag never reaches `onEnded`, so the image returns to the
  /// settled framing as `dragTranslation` resets.
  private func dragGesture(
    cropSize: CGSize,
    containerSize: CGSize
  ) -> some Gesture {
    DragGesture()
      .updating($dragTranslation) { value, translation, _ in
        translation = value.translation
      }
      .onEnded { value in
        viewModel.dragEnded(
          translation: value.translation,
          imageSize: image?.size,
          cropSize: cropSize,
          containerSize: containerSize
        )
      }
  }

  /// Tracks a pinch in `pinchMagnification` while it lasts and hands it to the view
  /// model when it ends. A cancelled pinch returns the image to the settled framing.
  private func pinchGesture(
    cropSize: CGSize,
    containerSize: CGSize
  ) -> some Gesture {
    MagnifyGesture()
      .updating($pinchMagnification) { value, magnification, _ in
        magnification = value.magnification
      }
      .onEnded { value in
        viewModel.pinchEnded(
          magnification: value.magnification,
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
