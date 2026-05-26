// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "saver_gallery",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "saver-gallery", targets: ["saver_gallery"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "saver_gallery",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
