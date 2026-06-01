//
//  CropShapeView.swift
//  CropImage
//
//  Created by Quien on 2026-06-01.
//

import SwiftUI

/// Renders a `CropShape` as a concrete SwiftUI shape at the given size.
struct CropShapeView: View {
  let shape: CropShape
  let size: CGSize

  var body: some View {
    switch shape {
    case .circle:
      Circle().frame(width: size.width, height: size.height)
    case .square:
      Rectangle().frame(width: size.width, height: size.height)
    }
  }
}

#Preview("Circle") {
  CropShapeView(shape: .circle, size: CGSize(width: 200, height: 200))
}

#Preview("Square") {
  CropShapeView(shape: .square, size: CGSize(width: 200, height: 200))
}
