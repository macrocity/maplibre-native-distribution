// swift-tools-version:5.3
import PackageDescription

// Renderer source: 524a0dcecf99e097c22cc9ea808cbdd7484e8808
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-524a0dce-v1/MapLibre.xcframework.zip",
        checksum: "335fb15a659a4efe3b5d96db59070efd8a4602f5f57b1405a3aa10baea66e9b2"
    )]
)
