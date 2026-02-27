// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Pirs5PDFCompressor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Pirs5PDFCompressor",
            targets: ["PDFCompressorApp"]
        )
    ],
    targets: [
        .executableTarget(
            name: "PDFCompressorApp",
            path: "Sources/PDFCompressorApp",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
