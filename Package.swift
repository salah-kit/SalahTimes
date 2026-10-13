// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "SalahTimes",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .watchOS(.v6),
    .tvOS(.v13),
    .visionOS(.v1),
  ],
  products: [
    .library(name: "SalahTimes", targets: ["SalahTimes"])
  ],
  targets: [
    .target(name: "SalahTimes"),
    .testTarget(name: "SalahTimesTests", dependencies: ["SalahTimes"]),
  ]
)
