// swift-tools-version:5.3
import PackageDescription

// Renderer source: dbe277bb0bdf3b997eb54dd0a9fb380028c15e9c
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-dbe277bb-v1/MapLibre.xcframework.zip",
        checksum: "348535136b84b42b5eedaefbc03514e642998f7bb727bd2ea3348cd32db9c880"
    )]
)
