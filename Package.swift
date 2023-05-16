// swift-tools-version:999.0
import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "Renamed",
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
  ],
  products: [
    .library(
      name: "Renamed",
      targets: ["Renamed"]
    ),
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-syntax.git",
      branch: "main"
    ),
  ],
  targets: [
    .macro(
      name: "RenamedPlugin",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "Renamed",
      dependencies: [
        "RenamedPlugin",
      ],
      swiftSettings: [
        .enableExperimentalFeature("Macros"),
      ]
    ),
    .testTarget(
      name: "RenamedTests",
      dependencies: ["Renamed"]
    ),
  ]
)
