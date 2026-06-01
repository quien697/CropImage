# CropImage

![iOS](https://img.shields.io/badge/iOS-26-blue.svg) ![Swift](https://img.shields.io/badge/Swift-6-orange.svg) ![SwiftUI](https://img.shields.io/badge/SwiftUI-brightgreen.svg) ![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg) ![Xcode](https://img.shields.io/badge/Xcode-26.5-blue) ![License](https://img.shields.io/badge/license-MIT-green)

A lightweight SwiftUI view for interactively cropping images on iOS.



## 📝 Overview

1. A reusable SwiftUI component for cropping images, distributed via Swift Package Manager.
2. Lets users pan and pinch-to-zoom an image inside a fixed crop region, then returns the cropped result.
3. Supports circle and square crop shapes.
4. Built with pure SwiftUI and no third-party dependencies.
5. Follows MVVM architecture for clean separation of concerns.



## ✨ Features

1. **Pan & zoom** — drag and pinch to position the image within the crop region.
2. **Crop shapes** — choose between a circle or a square mask.
3. **Edge clamping** — the image snaps back so the crop region is always filled.
4. **Simple API** — a single `CropImageView` with an `onCrop` callback.



## 🛠️ Technologies & Frameworks

- iOS 26
- Swift 6
- SwiftUI
- Swift Package Manager - distribution



## 🔧 Development Tools

- Xcode 26.5
- Icons: [SF Symbols](https://developer.apple.com/sf-symbols/)
- Version control: GitHub / Git
- AI tools: [Claude Code](https://claude.com/claude-code)



## 📦 Installation

### Swift Package Manager

Add the package in Xcode via **File → Add Package Dependencies…** and enter the repository URL:

```
https://github.com/quien697/CropImage.git
```

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/quien697/CropImage.git", from: "1.0.0")
]
```



## 💻 Usage

Present `CropImageView` (for example, in a sheet) with an image and a crop shape. The `onCrop` closure delivers the cropped `UIImage` when the user confirms.

```swift
import CropImage
import SwiftUI

struct ContentView: View {
    @State private var sourceImage: UIImage?
    @State private var croppedImage: UIImage?
    @State private var isCropping = false

    var body: some View {
        // ...
        .sheet(isPresented: $isCropping) {
            if let sourceImage {
                CropImageView(image: sourceImage, cropShape: .circle) { result in
                    croppedImage = result
                }
            }
        }
    }
}
```

Available crop shapes:

```swift
public enum CropShape {
    case circle
    case square
}
```



## 📂 Folder Structure

```text
CropImage/
├─ Sources/
│  └─ CropImage/
│     ├─ Models/         # CropShape
│     ├─ ViewModels/     # CropImageViewModel (state, gestures, rendering)
│     ├─ Views/          # CropImageView, CropMaskView, CropShapeView
│     ├─ Utilities/      # CropGeometry (pure geometry helpers)
│     └─ Previews/       # Preview support
└─ Screenshots/
```



## 📸 Screenshots

<p align="left">
   <img src="https://github.com/quien697/CropImage/blob/main/Screenshots/crop-circle.png?raw=true" alt="Circle crop" width="200" />
   <img src="https://github.com/quien697/CropImage/blob/main/Screenshots/crop-square.png?raw=true" alt="Square crop" width="200" />
</p>



## 🚀 Getting Started

Add the package to your project (see [Installation](#-installation)) and present `CropImageView` (see [Usage](#-usage)).

A runnable example app is available on the [`with-demo`](https://github.com/quien697/CropImage/tree/with-demo) branch, demonstrating the full `PhotosPicker → CropImageView → result` flow:

```bash
git checkout with-demo
open CropImageDemo/CropImageDemo.xcodeproj
```



## 👨‍💻 Author

**Tsung-Hsun Liu**  
📧 [quien697@gmail.com](mailto:quien697@gmail.com)  
🌐 [tsunghsun.me](https://www.tsunghsun.me)



## 📄 License

MIT License © 2026 Tsung-Hsun Liu
