# SwiftLiftKit

A Swift package for lifting subjects out of images on iOS. Uses Apple's Vision framework to generate foreground masks (iOS 17+) with a person-segmentation fallback (iOS 16+), producing images with transparent backgrounds.

## Requirements

- iOS 16.0+
- Swift 6.0+

## Installation

Add SwiftLiftKit to your project via Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/mrwinson/SwiftLiftKit.git", from: "1.0.0")
]
```

Or in Xcode: **File > Add Package Dependencies** and paste the repository URL.

## Usage

### Lift a subject from an existing image

```swift
import SwiftLiftKit

let cutout = try await SwiftLiftKit.liftSubject(from: someUIImage)
// cutout is a UIImage with a transparent background
```

### Capture a photo and lift the subject

```swift
import SwiftLiftKit

let cutout = try await SwiftLiftKit.captureAndLift(presenter: viewController)
```

If the mask fails, the original photo is returned by default. Pass `preferOriginalIfNoMask: false` to throw instead:

```swift
let cutout = try await SwiftLiftKit.captureAndLift(
    presenter: viewController,
    preferOriginalIfNoMask: false
)
```

### SwiftUI

Use `SubjectLiftCameraView` to present a camera and receive the cut-out:

```swift
import SwiftLiftKit

struct ContentView: View {
    @State private var showCamera = false
    @State private var result: UIImage?

    var body: some View {
        Button("Lift Subject") { showCamera = true }
            .sheet(isPresented: $showCamera) {
                SubjectLiftCameraView { image in
                    result = image
                    showCamera = false
                }
            }
    }
}
```

## Error Handling

`SwiftLiftKit` throws `SubjectLiftError`:

| Case | Meaning |
|---|---|
| `.noMaskProduced` | Vision could not generate a foreground mask |
| `.cameraUnavailable` | Device has no camera |
| `.cameraDenied` | User denied camera permission |
| `.presentationFailed` | Camera was cancelled or failed to return an image |

## How It Works

1. The input image is normalized to upright RGBA8 sRGB.
2. On iOS 17+, `VNGenerateForegroundInstanceMaskRequest` isolates the foreground subject.
3. On iOS 16, `VNGeneratePersonSegmentationRequest` is used as a fallback (people only).
4. The mask is blended with a transparent background using Core Image.

## License

See [LICENSE](LICENSE) for details.
