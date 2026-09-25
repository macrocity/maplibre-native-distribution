// swift-tools-version:5.3
import PackageDescription

// Renderer source: c9f2f6e1b9ee198f7938a54c0864676587476edd
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-c9f2f6e1-v1/MapLibre.xcframework.zip",
        checksum: "b9a8124de36603d05cbf439485650b6e0d1befb3c98e7fc10aa7938f37bf8833"
    )]
)
