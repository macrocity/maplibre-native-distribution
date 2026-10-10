// swift-tools-version:5.3
import PackageDescription

// Renderer source: 8f46d77f778aa61ba51f5684f423810ba53854f6
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-8f46d77f-v1/MapLibre.xcframework.zip",
        checksum: "e78937bf4ae4764305a7b7ef65f195da6dcc17fe382635403c02a4ee1136c643"
    )]
)
