import Foundation
import SalahTimes
import Testing

/// Compares SalahTimes with official published timetables.
///
/// `Validation/official-timetables/sources.json` lists each timetable: the authority, the
/// reference coordinates, the time zone and the SalahTimes method to compare with. The data
/// is a CSV of local times per day. Timetables whose terms allow redistribution are committed
/// under `Validation/official-timetables/data/` and always compared. The others are fetched by
/// `Validation/official-timetables/fetch.py` into its gitignored `cache/` directory and compared
/// only when `SALAHTIMES_OFFICIAL_TIMETABLES` names that directory:
///
///     python3 Validation/official-timetables/fetch.py
///     SALAHTIMES_OFFICIAL_TIMETABLES=$PWD/Validation/official-timetables/cache \
///       swift test -j 4 --filter OfficialTimetable
///
/// For each timetable and prayer the test reports the official time minus SalahTimes' unrounded
/// time, in minutes: mean, minimum and maximum. A positive mean is the authority publishing
/// later, as precautionary minutes do; a mean near +0.5 with a spread of about a minute is an
/// authority that rounds up. It also reports how often the method's preset, rounded as it ships,
/// gives exactly the published minute. Set `SALAHTIMES_OFFICIAL_RESULTS` to a file path to write
/// the tables there as Markdown.
///
/// The suite is serialized because both tests append to the same results file.
///
/// The only assertion is a sanity bound: no day may differ by more than
/// ``OfficialTimetableTests/sanityMinutes``, which catches a wrong time zone, date or
/// coordinate. The offsets themselves are findings, interpreted in docs/validation.md.
@Suite("Official timetables", .serialized)
struct OfficialTimetableTests {
  static let sanityMinutes = 10.0
  static let cacheVariable = "SALAHTIMES_OFFICIAL_TIMETABLES"
  static let resultsVariable = "SALAHTIMES_OFFICIAL_RESULTS"

  static var directory: URL {
    URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
      .deletingLastPathComponent().appendingPathComponent("Validation")
      .appendingPathComponent("official-timetables")
  }

  static var hasCache: Bool {
    ProcessInfo.processInfo.environment[cacheVariable] != nil
  }

  @Test("Committed timetables")
  func committedTimetables() throws {
    let sources = try Self.loadSources().filter(\.committed)
    #expect(!sources.isEmpty)
    let directory = Self.directory.appendingPathComponent("data")
    let reports = try sources.map { try Self.compare($0, in: directory) }
    Self.publish(reports, name: "committed")
  }

  @Test(
    "Cached timetables",
    .enabled(if: hasCache, "Set SALAHTIMES_OFFICIAL_TIMETABLES to the cache directory"))
  func cachedTimetables() throws {
    let path = try #require(ProcessInfo.processInfo.environment[Self.cacheVariable])
    let directory = URL(fileURLWithPath: path)
    var reports: [Report] = []
    for source in try Self.loadSources() where !source.committed {
      let file = directory.appendingPathComponent(source.file)
      guard FileManager.default.fileExists(atPath: file.path) else {
        Issue.record("\(source.id): \(file.path) is missing; run fetch.py")
        continue
      }
      reports.append(try Self.compare(source, in: directory))
      for (label, parameters) in try Self.fits(for: source) {
        reports.append(try Self.compare(source, in: directory, fit: (label, parameters)))
      }
    }
    Self.publish(reports, name: "cached")
  }

  // MARK: Comparison

  struct Source: Decodable {
    let id: String
    let authority: String
    let place: String
    let latitude: Double
    let longitude: Double
    let timeZone: String
    let method: String
    let madhab: String
    let shafaq: String?
    let ramadanIshaMinutes: Int?
    let file: String
    let committed: Bool
  }

  struct Statistics {
    var count = 0
    var sum = 0.0
    var minimum = Double.infinity
    var maximum = -Double.infinity
    var exactMatches = 0
    var withinOneMinute = 0
    var largestPresetDifference = 0.0

