//
//  CropMaskView.swift
//  CropImage
//
//  Created by Quien on 2026-06-01.
//

import SwiftUI

/// A dimming overlay that punches a `CropShape`-sized hole in its center,
/// revealing the image underneath through the crop region.
struct CropMaskView: View {
  let shape: CropShape
  let cropSize: CGSize

  var body: some View {
    Rectangle()
      .fill(.black.opacity(0.5))
      .overlay {
        CropShapeView(shape: shape, size: cropSize)
          .blendMode(.destinationOut)
      }
      .compositingGroup()
      .allowsHitTesting(false)
  }
}

#Preview("Circle") {
  ZStack {
    LinearGradient(
      colors: [.blue, .purple, .pink],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
    CropMaskView(shape: .circle, cropSize: CGSize(width: 250, height: 250))
  }
  .ignoresSafeArea()
}

#Preview("Square") {
  ZStack {
    LinearGradient(
      colors: [.blue, .purple, .pink],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
    CropMaskView(shape: .square, cropSize: CGSize(width: 250, height: 250))
  }
  .ignoresSafeArea()
}
