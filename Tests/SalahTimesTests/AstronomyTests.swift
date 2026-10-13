import Foundation
import Testing

@testable import SalahTimes

/// The astronomy core against published worked examples (docs/algorithm.md, sections 3 to 7).
@Suite("Astronomy")
struct AstronomyTests {
  /// POSIX seconds of a UTC date and time.
  private static func instant(
    _ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0,
    _ second: Double = 0
  ) throws -> Double {
    let civil = try #require(GregorianDay(year: year, month: month, day: day))
    return Double(civil.daysSince1970) * 86_400 + Double(hour * 3600 + minute * 60) + second
  }

  @Test("Julian Day from POSIX seconds (Meeus Example 7.a, J2000.0)")
  func julianDay() throws {
    // Meeus, Astronomical Algorithms, 2nd ed., Example 7.a: 1957 October 4.81 is JD 2436116.31.
    let sputnik = try Self.instant(1957, 10, 4) + 0.81 * 86_400
    #expect(abs(Astronomy.julianDay(sputnik) - 2_436_116.31) < 1e-6)
    // J2000.0 is 2000 January 1, 12h, JD 2451545.0.
    let j2000 = try Self.instant(2000, 1, 1, 12)
    #expect(Astronomy.julianDay(j2000) == 2_451_545.0)
    #expect(Astronomy.daysSinceJ2000(j2000) == 0)
    #expect(Astronomy.j2000 == j2000)
  }

  @Test("The Sun on 1992 October 13.0 TD (Meeus Example 25.a)")
  func meeusExample25a() {
    // Published values of Meeus, Astronomical Algorithms, 2nd ed. (1998), Example 25.a, p. 165.
    // The final place is reproduced by pymeeus's tests (github.com/architest/pymeeus,
    // tests/test_sun.py: true longitude 199°54'36", apparent longitude 199°54'32",
    // α = 13h13m31.4s, δ = -7°47'06") and by the R package oce's documentation of
    // sunDeclinationRightAscension (δ = -7.78507°, α = -161.61919°). Retrieved 2026-10-13.
    // The book rounds each intermediate to five decimals, so Θ and λ carry 1e-5° of rounding.
    let jde = 2_448_908.5
    let sun = SolarCoordinates(julianCenturies: (jde - 2_451_545.0) / 36_525)
    #expect(abs(sun.t - -0.072_183_436) < 1e-9)
    #expect(abs(sun.meanLongitude - 201.80720) < 1e-5)
    #expect(abs(sun.meanAnomaly - 278.99397) < 1e-5)
    #expect(abs(sun.equationOfCenter - -1.89732) < 1e-5)
    #expect(abs(sun.trueLongitude - 199.90988) < 2e-5)
    #expect(abs(normalize360(sun.omega) - 264.65) < 0.005)
    #expect(abs(sun.apparentLongitude - 199.90895) < 2e-5)
    #expect(abs(sun.meanObliquity - (23 + 26 / 60 + 24.83 / 3600)) < 1e-5)
    #expect(abs(sun.obliquity - 23.43999) < 1e-5)
    #expect(abs(sun.rightAscension - -161.61917) < 1e-5)
    #expect(abs(normalize360(sun.rightAscension) / 15 - (13 + 13 / 60 + 31.4 / 3600)) < 1e-5)
    #expect(abs(sun.declination - -7.78507) < 1e-5)
  }

  @Test("Mean sidereal time at Greenwich (Meeus Examples 12.a and 12.b)")
  func meeusExamples12() throws {
    // Meeus, 2nd ed., Example 12.a: 1987 April 10, 0h UT, θ0 = 13h10m46.3668s.
    let midnight = try Self.instant(1987, 4, 10)
    let a = Astronomy.meanSiderealTime(daysSinceJ2000: Astronomy.daysSinceJ2000(midnight))
    #expect(abs(a - (13 + 10 / 60 + 46.3668 / 3600) * 15) < 1e-5)
    #expect(abs(a - 197.693195) < 1e-5)
    // Example 12.b: 1987 April 10, 19h21m00s UT, θ0 = 128.7378734° = 8h34m57.0896s.
    let evening = try Self.instant(1987, 4, 10, 19, 21)
    let b = Astronomy.meanSiderealTime(daysSinceJ2000: Astronomy.daysSinceJ2000(evening))
    #expect(abs(b - 128.737_873_4) < 1e-5)
    #expect(abs(b - (8 + 34 / 60 + 57.0896 / 3600) * 15) < 1e-5)
  }

  @Test("ΔT agrees with NASA's table of observed values")
  func deltaTTable() {
    // NASA, "Historical Values of Delta T", https://eclipse.gsfc.nasa.gov/SEcat5/deltat.html,
    // retrieved 2026-10-13. The polynomials fit the observations to a few tenths of a second.
    let observed: [(year: Double, seconds: Double, tolerance: Double)] = [
      (1900, -3, 0.5), (1950, 29, 0.2), (1960, 33.2, 0.2), (1970, 40.2, 0.2),
      (1980, 50.5, 0.2), (1990, 56.9, 0.2), (2000, 63.8, 0.2), (2005, 64.7, 0.2),
    ]
    for row in observed {
      let value = Astronomy.deltaT(decimalYear: row.year)
      #expect(abs(value - row.seconds) < row.tolerance, "ΔT at \(row.year) is \(value)")
    }
  }

