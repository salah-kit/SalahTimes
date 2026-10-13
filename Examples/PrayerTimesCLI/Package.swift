// swift-tools-version: 6.2

import PackageDescription

// The default isolation of the example's code: nonisolated unless SALAHTIMES_EXAMPLE_ISOLATION
// is `MainActor`, as an app target might set it. SalahTimes itself builds as it always does.
let defaultIsolation: [SwiftSetting] =
  Context.environment["SALAHTIMES_EXAMPLE_ISOLATION"] == "MainActor"
  ? [.defaultIsolation(MainActor.self)] : []

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
      dependencies: [.product(name: "SalahTimes", package: "SalahTimes")],
      swiftSettings: defaultIsolation)
  ]
)
