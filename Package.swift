// swift-tools-version:5.3
import PackageDescription

// Renderer source: de5c9f0b1842270ac0a9558deda9e805a31d1ea9
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-de5c9f0b-v1/MapLibre.xcframework.zip",
        checksum: "0d65d7222f17ebc5fd3baa87a6be81fc77469b9e43a50bc5617f526b94beb0cc"
    )]
)
