// swift-tools-version:5.3
import PackageDescription

// Renderer source: 0cf262de84b62b02ecd39917352028216141570f
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-0cf262de-v1/MapLibre.xcframework.zip",
        checksum: "2c09fff7b2d1d3c73e04f47bc744a7ef5b5b1b507f4fba69483f5de1ec0a06e4"
    )]
)
