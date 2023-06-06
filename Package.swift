// swift-tools-version:5.9
import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "Renamed",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
    .macCatalyst(.v13),
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
    .target(
        name: "Renamed",
        dependencies: [
            "RenamedPlugin",
        ]
    ),
    .macro(
      name: "RenamedPlugin",
      dependencies: [
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "RenamedTests",
      dependencies: ["Renamed"]
    ),
  ]
)
