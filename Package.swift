// swift-tools-version:5.3
import PackageDescription

// Renderer source: c5a88b70e77db467f1e114affda97c57e71e8323
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-c5a88b70-v2/MapLibre.xcframework.zip",
        checksum: "7d2079cbcebcb284cec92510bde4d0d3d4a2935e74db16861c7b343314e60a22"
    )]
)