    mutating func add(_ minutes: Double, presetDifference: Double) {
      count += 1
      sum += minutes
      minimum = min(minimum, minutes)
      maximum = max(maximum, minutes)
      if abs(presetDifference) < 0.001 { exactMatches += 1 }
      if abs(presetDifference) <= 1.001 { withinOneMinute += 1 }
      largestPresetDifference = max(largestPresetDifference, abs(presetDifference))
    }

    var mean: Double { count == 0 ? 0 : sum / Double(count) }
  }

  struct Report {
    let source: Source
    let fit: String?
    let days: Int
    let statistics: [(String, Statistics)]
  }

  static let prayers: [(String, PrayerTimes.Event)] = [
    ("fajr", .fajr), ("sunrise", .sunrise), ("dhuhr", .dhuhr), ("asr", .asr),
    ("maghrib", .maghrib), ("isha", .isha),
  ]

  static func loadSources() throws -> [Source] {
    struct File: Decodable { let sources: [Source] }
    let data = try Data(contentsOf: directory.appendingPathComponent("sources.json"))
    return try JSONDecoder().decode(File.self, from: data).sources
  }

  static func parameters(for source: Source) throws -> CalculationParameters {
    let method = try #require(CalculationMethod(rawValue: source.method), "\(source.method)")
    var parameters = method.parameters
    parameters.madhab = try #require(Madhab(rawValue: source.madhab))
    if let shafaq = source.shafaq {
      parameters.isha = .moonsightingCommittee(try #require(Shafaq(rawValue: shafaq)))
    }
    if let minutes = source.ramadanIshaMinutes {
      parameters.ramadanIsha = .interval(minutes: minutes, hijriDayOffset: 0)
    }
    return parameters
  }

  /// Place-specific fits compared in addition to the preset: user adjustments and rounding
  /// that reproduce one timetable more closely than the method's documented rules do. They
  /// describe that timetable, not the method, so they stay out of the presets.
  static func fits(for source: Source) throws -> [(String, CalculationParameters)] {
    switch source.id {
    case "jakim-wly01":
      // On top of the preset's own Dhuhr +1 minute: Dhuhr +2 in all.
      var parameters = try parameters(for: source)
      parameters.rounding = .up
      parameters.adjustments = PrayerAdjustments(
        fajr: 1, sunrise: -1, dhuhr: 1, asr: 1, maghrib: 1, isha: 1)
      return [
        (
          "WLY01 fit: rounding up, user adjustments Fajr +1, sunrise -1, Dhuhr +1, Asr +1, "
            + "Maghrib +1, Isha +1", parameters
        )
      ]
    default:
      return []
    }
  }

  static func compare(
    _ source: Source, in directory: URL, fit: (String, CalculationParameters)? = nil
  ) throws -> Report {
    let zone = try #require(TimeZone(identifier: source.timeZone))
    let coordinates = Coordinates(latitude: source.latitude, longitude: source.longitude)
    let preset = try fit?.1 ?? parameters(for: source)
    var exact = preset
    exact.rounding = .none
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = zone

    let text = try String(
      contentsOf: directory.appendingPathComponent(source.file), encoding: .utf8)
    let lines = text.split(separator: "\n").map(String.init)
    #expect(lines.first == "date,fajr,sunrise,dhuhr,asr,maghrib,isha", "\(source.id) header")
    var statistics = prayers.map { ($0.0, Statistics()) }
    var days = 0
    for line in lines.dropFirst() where !line.isEmpty {
      let fields = line.split(separator: ",").map(String.init)
      try #require(fields.count == 7, "\(source.id): \(line)")
      let day = try #require(GregorianDay(fields[0]), "\(source.id): \(line)")
      let rounded = try PrayerTimes(
        coordinates: coordinates, day: day, timeZone: zone, parameters: preset)
      let unrounded = try PrayerTimes(
        coordinates: coordinates, day: day, timeZone: zone, parameters: exact)
      days += 1
      for (index, (name, event)) in prayers.enumerated() {
        let clock = fields[index + 1].split(separator: ":").compactMap { Int($0) }
        try #require(clock.count == 2, "\(source.id) \(day) \(name)")
        let official = try #require(
          calendar.date(
            from: DateComponents(
              year: day.year, month: day.month, day: day.day, hour: clock[0], minute: clock[1])))
        let computed = try #require(unrounded[event].date, "\(source.id) \(day) \(name)")
        let shipped = try #require(rounded[event].date)
        let minutes = official.timeIntervalSince(computed) / 60
        statistics[index].1.add(
          minutes, presetDifference: official.timeIntervalSince(shipped) / 60)
      }
    }
    // One issue per prayer, not per day.
    for (name, stats) in statistics {
      let worst = max(abs(stats.minimum), abs(stats.maximum))
      #expect(
        worst <= sanityMinutes,
        Comment(
          rawValue: "\(source.id) \(name): official minus SalahTimes ranges from "
            + "\(format(stats.minimum)) to \(format(stats.maximum)) min, beyond the "
            + "\(sanityMinutes)-minute sanity bound"))
    }
    return Report(source: source, fit: fit?.0, days: days, statistics: statistics)
  }

  static func publish(_ reports: [Report], name: String) {
    var markdown = ""
    for report in reports {
      let source = report.source
      markdown += "### \(source.id): \(source.place)"
      markdown += report.fit == nil ? "\n\n" : ", place-specific fit\n\n"
      markdown += "\(source.authority). \(report.days) days. Compared with `\(source.method)`, "
      markdown += "\(source.madhab) Asr"
      if let shafaq = source.shafaq { markdown += ", shafaq \(shafaq)" }
      if let minutes = source.ramadanIshaMinutes {
        markdown += ", Ramadan Isha \(minutes) minutes"
      }
      markdown += ", at \(source.latitude), \(source.longitude).\n\n"
      if let fit = report.fit {
        markdown += "\(fit). The columns below use these parameters in place of the preset.\n\n"
      }
      markdown += "| Prayer | Mean | Min | Max | Preset exact | Preset within 1 min "
      markdown += "| Preset largest difference |\n"
      markdown += "|---|---:|---:|---:|---:|---:|---:|\n"
      for (prayer, stats) in report.statistics {
        markdown += "| \(prayer) | \(format(stats.mean)) | \(format(stats.minimum)) | "
        markdown += "\(format(stats.maximum)) | \(share(stats.exactMatches, of: stats.count)) | "
        markdown += "\(share(stats.withinOneMinute, of: stats.count)) | "
        markdown += "\(String(format: "%.0f", stats.largestPresetDifference)) min |\n"
      }
      markdown += "\n"
    }
    print("Official timetables (\(name)), official minus SalahTimes in minutes:\n\n" + markdown)
    if let path = ProcessInfo.processInfo.environment[resultsVariable] {
      let url = URL(fileURLWithPath: path)
      var existing = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
      if existing.isEmpty {
        existing = resultsHeader
      }
      do {
        try (existing + markdown).write(to: url, atomically: true, encoding: .utf8)
      } catch {
        Issue.record("Couldn't write \(path): \(error)")
      }
    }
  }

  static let resultsHeader = """
    # Official timetables: results

    Official time minus SalahTimes' unrounded time, in minutes, for every day of 2026. A \
    positive value means the authority publishes later. "Preset exact", "Preset within 1 \
    min" and "Preset largest difference" compare the method's preset as it ships (with its own \
    adjustments and rounding) with the published minute, in days of the year. A \
    place-specific fit replaces the preset in those columns and in the mean.

    Written by `OfficialTimetableTests.swift`; see README.md to reproduce. docs/validation.md \
    interprets the numbers.


    """

  /// A count of days with its percentage, such as "347 (95%)".
  static func share(_ count: Int, of total: Int) -> String {
    "\(count) (\(String(format: "%.0f", 100 * Double(count) / Double(max(total, 1))))%)"
  }

  static func format(_ value: Double) -> String {
    String(format: "%+.2f", value)
  }
}
