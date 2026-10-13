import Foundation
import SalahTimes
import Testing

// The code samples in README.md and in the DocC articles come from this file. Each sample sits
// between a `// docs:begin <name>` and a `// docs:end` comment, inside a test that runs it and
// checks its results. `samplesMatchTheDocumentation` fails when an article's Swift code and its
// sample here differ, so change both together.

@Suite("Documentation examples")
struct DocumentationExampleTests {
  @Test("The README's quick start computes Makkah's times")
  func readmeQuickStart() throws {
    // docs:begin readme-quick-start
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
    // docs:end

    for event in PrayerTimes.Event.allCases {
      #expect(times[event].date != nil, "\(event) occurs in Makkah every day")
    }
  }

  @Test("Getting started computes, reads and explains a day's times")
  func gettingStarted() throws {
    // docs:begin getting-started-compute
    let istanbul = TimeZone(identifier: "Europe/Istanbul")!
    let times = try PrayerTimes(
      coordinates: Coordinates(latitude: 41.0082, longitude: 28.9784),
      day: GregorianDay(year: 2026, month: 3, day: 20)!,
      timeZone: istanbul,
      parameters: CalculationMethod.diyanet.parameters)
    // docs:end

    let prayers = [times.fajr, times.sunrise, times.dhuhr, times.asr, times.maghrib, times.isha]
    let dates = prayers.compactMap(\.date)
    #expect(dates.count == prayers.count)
    #expect(dates == dates.sorted())
    #expect(times.day == GregorianDay(year: 2026, month: 3, day: 20))

    // docs:begin getting-started-today
    let today = GregorianDay(containing: Date(), in: istanbul)
    // docs:end
    #expect(today == GregorianDay(containing: Date(), in: istanbul))

    // docs:begin getting-started-read
    if let maghrib = times.maghrib.date {
      let formatter = DateFormatter()
      formatter.timeStyle = .short
      formatter.timeZone = istanbul
      print("Maghrib", formatter.string(from: maghrib))
    }
    // docs:end

    // docs:begin getting-started-does-not-occur
    let tromso = try PrayerTimes(
      coordinates: Coordinates(latitude: 69.6492, longitude: 18.9553),
      day: GregorianDay(year: 2026, month: 6, day: 21)!,
      timeZone: TimeZone(identifier: "Europe/Oslo")!,
      parameters: CalculationMethod.muslimWorldLeague.parameters)

    switch tromso.isha {
    case .occurs(let date):
      print("Isha", date)
    case .doesNotOccur(.sunStaysAbove):
      print("The Sun doesn't set tonight, so there's no Isha.")
    case .doesNotOccur(.sunStaysBelow):
      print("The Sun doesn't rise high enough for Isha.")
    }
    // docs:end

    // Tromsø has midnight sun on the June solstice: no sunset, so no Maghrib and no Isha.
    #expect(tromso.sunset == .doesNotOccur(.sunStaysAbove))
    #expect(tromso.maghrib == .doesNotOccur(.sunStaysAbove))
    #expect(tromso.isha == .doesNotOccur(.sunStaysAbove))
    #expect(tromso.dhuhr.date != nil)

    // docs:begin getting-started-owning-day
    let kashgarZone = TimeZone(identifier: "Asia/Shanghai")!
    let kashgar = try PrayerTimes(
      coordinates: Coordinates(latitude: 39.4704, longitude: 75.9898),
      day: GregorianDay(year: 2026, month: 6, day: 21)!,
      timeZone: kashgarZone,
      parameters: CalculationMethod.muslimWorldLeague.parameters)

    if let isha = kashgar.isha.date {
      let civilDay = GregorianDay(containing: isha, in: kashgarZone)
      print(kashgar.day, civilDay)  // 2026-06-21 2026-06-22
    }
    // docs:end

    // Kashgar keeps China Standard Time, about three hours ahead of its Sun, so its summer Isha
    // falls after midnight but still belongs to 21 June.
    let isha = try #require(kashgar.isha.date)
    #expect(kashgar.day == GregorianDay(year: 2026, month: 6, day: 21))
    #expect(GregorianDay(containing: isha, in: kashgarZone) == kashgar.day.adding(days: 1))

    // docs:begin getting-started-qibla
    let london = Coordinates(latitude: 51.5072, longitude: -0.1276)
    if let bearing = Qibla.direction(from: london) {
      print("Qibla: \(Int(bearing.rounded()))° from true north")  // 119°
    }
    // docs:end

    let bearing = try #require(Qibla.direction(from: london))
    #expect(Int(bearing.rounded()) == 119)
  }

