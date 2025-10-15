// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftLiftKit",
    platforms: [.iOS(.v16)], // uses Vision foreground mask on iOS 17+, people fallback earlier
    products: [
        .library(name: "SwiftLiftKit", targets: ["SwiftLiftKit"])
    ],
    targets: [
        .target(
            name: "SwiftLiftKit",
            dependencies: [],
            path: "Sources/SwiftLiftKit",
            resources: []
        )
    ]
)
