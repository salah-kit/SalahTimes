import Foundation
import SalahTimes
import Testing

/// Parity with the timetables in adhan-swift's test data (`Tests/Data/adhan-swift`).
///
/// Each file names a place, a method, a madhab and a high-latitude rule. The test maps them to
/// SalahTimes' preset for the same method, computes every listed day, and checks every prayer
/// agrees with the file's local time within one minute. A pair that can't agree is listed in
/// ``knownDifferences`` with the largest difference it may show and the reason, and
/// docs/validation.md explains it.
@Suite("adhan-swift parity")
struct AdhanParityTests {
  static let files = [
    "Ankara-Turkey",
    "Doha-Qatar",
    "Dubai-Gulf",
    "Kuwait City-Kuwait",
    "London-MoonsightingCommittee",
    "Makkah-UmmAlQura",
    "Singapore-Singapore",
    "Tehran-Tehran",
  ]

  /// A file's prayer that differs from SalahTimes by more than one minute, for a stated reason.
  struct KnownDifference {
    /// The largest difference allowed, in minutes.
    let maximumMinutes: Double
    /// Why the two disagree.
    let reason: String
  }

  /// Known differences, keyed by file name and then by prayer.
  static let knownDifferences: [String: [String: KnownDifference]] = [:]

  @Test("Every listed day agrees within one minute", arguments: files)
  func parity(file: String) throws {
    let url = Self.dataDirectory.appendingPathComponent(file + ".json")
    let data = try Data(contentsOf: url)
    let table = try JSONDecoder().decode(AdhanTable.self, from: data)
    let timeZone = try #require(TimeZone(identifier: table.params.timezone))
    let parameters = try #require(Self.parameters(for: table.params), "Unknown method")
    let coordinates = Coordinates(
      latitude: table.params.latitude, longitude: table.params.longitude)
    let known = Self.knownDifferences[file] ?? [:]

    var worst: [String: Double] = [:]
    for entry in table.times {
      let day = try #require(GregorianDay(entry.date), "Bad date \(entry.date)")
      let times = try PrayerTimes(
        coordinates: coordinates, day: day, timeZone: timeZone, parameters: parameters)
      for (prayer, expectedText) in entry.prayers {
        let expected = try #require(
          Self.instant(expectedText, on: day, in: timeZone), "Bad time \(expectedText)")
        let computed = try #require(
          times[prayer.event].date, "\(file) \(entry.date) \(prayer.name) doesn't occur")
        let minutes = computed.timeIntervalSince(expected) / 60
        worst[prayer.name] = max(worst[prayer.name] ?? 0, abs(minutes))
        let limit = known[prayer.name]?.maximumMinutes ?? 1
        #expect(
          abs(minutes) <= limit,
          "\(file) \(entry.date) \(prayer.name): expected \(expectedText), off by \(minutes) min")
      }
    }

    // A known difference that no longer exceeds a minute should be removed from the list.
    for (prayer, difference) in known {
      #expect(
        (worst[prayer] ?? 0) > 1,
        "\(file) \(prayer) now agrees within a minute; remove: \(difference.reason)")
    }
    let summary = AdhanTable.prayerNames.map { name in
      "\(name) \(String(format: "%.2f", worst[name] ?? 0))"
    }
    print("adhan-swift parity \(file), \(table.times.count) days, max |diff| min: "
      + summary.joined(separator: ", "))
  }

  /// SalahTimes' parameters for an adhan-swift file's method, madhab and high-latitude rule.
  static func parameters(for params: AdhanTable.Params) -> CalculationParameters? {
    let methods: [String: CalculationMethod] = [
      "MuslimWorldLeague": .muslimWorldLeague,
      "Egyptian": .egyptian,
      "Karachi": .karachi,
      "UmmAlQura": .ummAlQura,
      "Dubai": .dubai,
      "Qatar": .qatar,
      "Kuwait": .kuwait,
      "MoonsightingCommittee": .moonsightingCommittee,
      "Singapore": .muis,
      "Turkey": .diyanet,
      "Tehran": .tehran,
      "NorthAmerica": .isna,
    ]
    let rules: [String: HighLatitudeRule] = [
      "MiddleOfTheNight": .middleOfTheNight,
      "SeventhOfTheNight": .seventhOfTheNight,
      "TwilightAngle": .twilightAngle,
    ]
    guard let method = methods[params.method], let rule = rules[params.highLatitudeRule] else {
      return nil
    }
    var parameters = method.parameters
    parameters.madhab = params.madhab == "Hanafi" ? .hanafi : .shafi
    parameters.highLatitudeRule = rule
    return parameters
  }

  /// Reads a local time such as "5:38 AM" on a day in a time zone.
  static func instant(_ text: String, on day: GregorianDay, in timeZone: TimeZone) -> Date? {
    let parts = text.split(separator: " ")
    guard parts.count == 2 else { return nil }
    let clock = parts[0].split(separator: ":")
    guard clock.count == 2, var hour = Int(clock[0]), let minute = Int(clock[1]),
      (1...12).contains(hour), (0..<60).contains(minute)
    else { return nil }
    switch parts[1] {
    case "AM": hour = hour == 12 ? 0 : hour
    case "PM": hour = hour == 12 ? 12 : hour + 12
    default: return nil
    }
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    return calendar.date(
      from: DateComponents(
        year: day.year, month: day.month, day: day.day, hour: hour, minute: minute))
  }

  static var dataDirectory: URL {
    URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
      .appendingPathComponent("Data").appendingPathComponent("adhan-swift")
  }

  /// One adhan-swift data file. The `source` and `variance` keys aren't used.
  struct AdhanTable: Decodable {
    struct Params: Decodable {
      let latitude: Double
      let longitude: Double
      let timezone: String
      let method: String
      let madhab: String
      let highLatitudeRule: String
    }

    struct Prayer {
      let name: String
      let event: PrayerTimes.Event
    }

    struct Entry: Decodable {
      let date: String
      let fajr: String
      let sunrise: String
      let dhuhr: String
      let asr: String
      let maghrib: String
      let isha: String

      var prayers: [(Prayer, String)] {
        [
          (Prayer(name: "fajr", event: .fajr), fajr),
          (Prayer(name: "sunrise", event: .sunrise), sunrise),
          (Prayer(name: "dhuhr", event: .dhuhr), dhuhr),
          (Prayer(name: "asr", event: .asr), asr),
          (Prayer(name: "maghrib", event: .maghrib), maghrib),
          (Prayer(name: "isha", event: .isha), isha),
        ]
      }
    }

    static let prayerNames = ["fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"]

    let params: Params
    let times: [Entry]
  }
}
