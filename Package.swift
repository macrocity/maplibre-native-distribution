// swift-tools-version:5.3
import PackageDescription

// Renderer source: 779568e91746d2ea0d093b1dcb1de0a4a3d5b815
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-779568e9-v1/MapLibre.xcframework.zip",
        checksum: "7c1a24cedef3402da0bed1dd4f9146ce336bdfb074e30b8c0df0b99436962b01"
    )]
)
