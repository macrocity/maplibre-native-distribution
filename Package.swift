// swift-tools-version:5.3
import PackageDescription

// Renderer source: c978ac5c2ef6606bf471217f52feabc5e8419b71
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-c978ac5c-v1/MapLibre.xcframework.zip",
        checksum: "85530d10a7aa1debee8bfcca55d1c8a1bfd74d5fe7b542c12da74f341c0e8fb5"
    )]
)
