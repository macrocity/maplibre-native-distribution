// swift-tools-version:5.3
import PackageDescription

// Renderer source: 923ebf0b6a3c93a0cfebf1d2048a190e612e14bd
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-923ebf0b-v1/MapLibre.xcframework.zip",
        checksum: "41a8fb1c954a876f89a4cb3725f78a8d5555fa44180f3483ba6f4e077605651c"
    )]
)
