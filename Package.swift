// swift-tools-version:5.3
import PackageDescription

// Renderer source: ab3d5586e56ab929dc4dfa4df73f489629b1409f
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-ab3d5586-v1/MapLibre.xcframework.zip",
        checksum: "2ebaa4bb41de249bcf6f5d140dba0d1457b50cdae666a053a5f4f5b12ff55871"
    )]
)
