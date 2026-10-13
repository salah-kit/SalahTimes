# SalahTimes

Prayer-time calculation in Swift, for any app that shows prayer times, with no dependencies.

[![CI](https://github.com/salah-kit/SalahTimes/actions/workflows/ci.yml/badge.svg)](https://github.com/salah-kit/SalahTimes/actions/workflows/ci.yml)
[![Latest release](https://img.shields.io/github/v/release/salah-kit/SalahTimes?sort=semver)](https://github.com/salah-kit/SalahTimes/releases)
[![License: MIT](https://img.shields.io/github/license/salah-kit/SalahTimes)](LICENSE)

## What it is

SalahTimes computes the five daily prayers, sunrise, sunset and the night's middle and last third for one civil day at one place. It's the calculation engine of the [salah-kit](https://github.com/salah-kit) ecosystem, and any app can use it on its own.

- **An engine written from published sources.** The Sun's position follows Jean Meeus' *Astronomical Algorithms*. [docs/algorithm.md](docs/algorithm.md) specifies every step, so other languages can reproduce it.
- **Published methods.** Fourteen presets, from the Muslim World League to Diyanet, JAKIM, Kemenag and the Moonsighting Committee. [METHODS.md](METHODS.md) gives each value with its source. You can change any parameter or build your own method.
- **High latitudes.** Rules keep Fajr and Isha reasonable where twilight lasts all night. The recommended rule works by absolute latitude, so it serves Ushuaia as well as Oslo. Each prayer is bounded by its own night, so times never cross.
- **Typed non-occurrence.** When the Sun doesn't set or doesn't reach an angle, the event is `.doesNotOccur(reason)`. SalahTimes never invents a time.
- **Qibla.** The great-circle direction of the Kaaba from any place.
- **Shared vectors.** The JSON in [Vectors/](Vectors/README.md) comes from an independent reference implementation. Engines in other languages pass the same vectors. [docs/validation.md](docs/validation.md) describes how the results are checked.

What it deliberately isn't:

- It has no location services. You pass coordinates and a time zone.
- It doesn't format times or translate prayer names. It returns `Date` values.
- It has no Hijri dates, apart from the opt-in Ramadan rule for Isha.
- It plays no adhan audio and schedules no notifications. [SalahKit](https://github.com/salah-kit/SalahKit) does that.
- It has no dependencies.

## Installation

Add SalahTimes to your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/salah-kit/SalahTimes.git", from: "0.1.0")
],
targets: [
  .target(name: "MyApp", dependencies: ["SalahTimes"])
]
```

In Xcode, choose File > Add Package Dependencies and enter `https://github.com/salah-kit/SalahTimes.git`.

## Quick start

```swift
let makkah = TimeZone(identifier: "Asia/Riyadh")!
let times = try PrayerTimes(
  coordinates: Coordinates(latitude: 21.4225, longitude: 39.8262),
  day: GregorianDay(containing: Date(), in: makkah),
  timeZone: makkah,
  parameters: CalculationMethod.ummAlQura.parameters)

let formatter = DateFormatter()
formatter.timeStyle = .short
formatter.timeZone = makkah
for event in PrayerTimes.Event.allCases {
  switch times[event] {
  case .occurs(let date):
    print(event, formatter.string(from: date))
  case .doesNotOccur(let reason):
    print(event, "doesn't occur:", reason)
  }
}
```

Compute for a day in the location's time zone, not the device's. [Examples/PrayerTimesCLI](Examples/PrayerTimesCLI) is a complete command-line program.

## Documentation

The documentation is at [salah-kit.github.io/SalahTimes](https://salah-kit.github.io/SalahTimes/documentation/salahtimes). It includes articles on getting started, choosing a method, high latitudes and validation.

## Supported platforms

- iOS 13, macOS 10.15, watchOS 6, tvOS 13 and visionOS 1
- Linux
- Swift 6.0 or later

## Status and versioning

SalahTimes is before 1.0. It follows [Semantic Versioning](https://semver.org), so a minor release can still change the API while it's below 1.0. API changes go through an RFC in [docs/rfcs](docs/rfcs). [CHANGELOG.md](CHANGELOG.md) lists every release.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The org-wide code of conduct and security policy live in [salah-kit/.github](https://github.com/salah-kit/.github).

## License

MIT. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
