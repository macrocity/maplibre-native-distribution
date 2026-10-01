// swift-tools-version:5.3
import PackageDescription

// Renderer source: 152ccaf04df8f28643a7f358b7920f8377474d95
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-152ccaf0-v1/MapLibre.xcframework.zip",
        checksum: "368662ef7d5556c255ce58fad1e07be20cadb5017a3635823d17b010a95abe51"
    )]
)