  @Test("Choosing a method: presets, madhab, adjustments and custom parameters")
  func choosingAMethod() throws {
    // docs:begin choosing-preset
    let mwl = CalculationMethod.muslimWorldLeague.parameters
    // docs:end
    #expect(mwl.fajr == .angle(18))
    #expect(mwl.isha == .angle(17))

    // docs:begin choosing-madhab
    var hanafi = CalculationMethod.karachi.parameters
    hanafi.madhab = .hanafi
    // docs:end

    // docs:begin choosing-adjustments
    var diyanet = CalculationMethod.diyanet.parameters
    diyanet.adjustments.isha = 2
    // diyanet.methodAdjustments still holds Diyanet's own minutes.
    // docs:end
    #expect(diyanet.methodAdjustments == CalculationMethod.diyanet.parameters.methodAdjustments)
    #expect(diyanet.adjustments == PrayerAdjustments(isha: 2))

    // docs:begin choosing-rounding
    var exact = CalculationMethod.isna.parameters
    exact.rounding = .none
    // docs:end

    // docs:begin choosing-custom
    let custom = CalculationParameters(
      fajr: .angle(16), isha: .minutesAfterMaghrib(75), madhab: .hanafi)
    // docs:end

    // docs:begin choosing-json
    let json = Data(#"{"fajr": {"angle": 16}, "isha": {"minutesAfterMaghrib": 75}}"#.utf8)
    let decoded = try JSONDecoder().decode(CalculationParameters.self, from: json)
    // docs:end
    #expect(decoded == CalculationParameters(fajr: .angle(16), isha: .minutesAfterMaghrib(75)))

    // docs:begin choosing-suggestion
    let method = CalculationMethod.suggested(forCountryCode: "tr") ?? .muslimWorldLeague
    // docs:end
    #expect(method == .diyanet)
    #expect(CalculationMethod.suggested(forCountryCode: "GB") == nil)

    // docs:begin choosing-ramadan
    var ummAlQura = CalculationMethod.ummAlQura.parameters
    ummAlQura.ramadanIsha = .interval(minutes: 120, hijriDayOffset: 0)
    // docs:end

    // Run the samples' parameters in Karachi.
    let karachi = Coordinates(latitude: 24.8607, longitude: 67.0011)
    let karachiZone = try #require(TimeZone(identifier: "Asia/Karachi"))
    let day = try #require(GregorianDay(year: 2026, month: 3, day: 1))
    func times(_ parameters: CalculationParameters) throws -> PrayerTimes {
      try PrayerTimes(
        coordinates: karachi, day: day, timeZone: karachiZone, parameters: parameters)
    }

    let shafiAsr = try #require(try times(CalculationMethod.karachi.parameters).asr.date)
    let hanafiAsr = try #require(try times(hanafi).asr.date)
    #expect(hanafiAsr > shafiAsr)

    let exactTimes = try times(exact)
    let exactFajr = try #require(exactTimes.fajr.date)
    #expect(exactFajr.timeIntervalSince1970.truncatingRemainder(dividingBy: 60) != 0)

    let customTimes = try times(custom)
    let customMaghrib = try #require(customTimes.maghrib.date)
    let customIsha = try #require(customTimes.isha.date)
    #expect(customIsha.timeIntervalSince(customMaghrib) == 75 * 60)

    // 1 March 2026 falls in Ramadan 1447 in the Umm al-Qura calendar.
    let ramadan = try times(ummAlQura)
    let ramadanMaghrib = try #require(ramadan.maghrib.date)
    let ramadanIsha = try #require(ramadan.isha.date)
    #expect(ramadanIsha.timeIntervalSince(ramadanMaghrib) == 120 * 60)
    let ordinary = try times(CalculationMethod.ummAlQura.parameters)
    let ordinaryMaghrib = try #require(ordinary.maghrib.date)
    let ordinaryIsha = try #require(ordinary.isha.date)
    #expect(ordinaryIsha.timeIntervalSince(ordinaryMaghrib) == 90 * 60)
  }

  @Test("High latitudes: the recommended rule, bounds and polar night")
  func highLatitudes() throws {
    // docs:begin high-latitudes-recommended
    let ushuaia = Coordinates(latitude: -54.8019, longitude: -68.3030)
    let rule = HighLatitudeRule.recommended(for: ushuaia)  // .seventhOfTheNight
    // docs:end
    #expect(rule == .seventhOfTheNight)

    // docs:begin high-latitudes-compare
    let oslo = TimeZone(identifier: "Europe/Oslo")!
    let tromso = Coordinates(latitude: 69.6492, longitude: 18.9553)
    let august = GregorianDay(year: 2026, month: 8, day: 10)!

    var bounded = CalculationMethod.muslimWorldLeague.parameters
    bounded.highLatitudeRule = .seventhOfTheNight
    var unbounded = bounded
    unbounded.highLatitudeRule = .disabled

    let withRule = try PrayerTimes(
      coordinates: tromso, day: august, timeZone: oslo, parameters: bounded)
    let withoutRule = try PrayerTimes(
      coordinates: tromso, day: august, timeZone: oslo, parameters: unbounded)
    // withRule.isha occurs a seventh of the night after sunset.
    // withoutRule.isha is .doesNotOccur(.sunStaysAbove).
    // docs:end

    // In Tromsø in August the Sun sets, but stays within about 5° of the horizon all night.
    let sunset = try #require(withRule.sunset.date)
    let isha = try #require(withRule.isha.date)
    #expect(isha > sunset)
    #expect(withRule.fajr.date != nil)
    #expect(withoutRule.sunset == withRule.sunset)
    #expect(withoutRule.isha == .doesNotOccur(.sunStaysAbove))
    #expect(withoutRule.fajr == .doesNotOccur(.sunStaysAbove))

    // docs:begin high-latitudes-polar-night
    let december = try PrayerTimes(
      coordinates: tromso, day: GregorianDay(year: 2026, month: 12, day: 21)!,
      timeZone: oslo, parameters: bounded)
    // december.sunrise and december.sunset are .doesNotOccur(.sunStaysBelow).
    // december.dhuhr occurs: it's the Sun's transit, below the horizon.
    // docs:end

    #expect(december.sunrise == .doesNotOccur(.sunStaysBelow))
    #expect(december.sunset == .doesNotOccur(.sunStaysBelow))
    #expect(december.maghrib == .doesNotOccur(.sunStaysBelow))
    #expect(december.asr == .doesNotOccur(.sunStaysBelow))
    #expect(december.dhuhr.date != nil)
    #expect(december.fajr.date != nil)
    #expect(december.isha.date != nil)
  }

  @Test("The documentation's Swift code matches these samples")
  func samplesMatchTheDocumentation() throws {
    let samples = try Self.samples()
    #expect(samples.count >= 15)
    var unused = Set(samples.keys)

    var documents = [Self.root.appendingPathComponent("README.md")]
    let catalog = Self.root.appendingPathComponent("Sources/SalahTimes/SalahTimes.docc")
    documents += try FileManager.default.contentsOfDirectory(
      at: catalog, includingPropertiesForKeys: nil
    ).filter { $0.pathExtension == "md" }
    #expect(documents.count == 6)

    for document in documents {
      let text = try String(contentsOf: document, encoding: .utf8)
      for block in Self.swiftBlocks(in: text) {
        if block.contains(".package(url:") {
          // A manifest excerpt can't run in a test. Check that it names this package.
          #expect(block.contains("https://github.com/salah-kit/SalahTimes.git"))
          continue
        }
        let matches = samples.filter { $0.value == block }.map(\.key)
        #expect(
          !matches.isEmpty,
          "\(document.lastPathComponent) has Swift code that matches no sample:\n\(block)")
        unused.subtract(matches)
      }
    }
    #expect(unused.isEmpty, "Samples that no document shows: \(unused.sorted())")
  }

