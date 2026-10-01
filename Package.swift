// swift-tools-version:5.3
import PackageDescription

// Renderer source: c875c548eef3154dfabbfbc7459e650ab96baf9d
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-c875c548-v1/MapLibre.xcframework.zip",
        checksum: "f1fb5533a21a1bca2b520204e73bf730221914de10a87ddbf28b2c2a29c5d8bc"
    )]
)
