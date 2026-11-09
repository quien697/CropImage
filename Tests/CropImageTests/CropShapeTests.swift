//
//  CropShapeTests.swift
//  CropImage
//
//  Created by Quien on 2026-11-04.
//

import Testing

@testable import CropImage

struct CropShapeTests {
  /// A crop shape can be handed to another task, as Swift 6 apps do when they pass one
  /// between actors.
  @Test func cropShapeCanBeSentToAnotherTask() async {
    let shape = CropShape.circle

    let received = await Task.detached { shape }.value

    #expect(received == .circle)
  }
}
