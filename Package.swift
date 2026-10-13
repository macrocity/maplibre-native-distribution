// swift-tools-version:5.3
import PackageDescription

// Renderer source: d10493c17b6f55e9c30e161dc039ff93e0b3d2b6
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-d10493c1-v1/MapLibre.xcframework.zip",
        checksum: "0f67cf8c0244d8f596158d5a4519413aab258a1023c6ed330729d3c9dfab7326"
    )]
)
