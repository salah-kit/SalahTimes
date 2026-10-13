// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "PrayerTimesCLI",
  platforms: [.macOS(.v10_15)],
  dependencies: [
    // The name keeps the product reference below working in a checkout whose directory isn't
    // called SalahTimes. In your own app, depend on the released package by URL instead.
    .package(name: "SalahTimes", path: "../..")
  ],
  targets: [
    .executableTarget(
      name: "PrayerTimesCLI",
      dependencies: [.product(name: "SalahTimes", package: "SalahTimes")])
  ]
)
