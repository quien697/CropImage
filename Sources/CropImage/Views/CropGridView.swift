//
//  CropGridView.swift
//  CropImage
//
//  Created by Quien on 2026-11-04.
//

import SwiftUI

/// Two vertical and two horizontal one-pixel lines that divide the crop region into
/// thirds, clipped to the crop shape.
struct CropGridView: View {
  @Environment(\.displayScale) private var displayScale

  let shape: CropShape
  let cropSize: CGSize

  var body: some View {
    ThirdsGrid()
      .stroke(.white.opacity(0.5), lineWidth: 1 / displayScale)
      .frame(width: cropSize.width, height: cropSize.height)
      .mask(CropShapeView(shape: shape, size: cropSize))
      .allowsHitTesting(false)
  }
}

/// The lines at a third and two thirds of the way across and down a rectangle.
private struct ThirdsGrid: Shape {
  /// The four grid lines inside `rect`.
  func path(in rect: CGRect) -> Path {
    var path = Path()
    for third in [1.0, 2.0] {
      let x = rect.minX + rect.width * third / 3
      path.move(to: CGPoint(x: x, y: rect.minY))
      path.addLine(to: CGPoint(x: x, y: rect.maxY))
      let y = rect.minY + rect.height * third / 3
      path.move(to: CGPoint(x: rect.minX, y: y))
      path.addLine(to: CGPoint(x: rect.maxX, y: y))
    }
    return path
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
    CropGridView(shape: .circle, cropSize: CGSize(width: 250, height: 250))
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
    CropGridView(shape: .square, cropSize: CGSize(width: 250, height: 250))
  }
  .ignoresSafeArea()
}
