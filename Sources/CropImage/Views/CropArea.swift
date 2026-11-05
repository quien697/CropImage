//
//  CropArea.swift
//  CropImage
//
//  Created by Quien on 2026-11-04.
//

import SwiftUI

/// The image with pinch and drag, and the dimmed surround with the crop shape's hole,
/// filling the space you give it.
///
/// Build your own crop screen around it: keep a `CropAreaViewModel` in that screen's
/// `@State`, pass it in, and call its `crop(outputSide:)` and `reset()` from your own
/// buttons.
public struct CropArea: View {
  // MARK: - State
  @GestureState(resetTransaction: Transaction(animation: .cropSettle))
  private var dragTranslation: CGSize = .zero
  @GestureState(resetTransaction: Transaction(animation: .cropSettle))
  private var pinchMagnification: CGFloat = 1

  // MARK: - Properties
  private let image: UIImage?
  private let cropShape: CropShape
  private let viewModel: CropAreaViewModel
  private let showsGrid: Bool

  // MARK: - Init
  /// Creates a crop area for `image`, cropped and reset through `viewModel`.
  ///
  /// - Parameters:
  ///   - image: The image to crop. It can arrive after the area appears.
  ///   - cropShape: The shape of the hole in the dimming.
  ///   - viewModel: The view model that crops and resets this area. Give each area
  ///     its own.
  ///   - showsGrid: Whether lines divide the crop region into thirds. They are never part
  ///     of the cropped image.
  public init(
    image: UIImage?,
    cropShape: CropShape,
    viewModel: CropAreaViewModel,
    showsGrid: Bool = false
  ) {
    self.image = image
    self.cropShape = cropShape
    self.viewModel = viewModel
    self.showsGrid = showsGrid
  }

  // MARK: - Body
  public var body: some View {
    GeometryReader { geo in
      let cropSize = CropGeometry.cropSize(containerSize: geo.size)

      ZStack {
        if let image {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .scaleEffect(viewModel.shownScale(pinch: pinchMagnification))
            .offset(viewModel.shownOffset(drag: dragTranslation))
            .gesture(dragGesture)
            .gesture(pinchGesture)
        }

        CropMaskView(shape: cropShape, cropSize: cropSize)

        if showsGrid {
          CropGridView(shape: cropShape, cropSize: cropSize)
        }
      }  // ZStack
      .frame(width: geo.size.width, height: geo.size.height)
      .clipped()
      .onChange(of: geo.size, initial: true) {
        viewModel.areaSizeChanged(to: geo.size)
      }
      // By identity: UIImage's == compares pixel data.
      .onChange(of: image.map(ObjectIdentifier.init), initial: true) {
        viewModel.imageChanged(to: image)
      }
      // A view model the app swaps in needs the size and image too.
      .onChange(of: ObjectIdentifier(viewModel)) {
        viewModel.areaSizeChanged(to: geo.size)
        viewModel.imageChanged(to: image)
      }
    }  // GeometryReader
  }

  // MARK: - Gestures
  /// Tracks a drag in `dragTranslation` while it lasts and hands it to the view model
  /// when it ends. A cancelled drag never reaches `onEnded`, so the image returns to the
  /// settled framing as `dragTranslation` resets.
  private var dragGesture: some Gesture {
    DragGesture()
      .updating($dragTranslation) { value, translation, _ in
        translation = value.translation
      }
      .onEnded { value in
        viewModel.dragEnded(translation: value.translation)
      }
  }

  /// Tracks a pinch in `pinchMagnification` while it lasts and hands it to the
  /// view model when it ends. A cancelled pinch returns the image to the settled framing.
  private var pinchGesture: some Gesture {
    MagnifyGesture()
      .updating($pinchMagnification) { value, magnification, _ in
        magnification = value.magnification
      }
      .onEnded { value in
        viewModel.pinchEnded(magnification: value.magnification)
      }
  }
}

#if DEBUG
  /// A screen an app might build around `CropArea`, with the view model in its own
  /// `@State` so each visit starts at the initial framing.
  private struct FramePhotoPreviewScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CropAreaViewModel()

    let image: UIImage
    let onFramed: (UIImage) -> Void

    var body: some View {
      CropArea(image: image, cropShape: .square, viewModel: viewModel, showsGrid: true)
        .navigationTitle("Frame your photo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .bottomBar) {
            Button("Reset") {
              viewModel.reset()
            }
          }  // ToolbarItem
          ToolbarItem(placement: .confirmationAction) {
            Button(role: .confirm) {
              if let framedImage = viewModel.crop(outputSide: 840) {
                onFramed(framedImage)
              }
              dismiss()
            }
          }  // ToolbarItem
        }  // toolbar
    }
  }

  #Preview("App's own screen") {
    @Previewable @State var image = previewImage(width: 800, height: 600)
    @Previewable @State var framedImage: UIImage?

    NavigationStack {
      List {
        NavigationLink("Frame your photo") {
          FramePhotoPreviewScreen(image: image) { framedImage = $0 }
        }  // NavigationLink

        if let framedImage {
          Image(uiImage: framedImage)
            .resizable()
            .scaledToFit()
            .frame(height: 160)
        }
      }  // List
    }  // NavigationStack
  }

  #Preview("Grid on a circle") {
    @Previewable @State var viewModel = CropAreaViewModel()
    @Previewable @State var image = previewImage(width: 600, height: 800)

    CropArea(image: image, cropShape: .circle, viewModel: viewModel, showsGrid: true)
  }
#endif
