// swift-tools-version:5.3
import PackageDescription

// Renderer source: 9d0d76707e6f6917e8001e97e5229273d330bbcc
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-9d0d7670-v1/MapLibre.xcframework.zip",
        checksum: "c5d3b575ee03733270f7ab322cf21187b40c8a6fdc16f3402e0b83d096c73b8a"
    )]
)