  /// The package's root directory.
  private static let root = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()

  /// The samples in this file, by name, with their indentation normalized.
  private static func samples() throws -> [String: String] {
    let source = try String(contentsOf: URL(fileURLWithPath: #filePath), encoding: .utf8)
    var samples: [String: String] = [:]
    var name: String?
    var lines: [Substring] = []
    for line in source.split(separator: "\n", omittingEmptySubsequences: false) {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if trimmed.hasPrefix("// docs:begin ") {
        name = String(trimmed.dropFirst("// docs:begin ".count))
        lines = []
      } else if trimmed == "// docs:end", let current = name {
        samples[current] = normalized(lines)
        name = nil
      } else if name != nil {
        lines.append(line)
      }
    }
    return samples
  }

  /// The Swift code blocks in a Markdown document, with their indentation normalized.
  private static func swiftBlocks(in markdown: String) -> [String] {
    var blocks: [String] = []
    var lines: [Substring]?
    for line in markdown.split(separator: "\n", omittingEmptySubsequences: false) {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if lines == nil, trimmed == "```swift" {
        lines = []
      } else if let current = lines, trimmed == "```" {
        blocks.append(normalized(current))
        lines = nil
      } else if lines != nil {
        lines?.append(line)
      }
    }
    return blocks
  }

  /// Removes the indentation that all lines share, trailing spaces and surrounding blank lines.
  private static func normalized(_ lines: [Substring]) -> String {
    var lines = lines.map { String($0.reversed().drop(while: { $0 == " " }).reversed()) }
    while lines.first?.isEmpty == true { lines.removeFirst() }
    while lines.last?.isEmpty == true { lines.removeLast() }
    let indentation =
      lines.filter { !$0.isEmpty }.map { $0.prefix(while: { $0 == " " }).count }.min() ?? 0
    return lines.map { String($0.dropFirst(min(indentation, $0.count))) }.joined(separator: "\n")
  }
}
