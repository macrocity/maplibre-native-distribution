// swift-tools-version:5.3
import PackageDescription

// Renderer source: fa31fcac317189e395f229dcb242eb8db6ca3622
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-fa31fcac-v1/MapLibre.xcframework.zip",
        checksum: "3bb39d2eb641ea84363e9ee07baaa3a4d0bbf79b55acb85ffc4f3839d8e859ea"
    )]
)
