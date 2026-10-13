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
