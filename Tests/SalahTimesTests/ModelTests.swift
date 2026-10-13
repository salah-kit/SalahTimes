import Foundation
import Testing

@testable import SalahTimes

@Suite("Model")
struct ModelTests {
  @Test("GregorianDay round-trips through days since 1970")
  func gregorianDayConversions() throws {
    for days in stride(from: -800_000, through: 800_000, by: 997) {
      let day = GregorianDay(daysSince1970: days)
      #expect(day.daysSince1970 == days)
      #expect(GregorianDay(year: day.year, month: day.month, day: day.day) == day)
    }
    #expect(GregorianDay(daysSince1970: 0).description == "1970-01-01")
    #expect(try #require(GregorianDay(year: 2024, month: 2, day: 29)).dayOfYear == 60)
    #expect(GregorianDay(year: 2026, month: 2, day: 29) == nil)
    #expect(GregorianDay(year: 2026, month: 13, day: 1) == nil)
  }

  @Test("GregorianDay parses and prints ISO 8601")
  func gregorianDayStrings() throws {
    #expect(GregorianDay("2026-03-20")?.description == "2026-03-20")
    #expect(GregorianDay("+10000-01-01")?.year == 10_000)
    #expect(GregorianDay("-0001-12-31")?.year == -1)
    #expect(GregorianDay("2026-3-20") == nil)
    #expect(GregorianDay("10000-01-01") == nil)
    #expect(GregorianDay("2026-02-30") == nil)
    let encoded = try JSONEncoder().encode(GregorianDay(year: 2026, month: 3, day: 20))
    #expect(String(decoding: encoded, as: UTF8.self) == "\"2026-03-20\"")
  }

  @Test("GregorianDay contains an instant in its time zone")
  func gregorianDayContaining() throws {
    // 2026-03-20T22:30:00Z is already 21 March in Riyadh (UTC+3).
    let instant = Date(timeIntervalSince1970: 1_774_045_800)
    let riyadh = try #require(TimeZone(identifier: "Asia/Riyadh"))
    let utc = try #require(TimeZone(identifier: "UTC"))
    #expect(GregorianDay(containing: instant, in: riyadh).description == "2026-03-21")
    #expect(GregorianDay(containing: instant, in: utc).description == "2026-03-20")
  }

  @Test("Parameters round-trip through JSON", arguments: CalculationMethod.allCases)
  func parametersRoundTrip(method: CalculationMethod) throws {
    var parameters = method.parameters
    parameters.adjustments = PrayerAdjustments(fajr: 2, isha: -3)
    parameters.ramadanIsha = .interval(minutes: 120, hijriDayOffset: -1)
    let data = try JSONEncoder().encode(parameters)
    #expect(try JSONDecoder().decode(CalculationParameters.self, from: data) == parameters)
  }

