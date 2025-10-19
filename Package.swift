// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "miniaudio",
  platforms: [
    .macOS(.v13),
    .iOS(.v16),
    .watchOS(.v9),
    .tvOS(.v16),
  ],
  products: [
    .library(
      name: "Miniaudio",
      targets: ["Miniaudio"]
    ),
    .executable(
      name: "SimplePlaybackTest",
      targets: ["SimplePlaybackTest"]
    ),
    .executable(
      name: "MultiplePlaybackTest",
      targets: ["MultiplePlaybackTest"]
    )
  ],
  targets: [
    .target(
      name: "CMiniaudio",
      path: ".",
      sources: ["miniaudio.c"],
      publicHeadersPath: "include",
      cSettings: [
        .headerSearchPath(".")
      ]
    ),
    .target(
      name: "Miniaudio",
      dependencies: ["CMiniaudio"],
      path: "swift"
    ),
    .testTarget(
      name: "MiniaudioTests",
      dependencies: ["Miniaudio"],
      path: "tests/swift"
    ),
    .executableTarget(
      name: "SimplePlaybackTest",
      dependencies: ["Miniaudio"],
      path: "tests/executable",
      sources: ["SimplePlaybackTest.swift"]
    ),
    .executableTarget(
      name: "MultiplePlaybackTest",
      dependencies: ["Miniaudio"],
      path: "tests/executable",
      sources: ["MultiplePlaybackTest.swift"]
    ),
  ]
)
