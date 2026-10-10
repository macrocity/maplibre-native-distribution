// swift-tools-version:5.3
import PackageDescription

// Renderer source: 4af15c315f192b0be3b4965e361cd8349f6055ec
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-4af15c31-v1/MapLibre.xcframework.zip",
        checksum: "8736236d4eb9573906ee9a72fe779365c160017be90fd4d102d83f5a22add15a"
    )]
)