  @Test("Parameters decode with defaults")
  func parametersDefaults() throws {
    let json = Data(#"{"fajr": {"angle": 18}, "isha": {"minutesAfterMaghrib": 90}}"#.utf8)
    let decoded = try JSONDecoder().decode(CalculationParameters.self, from: json)
    #expect(decoded == CalculationParameters(fajr: .angle(18), isha: .minutesAfterMaghrib(90)))
  }

  @Test("Qibla points the right way")
  func qibla() throws {
    let london = Coordinates(latitude: 51.5072, longitude: -0.1276)
    let bearing = try #require(Qibla.direction(from: london))
    #expect(abs(bearing - 119) < 1)
    #expect(Qibla.direction(from: Qibla.kaaba) == nil)
    #expect(Qibla.direction(from: Coordinates(latitude: 91, longitude: 0)) == nil)
  }

  @Test("Qibla bearings stay below 360°")
  func qiblaBelow360() throws {
    // Just east of the Kaaba's meridian and south of it, the bearing is a tiny negative angle
    // that a naive `+ 360` rounds to exactly 360.
    for latitude in [0.0, -30, -60] {
      let place = Coordinates(latitude: latitude, longitude: Qibla.kaaba.longitude.nextUp)
      let bearing = try #require(Qibla.direction(from: place))
      #expect(bearing >= 0 && bearing < 360, "\(bearing)")
    }
  }

  @Test("GregorianDay holds years from -999999 to 999999")
  func gregorianDayRange() throws {
    #expect(GregorianDay(year: Int.min, month: 1, day: 1) == nil)
    #expect(GregorianDay(year: 1_000_000, month: 1, day: 1) == nil)
    #expect(GregorianDay("+100000000000000000-01-01") == nil)
    #expect(GregorianDay("+1000000-01-01") == nil)
    let json = Data(#""+100000000000000000-01-01""#.utf8)
    #expect(throws: DecodingError.self) { try JSONDecoder().decode(GregorianDay.self, from: json) }

    let last = try #require(GregorianDay("+999999-12-31"))
    let first = try #require(GregorianDay("-999999-01-01"))
    #expect(last.description == "+999999-12-31")
    #expect(first.description == "-999999-01-01")
    #expect(last.adding(days: -1) == GregorianDay(year: 999_999, month: 12, day: 30))
    #expect(first.adding(days: 1) == GregorianDay(year: -999_999, month: 1, day: 2))
    #expect(first.adding(days: last.daysSince1970 - first.daysSince1970) == last)
    let lastInstant = Date(timeIntervalSince1970: Double(last.daysSince1970) * 86_400 + 43_200)
    #expect(GregorianDay(containing: lastInstant, in: TimeZone(secondsFromGMT: 0)!) == last)
  }

  #if compiler(>=6.2) && (os(macOS) || os(Linux))
    @Test("GregorianDay stops at the edges of its years")
    func gregorianDayPreconditions() async {
      await #expect(processExitsWith: .failure) {
        _ = GregorianDay(year: 999_999, month: 12, day: 31)!.adding(days: 1)
      }
      await #expect(processExitsWith: .failure) {
        _ = GregorianDay(year: 2026, month: 1, day: 1)!.adding(days: .max)
      }
      await #expect(processExitsWith: .failure) {
        _ = GregorianDay(containing: Date(timeIntervalSince1970: 1e300), in: .current)
      }
      await #expect(processExitsWith: .failure) {
        _ = GregorianDay(containing: Date(timeIntervalSince1970: .nan), in: .current)
      }
    }
  #endif

  @Test("An event time decodes from exactly one key")
  func eventTimeDecoding() throws {
    let decoder = JSONDecoder()
    let both = Data(#"{"occurs": 0, "doesNotOccur": "sunStaysAbove"}"#.utf8)
    #expect(throws: DecodingError.self) { try decoder.decode(EventTime.self, from: both) }
    let neither = Data(#"{}"#.utf8)
    #expect(throws: DecodingError.self) { try decoder.decode(EventTime.self, from: neither) }
    let occurs = try decoder.decode(EventTime.self, from: Data(#"{"occurs": 0}"#.utf8))
    #expect(occurs == .occurs(Date(timeIntervalSinceReferenceDate: 0)))
    let reason = Data(#"{"doesNotOccur": "sunStaysBelow"}"#.utf8)
    #expect(try decoder.decode(EventTime.self, from: reason) == .doesNotOccur(.sunStaysBelow))
  }

  @Test("An autoupdating time zone is stored as the zone it stood for")
  func fixedTimeZone() throws {
    let current = TimeZone.autoupdatingCurrent
    let fixed = try #require(TimeZone(identifier: current.identifier))
    let times = try PrayerTimes(
      coordinates: Coordinates(latitude: 30.0444, longitude: 31.2357),
      day: try #require(GregorianDay("2026-03-20")), timeZone: current,
      parameters: CalculationMethod.egyptian.parameters)
    #expect(times.timeZone == fixed)
    let json = String(decoding: try JSONEncoder().encode(times), as: UTF8.self)
    #expect(!json.contains(#""autoupdating":true"#), "\(json)")
  }

  @Test("Qibla resolves places within a few metres of the Kaaba's antipode")
  func qiblaNearTheAntipode() throws {
    // The antipode itself has no direction, and neither does a point 1e-11° from it, about
    // 1e-13 radians, below section 10's 1e-9.
    let antipode = (latitude: -21.4225241, longitude: -140.1738182)
    let none = [0, 1e-11].map {
      Qibla.direction(from: Coordinates(latitude: antipode.latitude + $0, longitude: -140.1738182))
    }
    #expect(none == [nil, nil])
    // 3e-7° north of the antipode, about 5e-9 radians, the Kaaba lies due north. The haversine
    // formula loses that distance to rounding and reports the antipode itself.
    let north = Coordinates(latitude: antipode.latitude + 3e-7, longitude: antipode.longitude)
    let bearing = try #require(Qibla.direction(from: north))
    #expect(min(bearing, 360 - bearing) < 1e-5)
  }
}
