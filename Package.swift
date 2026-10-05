// swift-tools-version:5.3
import PackageDescription

// Renderer source: 3ed3cb3ee1ce7e868ea5458b50877c525dd12ea7
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-3ed3cb3e-v1/MapLibre.xcframework.zip",
        checksum: "51515f768a2be3f56f0b6695fca9441389dc539b2f64510a02b475259571ba62"
    )]
)
