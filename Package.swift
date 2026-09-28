// swift-tools-version:5.3
import PackageDescription

// Renderer source: c5a88b70e77db467f1e114affda97c57e71e8323
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-c5a88b70-v1/MapLibre.xcframework.zip",
        checksum: "578f48cac7f7e927d678566826a0dbf900109f1ffdc50e92eb7bd17391b9e4e0"
    )]
)
