// swift-tools-version:5.3
import PackageDescription

// Renderer source: 9b051a164173ac39493338ffd15392414c151ae2
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-9b051a16-v1/MapLibre.xcframework.zip",
        checksum: "bda3c61c341dabf443908de5158b2f8602411d007b94ca3a0ec133a7f7fe4218"
    )]
)
