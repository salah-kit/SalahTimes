import Dispatch
import Foundation
import SalahTimes
import Testing

/// How long it takes to compute 48 hours of events: three consecutive days, the shape of a
/// widget timeline or a notification schedule.
///
/// Run it in release to see production speed:
///
///     swift test -c release -Xswiftc -enable-testing -j 4 --filter Benchmark
///
/// The test prints its numbers. Its only assertion is a ceiling far above any plausible
/// result, so a busy machine can't make it fail.
@Suite("Benchmark")
struct BenchmarkTests {
  static let places: [(String, Double, Double, String, CalculationMethod)] = [
    ("Makkah", 21.4225, 39.8262, "Asia/Riyadh", .ummAlQura),
    ("London", 51.5074, -0.1278, "Europe/London", .moonsightingCommittee),
    ("Jakarta", -6.1754, 106.8272, "Asia/Jakarta", .kemenag),
    ("Istanbul", 41.0082, 28.9784, "Europe/Istanbul", .diyanet),
    ("Tromsø", 69.65, 18.96, "Europe/Oslo", .muslimWorldLeague),
    ("Ushuaia", -54.80, -68.30, "America/Argentina/Ushuaia", .muslimWorldLeague),
  ]

  @Test("Time to compute three consecutive days")
  func threeDays() throws {
    let repetitions = 200
    let start = GregorianDay(year: 2026, month: 3, day: 1)!
    var lines: [String] = []
    var total = 0.0
    var calls = 0
    for (name, latitude, longitude, identifier, method) in Self.places {
      let zone = try #require(TimeZone(identifier: identifier))
      let coordinates = Coordinates(latitude: latitude, longitude: longitude)
      let parameters = method.parameters
      // Warm up, and keep a result so the work can't be optimized away.
      var checksum = 0.0
      for offset in 0..<3 {
        let times = try PrayerTimes(
          coordinates: coordinates, day: start.adding(days: offset), timeZone: zone,
          parameters: parameters)
        checksum += times.dhuhr.date?.timeIntervalSince1970 ?? 0
      }
      let began = DispatchTime.now().uptimeNanoseconds
      for repetition in 0..<repetitions {
        for offset in 0..<3 {
          let times = try PrayerTimes(
            coordinates: coordinates, day: start.adding(days: offset + repetition % 7),
            timeZone: zone, parameters: parameters)
          checksum += times.isha.date?.timeIntervalSince1970 ?? 0
        }
      }
      let seconds = Double(DispatchTime.now().uptimeNanoseconds - began) / 1e9
      let perCall = seconds / Double(repetitions * 3)
      total += seconds
      calls += repetitions * 3
      #expect(checksum != 0)
      lines.append(
        "\(name) (\(method)): \(String(format: "%.1f", perCall * 1e6)) µs per day, "
          + "\(String(format: "%.1f", perCall * 3e6)) µs per 48 hours")
    }
    let average = total / Double(calls)
    #if DEBUG
      let configuration = "debug"
    #else
      let configuration = "release"
    #endif
    print("Benchmark (\(configuration)), \(calls) calls:\n  " + lines.joined(separator: "\n  "))
    print(
      "Benchmark (\(configuration)) average: \(String(format: "%.1f", average * 1e6)) µs per "
        + "day, \(String(format: "%.1f", average * 3e6)) µs per 48 hours")
    // A ceiling no correct build comes near: 50 ms for one day's events.
    #expect(average < 0.05)
  }
}
