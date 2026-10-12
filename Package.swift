// swift-tools-version:5.3
import PackageDescription

// Renderer source: 5c17df022faecf9a0a272f574337bbb41b1b703e
let package = Package(
    name: "MapLibre Native",
    platforms: [.iOS("15.5")],
    products: [.library(name: "MapLibre", targets: ["MapLibre"])],
    targets: [.binaryTarget(
        name: "MapLibre",
        url: "https://github.com/macrocity/maplibre-native/releases/download/macrocity-globe-5c17df02-v1/MapLibre.xcframework.zip",
        checksum: "c2576ff19fcf32379c3e05bd69ed86f8bf364c729cd40daf631ce61f0988b855"
    )]
)
