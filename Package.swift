// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AntifraudSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "AntifraudSDK",
            targets: ["AntifraudSDK"]
        )
    ],
    targets: [
        .target(
            name: "AntifraudSDK",
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
