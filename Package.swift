// swift-tools-version:5.3
import PackageDescription

// Renderer source: e4be05b5e6c0488b2b8935ecbe67e14bad227ae0
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-e4be05b5-v1/MapLibre.xcframework.zip",
        checksum: "d67f6fa1b9e0490b2bf94053ed1a01bfb42102ff2e27d87bc5c3524a5892a0df"
    )]
)
