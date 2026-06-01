//
//  PreviewImage.swift
//  CropImage
//
//  Created by Quien on 2026-06-01.
//

#if DEBUG
  import UIKit

  /// A gradient placeholder image used by SwiftUI previews.
  func previewImage(width: CGFloat, height: CGFloat) -> UIImage {
    let size = CGSize(width: width, height: height)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { ctx in
      let colors = [UIColor.systemBlue, UIColor.systemPurple, UIColor.systemPink]
      let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors.map(\.cgColor) as CFArray,
        locations: [0, 0.5, 1]
      )!
      ctx.cgContext.drawLinearGradient(
        gradient,
        start: .zero,
        end: CGPoint(x: size.width, y: size.height),
        options: []
      )
    }
  }
#endif