  @Test("ΔT follows each polynomial of section 3")
  func deltaTPolynomials() {
    // Values worked by hand from the expressions in docs/algorithm.md, section 3.
    #expect(abs(Astronomy.deltaT(decimalYear: 1820) - -20) < 1e-9)
    #expect(abs(Astronomy.deltaT(decimalYear: 2200) - (-20 + 32 * 3.8 * 3.8)) < 1e-9)
    #expect(abs(Astronomy.deltaT(decimalYear: 1900) - -2.79) < 1e-9)
    #expect(abs(Astronomy.deltaT(decimalYear: 1920) - 21.20) < 1e-9)
    #expect(abs(Astronomy.deltaT(decimalYear: 1950) - 29.07) < 1e-9)
    #expect(abs(Astronomy.deltaT(decimalYear: 1975) - 45.45) < 1e-9)
    #expect(abs(Astronomy.deltaT(decimalYear: 2000) - 63.86) < 1e-9)
    #expect(abs(Astronomy.deltaT(decimalYear: 2010) - (62.92 + 3.2217 + 0.5589)) < 1e-9)
    #expect(
      abs(Astronomy.deltaT(decimalYear: 2100) - (-20 + 32 * 2.8 * 2.8 - 0.5628 * 50)) < 1e-9)
    // The decimal year is the middle of the instant's UTC month.
    let march2026 = Double(GregorianDay(year: 2026, month: 3, day: 31)!.daysSince1970) * 86_400
    #expect(abs(Astronomy.decimalYear(march2026 + 86_399) - (2026 + 2.5 / 12)) < 1e-12)
    #expect(abs(Astronomy.decimalYear(march2026 + 86_400) - (2026 + 3.5 / 12)) < 1e-12)
  }

  @Test("Angles normalize into their ranges")
  func normalization() {
    #expect(normalize360(-30) == 330)
    #expect(normalize360(720) == 0)
    #expect(normalize360(-1e-15) < 360)
    #expect(normalize180(180) == 180)
    #expect(normalize180(-180) == 180)
    #expect(normalize180(190) == -170)
    #expect(normalize180(-190) == 170)
  }

  @Test("Transits put the Sun on the meridian and crossings reach their altitude")
  func eventsSolveTheirEquations() throws {
    let observer = Observer(latitude: 21.4225, longitude: 39.8262)
    let riyadh = try #require(TimeZone(identifier: "Asia/Riyadh"))
    let day = try #require(GregorianDay(year: 2026, month: 3, day: 20))
    let transit = observer.transit(of: day, in: riyadh)
    #expect(abs(observer.hourAngle(at: transit)) < 1e-5)

    for (altitude, side) in [(-50.0 / 60, -1.0), (-50.0 / 60, 1), (-18, -1), (-17, 1), (40, 1)] {
      let event = observer.crossing(transit: transit, altitude: altitude, side: side)
      let t = try #require(event.seconds)
      #expect(abs(observer.altitude(at: t) - altitude) < 1e-4)
      #expect(side < 0 ? t < transit : t > transit)
    }

    // At Asr an object's shadow is its length plus its noon shadow.
    let asr = try #require(observer.asr(transit: transit, shadowFactor: 1).seconds)
    let noonZenith = 90 - observer.altitude(at: transit)
    let asrZenith = 90 - observer.altitude(at: asr)
    let shadow = tan(radians(asrZenith))
    #expect(abs(shadow - (1 + tan(radians(noonZenith)))) < 1e-4)
    let hanafi = try #require(observer.asr(transit: transit, shadowFactor: 2).seconds)
    #expect(hanafi > asr)
  }

  @Test("Crossings report which way the Sun fails")
  func crossingNonOccurrence() throws {
    let observer = Observer(latitude: 78.22, longitude: 15.65)
    let oslo = try #require(TimeZone(identifier: "Arctic/Longyearbyen"))
    let june = observer.transit(of: try #require(GregorianDay("2026-06-21")), in: oslo)
    #expect(observer.sunset(transit: june) == .doesNotOccur(.sunStaysAbove))
    let december = observer.transit(of: try #require(GregorianDay("2026-12-21")), in: oslo)
    #expect(observer.sunrise(transit: december) == .doesNotOccur(.sunStaysBelow))
    #expect(observer.asr(transit: december, shadowFactor: 1) == .doesNotOccur(.sunStaysBelow))
    // At the poles cos φ isn't exactly zero, so the test still reports the right reason.
    let pole = Observer(latitude: 90, longitude: 0)
    #expect(pole.sunset(transit: june) == .doesNotOccur(.sunStaysAbove))
    #expect(pole.sunrise(transit: december) == .doesNotOccur(.sunStaysBelow))
  }
}
