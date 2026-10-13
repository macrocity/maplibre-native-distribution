// swift-tools-version:5.3
import PackageDescription

// Renderer source: 69cefcf5c157947b187f8a08d35222435a0a37c8
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-69cefcf5-v1/MapLibre.xcframework.zip",
        checksum: "a15307c9f3895342b689c5657f8047593e131c6105d1d92028bfac5a7b077f4a"
    )]
)
