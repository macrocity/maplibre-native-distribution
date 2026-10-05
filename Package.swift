// swift-tools-version:5.3
import PackageDescription

// Renderer source: b95160d5dce6e60b901082aa1e7fcf18656bc3dc
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-b95160d5-v1/MapLibre.xcframework.zip",
        checksum: "5657c8cf0039f1dab16ca5c23c1df9a6eaf9943ce77322c4378c95ffb4cb841d"
    )]
)
