// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "CropImage",
  platforms: [
    .iOS("26.0")
  ],
  products: [
    .library(name: "CropImage", targets: ["CropImage"])
  ],
  targets: [
    .target(name: "CropImage"),
  ],
  swiftLanguageModes: [.v6]
)
