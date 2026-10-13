// swift-tools-version:5.3
import PackageDescription

// Renderer source: 4a4c53dff729899cbf5c252dd4ba2f36cf8110fe
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-4a4c53df-v1/MapLibre.xcframework.zip",
        checksum: "4ec0fb3f00b293cfb9186ee609384683bd1eb5e05a6068e4be61c45268cdd250"
    )]
)
