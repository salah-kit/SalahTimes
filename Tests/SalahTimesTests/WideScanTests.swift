import Foundation
import SalahTimes
import Testing

/// A wide scan for events that tie, fall out of order, or fall before their day.
///
/// Every preset, plus Umm al-Qura with the Ramadan rule's 120 minutes and the middle of the
/// night, at every whole latitude from 66° S to 70° N, on every day of 2026, at two places:
/// longitude 0 in UTC, and longitude 31.1° in Europe/Oslo, where the clock runs about an hour
/// behind the Sun in winter. Times are rounded as each preset ships.
///
/// It prints a Markdown table of what it finds, with the latitudes of each finding. It takes
/// about a minute, so it runs only on request:
///
///     SALAHTIMES_WIDE_SCAN=1 swift test -j 4 --filter WideScan
///
/// Set `SALAHTIMES_WIDE_SCAN_RESULTS` to a file path to write the table there as well.
/// docs/validation.md (Known limitations) summarizes the output.
@Suite("Wide scan")
struct WideScanTests {
  static let enabled = ProcessInfo.processInfo.environment["SALAHTIMES_WIDE_SCAN"] != nil

  struct Setup: Sendable {
    let name: String
    let parameters: CalculationParameters
  }

  static let setups: [Setup] = {
    var setups = CalculationMethod.allCases.map {
      Setup(name: "`\($0.rawValue)`", parameters: $0.parameters)
    }
    var ramadan = CalculationMethod.ummAlQura.parameters
    ramadan.ramadanIsha = .interval(minutes: 120, hijriDayOffset: 0)
    ramadan.highLatitudeRule = .middleOfTheNight
    setups.append(
      Setup(name: "`ummAlQura`, Ramadan 120 min, `middleOfTheNight`", parameters: ramadan))
    return setups
  }()

  static let places: [(name: String, longitude: Double, zone: String)] = [
    ("UTC, 0°", 0, "UTC"),
    ("Europe/Oslo, 31.1° E", 31.1, "Europe/Oslo"),
  ]

  static let latitudes = Array(-66...70)

  static let chain: [(String, PrayerTimes.Event)] = [
    ("Fajr", .fajr), ("sunrise", .sunrise), ("Dhuhr", .dhuhr), ("Asr", .asr),
    ("Maghrib", .maghrib), ("Isha", .isha),
  ]

  /// One kind of finding at one place: the latitudes where it happens and on how many days.
  struct Finding {
    var latitudes: Set<Int> = []
    var days = 0
  }

  @Test("Ties, inversions and events before their day", .enabled(if: enabled))
  func scan() throws {
    // Four workers, so the scan stays light on a shared machine; results keep setup order.
    let results = Results(count: Self.setups.count)
    let workers = 4
    DispatchQueue.concurrentPerform(iterations: workers) { worker in
      for index in stride(from: worker, to: Self.setups.count, by: workers) {
        results.set(index, Result { try Self.scan(Self.setups[index]) })
      }
    }
    var table = """
      | Setup | Place | Finding | Events | Latitudes | Days |
      |---|---|---|---|---|---|

      """
    for result in results.all {
      table += try result.get()
    }
    print("Wide scan:\n" + table)
    if let path = ProcessInfo.processInfo.environment["SALAHTIMES_WIDE_SCAN_RESULTS"] {
      let header = """
        # Wide scan

        Written by `WideScanTests.swift` (`SALAHTIMES_WIDE_SCAN=1 swift test -j 4 --filter \
        WideScan`). Every preset at every whole latitude from 66° S to 70° N, every day of \
        2026, with times rounded as each preset ships. Ties and inversions compare consecutive \
        prayers that occur (Fajr, sunrise, Dhuhr, Asr, Maghrib, Isha). "Before its day" is an \
        event whose instant precedes the start of its civil day in the place's zone. "Days" \
        counts latitude-days.


        """
      try (header + table).write(
        to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
    }
  }

  /// The table rows for one setup.
  static func scan(_ setup: Setup) throws -> String {
    let first = GregorianDay(year: 2026, month: 1, day: 1)!
    let days = (0..<366).map { first.adding(days: $0) }
    var findings: [String: Finding] = [:]

    for place in places {
      guard let zone = TimeZone(identifier: place.zone) else {
        throw CalculationError.invalidParameters("No time zone \(place.zone)")
      }
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = zone
      let starts = days.map {
        calendar.date(from: DateComponents(year: $0.year, month: $0.month, day: $0.day))!
      }
      for latitude in latitudes {
        let coordinates = Coordinates(latitude: Double(latitude), longitude: place.longitude)
        let series = try days.map {
          try PrayerTimes(
            coordinates: coordinates, day: $0, timeZone: zone, parameters: setup.parameters)
        }
        func record(_ key: String) {
          let full = "\(place.name) | \(key)"
          findings[full, default: Finding()].latitudes.insert(latitude)
          findings[full, default: Finding()].days += 1
        }
        for index in 0..<(days.count - 1) {
          let times = series[index]
          let occurring = chain.compactMap { name, event in
            times[event].date.map { (name, $0) }
          }
          for (earlier, later) in zip(occurring, occurring.dropFirst()) {
            if earlier.1 == later.1 {
              record("tie | \(earlier.0) = \(later.0)")
            } else if earlier.1 > later.1 {
              record("inversion within the day | \(earlier.0) after \(later.0)")
            }
          }
          if let isha = times.isha.date, let fajr = series[index + 1].fajr.date, isha > fajr {
            record("inversion across days | Isha after the next Fajr")
          }
          for (name, event) in chain {
            if let instant = times[event].date, instant < starts[index] {
              record("before its day | \(name)")
            }
          }
        }
      }
    }

    var lines = ""
    for key in findings.keys.sorted() {
      let finding = findings[key]!
      lines += "| \(setup.name) | \(key) | \(ranges(finding.latitudes)) | \(finding.days) |\n"
    }
    return lines.isEmpty ? "| \(setup.name) | both | none | | | |\n" : lines
  }

  /// Results filled in by concurrent workers.
  final class Results: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [Result<String, any Error>]

    init(count: Int) {
      values = Array(repeating: .success(""), count: count)
    }

    func set(_ index: Int, _ value: Result<String, any Error>) {
      lock.lock()
      defer { lock.unlock() }
      values[index] = value
    }

    var all: [Result<String, any Error>] {
      lock.lock()
      defer { lock.unlock() }
      return values
    }
  }

  /// Latitudes as runs, such as "−66–−64, 64–70".
  static func ranges(_ latitudes: Set<Int>) -> String {
    let sorted = latitudes.sorted()
    var runs: [(Int, Int)] = []
    for latitude in sorted {
      if let last = runs.last, last.1 == latitude - 1 {
        runs[runs.count - 1].1 = latitude
      } else {
        runs.append((latitude, latitude))
      }
    }
    return runs.map { $0.0 == $0.1 ? "\($0.0)°" : "\($0.0)° to \($0.1)°" }
      .joined(separator: ", ")
  }
}
