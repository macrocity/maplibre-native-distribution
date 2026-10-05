// swift-tools-version:5.3
import PackageDescription

// Renderer source: 6d52e1c813762feaaf6498d0894e19fa91d493c7
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-6d52e1c8-v1/MapLibre.xcframework.zip",
        checksum: "79b867a244c0ef89a35c32385a2bbf91fb06f2830a8e95909fd10e40c8586598"
    )]
)
