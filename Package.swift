// swift-tools-version:5.3
import PackageDescription

// Renderer source: b09629125bda8170deaae2231455f98edd6d064d
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-b0962912-v1/MapLibre.xcframework.zip",
        checksum: "9d26aa4be133aa262df537c79031ac02835ac61b7019d88c3d6ce3cba00cb504"
    )]
)
