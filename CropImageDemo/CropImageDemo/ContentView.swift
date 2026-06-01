//
//  ContentView.swift
//  CropImageDemo
//
//  Created by Quien on 2026-06-01.
//

import CropImage
import PhotosUI
import SwiftUI

struct ContentView: View {
  @State private var pickerItem: PhotosPickerItem?
  @State private var sourceImage: UIImage?
  @State private var croppedImage: UIImage?
  @State private var cropShape: CropShape = .circle
  @State private var isCropping = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        preview
          .frame(maxWidth: .infinity, maxHeight: 360)

        Picker("Crop shape", selection: $cropShape) {
          Text("Circle").tag(CropShape.circle)
          Text("Square").tag(CropShape.square)
        }
        .pickerStyle(.segmented)

        HStack {
          PhotosPicker("Pick photo", selection: $pickerItem, matching: .images)
            .buttonStyle(.bordered)

          Button("Crop") { isCropping = true }
            .buttonStyle(.borderedProminent)
            .disabled(sourceImage == nil)
        }

        Spacer()
      }
      .padding()
      .navigationTitle("CropImage Demo")
    }
    .onChange(of: pickerItem) {
      Task { await loadPickedImage() }
    }
    .sheet(isPresented: $isCropping) {
      if let sourceImage {
        CropImageView(image: sourceImage, cropShape: cropShape) { result in
          croppedImage = result
        }
      }
    }
  }

  // MARK: - Subviews
  @ViewBuilder
  private var preview: some View {
    if let croppedImage {
      Image(uiImage: croppedImage)
        .resizable()
        .scaledToFit()
        .clipShape(.rect(cornerRadius: 12))
    } else if let sourceImage {
      Image(uiImage: sourceImage)
        .resizable()
        .scaledToFit()
        .opacity(0.4)
        .overlay { Text("Tap Crop to start") }
    } else {
      ContentUnavailableView(
        "No photo",
        systemImage: "photo.on.rectangle.angled",
        description: Text("Pick a photo to crop")
      )
    }
  }

  // MARK: - Actions
  private func loadPickedImage() async {
    guard
      let data = try? await pickerItem?.loadTransferable(type: Data.self),
      let image = UIImage(data: data)
    else { return }

    sourceImage = image
    croppedImage = nil
    isCropping = true
  }
}

#Preview {
  ContentView()
}
