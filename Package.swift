// swift-tools-version:5.3
import PackageDescription

// Renderer source: aa173accdff15a104e3f9fee323fe0953866c3be
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-aa173acc-v1/MapLibre.xcframework.zip",
        checksum: "96362e4718866a3c189d99f64c477c0dee4507cb6e32d6ea8da824976e1b3efd"
    )]
)
