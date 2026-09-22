// swift-tools-version:5.3
import PackageDescription

// Renderer source: 4bdc8a58c5dab7e76af75effff7661437e314486
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-4bdc8a58-v1/MapLibre.xcframework.zip",
        checksum: "b3e301ef698776f7e0e34abcb73cc5253e263a00cb10875466089bf654f1661b"
    )]
)
