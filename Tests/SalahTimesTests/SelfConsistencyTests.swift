import Foundation
import SalahTimes
import Testing

/// Checks that the Sun is where each event says it is, with a solar model written here.
///
/// ``NOAASun`` follows NOAA's "General Solar Position Calculations" and its solar-calculator
/// spreadsheet: the hour angle comes from the equation of time (true solar time), not from the
/// right ascension and sidereal time that the engine uses (algorithm.md §4), and Julian Days use
/// UT throughout, without ΔT. At each computed instant the test measures the Sun's geometric
/// altitude with this model and compares it with the altitude that defines the event.
///
/// Tolerance: ``altitudeTolerance`` (0.03°) and ``hourAngleTolerance`` (0.03°, two seconds of
/// time short of NOAA's own stated accuracy for solar noon). The two models share the Sun's
/// longitude series, so declinations agree to well under 0.001°. They differ in the hour angle:
/// NOAA's equation-of-time series is an approximation that differs from the right-ascension form
/// by up to about 7 seconds of time, 0.03° of hour angle. The altitude error that causes is at
/// most the hour-angle error times cos φ cos δ sin H, so 0.03° bounds both. Engine times are
/// computed with `rounding: .none` and no minute adjustments, so the instants aren't moved.
@Suite("Self-consistency")
struct SelfConsistencyTests {
  static let altitudeTolerance = 0.03
  static let hourAngleTolerance = 0.03

  static let latitudes = stride(from: -60.0, through: 60.0, by: 10).map { $0 }
  static let longitudes = [-157.5, -75.0, 0.0, 37.5, 106.0]
  static let days: [GregorianDay] = {
    var days: [GregorianDay] = []
    for month in 1...12 {
      for day in [1, 15] {
        days.append(GregorianDay(year: 2026, month: month, day: day)!)
      }
    }
    days += [
      GregorianDay(year: 1950, month: 6, day: 21)!,
      GregorianDay(year: 2000, month: 12, day: 21)!,
      GregorianDay(year: 2100, month: 3, day: 20)!,
    ]
    return days
  }()

  struct Case {
    let fajrAngle: Double
    let ishaAngle: Double
    let maghribAngle: Double?
    let madhab: Madhab
  }

  static let cases = [
    Case(fajrAngle: 18, ishaAngle: 17, maghribAngle: nil, madhab: .shafi),
    Case(fajrAngle: 15, ishaAngle: 15, maghribAngle: nil, madhab: .hanafi),
    Case(fajrAngle: 19.5, ishaAngle: 17.5, maghribAngle: 4.5, madhab: .shafi),
  ]

  @Test("The Sun is at each event's altitude", arguments: cases.indices)
  func altitudes(caseIndex: Int) throws {
    let setup = Self.cases[caseIndex]
    var parameters = CalculationParameters(
      fajr: .angle(setup.fajrAngle), isha: .angle(setup.ishaAngle),
      maghrib: setup.maghribAngle.map { .angle($0) } ?? .sunset, madhab: setup.madhab,
      highLatitudeRule: .disabled)
    parameters.rounding = .none

    var worstAltitude = 0.0
    var worstHourAngle = 0.0
    var checked = 0
    for latitude in Self.latitudes {
      for longitude in Self.longitudes {
        let coordinates = Coordinates(latitude: latitude, longitude: longitude)
        let timeZone = Self.fixedZone(longitude: longitude)
        for day in Self.days {
          let times = try PrayerTimes(
            coordinates: coordinates, day: day, timeZone: timeZone, parameters: parameters)
          let place = "\(latitude), \(longitude) on \(day)"

          // Dhuhr: the hour angle is zero.
          let dhuhr = try #require(times.dhuhr.date, "\(place): no Dhuhr")
          let hourAngle = NOAASun.hourAngle(at: dhuhr, longitude: longitude)
          worstHourAngle = max(worstHourAngle, abs(hourAngle))
          #expect(abs(hourAngle) <= Self.hourAngleTolerance, "\(place): Dhuhr H = \(hourAngle)")

          // Altitude crossings.
          let declinationAtNoon = NOAASun.position(at: dhuhr).declination
          let zenithAtNoon = abs(latitude - declinationAtNoon)
          var targets: [(String, EventTime, Double)] = [
            ("fajr", times.fajr, -setup.fajrAngle),
            ("sunrise", times.sunrise, -50.0 / 60),
            ("sunset", times.sunset, -50.0 / 60),
            ("isha", times.isha, -setup.ishaAngle),
          ]
          targets.append(("maghrib", times.maghrib, -(setup.maghribAngle ?? 50.0 / 60)))
          if zenithAtNoon < 90 {
            let asrAltitude = NOAASun.degrees(
              atan(1 / (setup.madhab.shadowFactor + tan(NOAASun.radians(zenithAtNoon)))))
            targets.append(("asr", times.asr, asrAltitude))
          }
          for (name, event, target) in targets {
            guard let instant = event.date else { continue }
            let altitude = NOAASun.altitude(
              at: instant, latitude: latitude, longitude: longitude)
            worstAltitude = max(worstAltitude, abs(altitude - target))
            checked += 1
            #expect(
              abs(altitude - target) <= Self.altitudeTolerance,
              "\(place) \(name): altitude \(altitude), expected \(target)")
          }
        }
      }
    }
    print(
      "Self-consistency case \(caseIndex): \(checked) crossings, max |Δh| "
        + "\(String(format: "%.4f", worstAltitude))°, max |H| at Dhuhr "
        + "\(String(format: "%.4f", worstHourAngle))°")
    #expect(checked > 5_000)
  }

  @Test("The model reproduces Meeus's worked examples")
  func meeusExamples() {
    // Meeus, Astronomical Algorithms, example 25.a: on 1992-10-13 at 0h TD the apparent
    // declination is -7.78507°. This model reads the instant as UT, about 59 s earlier, which
    // moves the declination by under 0.0003°.
    let instant = Date(timeIntervalSince1970: 718_934_400)  // 1992-10-13T00:00:00Z
    let position = NOAASun.position(at: instant)
    #expect(abs(position.declination - -7.78507) < 0.002)
    // Example 28.b gives the equation of time that day as 13m 42.6s (13.71 minutes).
    #expect(abs(position.equationOfTimeMinutes - 13.71) < 0.1)
  }

  static func fixedZone(longitude: Double) -> TimeZone {
    TimeZone(secondsFromGMT: Int((longitude / 15).rounded()) * 3_600)!
  }

  /// The Sun's position by NOAA's spreadsheet formulas.
  ///
  /// NOAA Global Monitoring Laboratory, "General Solar Position Calculations" and the NOAA
  /// Solar Calculator spreadsheet (https://gml.noaa.gov/grad/solcalc/calcdetails.html).
  enum NOAASun {
    struct Position {
      /// Apparent declination, in degrees.
      let declination: Double
      /// Equation of time, in minutes.
      let equationOfTimeMinutes: Double
    }

    static func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }
    static func degrees(_ radians: Double) -> Double { radians * 180 / .pi }

    static func position(at date: Date) -> Position {
      let julianDay = date.timeIntervalSince1970 / 86_400 + 2_440_587.5
      let century = (julianDay - 2_451_545) / 36_525
      let meanLongitude = (280.46646 + century * (36_000.76983 + century * 0.0003032))
        .truncatingRemainder(dividingBy: 360)
      let meanAnomaly = 357.52911 + century * (35_999.05029 - 0.0001537 * century)
      let eccentricity = 0.016708634 - century * (0.000042037 + 0.0000001267 * century)
      let m = radians(meanAnomaly)
      let center =
        sin(m) * (1.914602 - century * (0.004817 + 0.000014 * century))
        + sin(2 * m) * (0.019993 - 0.000101 * century) + sin(3 * m) * 0.000289
      let trueLongitude = meanLongitude + center
      let omega = radians(125.04 - 1_934.136 * century)
      let apparentLongitude = trueLongitude - 0.00569 - 0.00478 * sin(omega)
      let meanObliquity =
        23 + (26 + (21.448 - century * (46.815 + century * (0.00059 - century * 0.001813))) / 60)
        / 60
      let obliquity = meanObliquity + 0.00256 * cos(omega)
      let declination = degrees(asin(sin(radians(obliquity)) * sin(radians(apparentLongitude))))
      let y = pow(tan(radians(obliquity / 2)), 2)
      let l0 = radians(meanLongitude)
      let equationOfTime =
        4
        * degrees(
          y * sin(2 * l0) - 2 * eccentricity * sin(m) + 4 * eccentricity * y * sin(m) * cos(2 * l0)
            - 0.5 * y * y * sin(4 * l0) - 1.25 * eccentricity * eccentricity * sin(2 * m))
      return Position(declination: declination, equationOfTimeMinutes: equationOfTime)
    }

    /// The local hour angle in degrees, in (-180, 180], from true solar time.
    static func hourAngle(at date: Date, longitude: Double) -> Double {
      let seconds = date.timeIntervalSince1970
      let minutesOfDay = (seconds / 60).truncatingRemainder(dividingBy: 1_440)
      let trueSolarTime = minutesOfDay + position(at: date).equationOfTimeMinutes + 4 * longitude
      var angle = (trueSolarTime / 4 - 180).truncatingRemainder(dividingBy: 360)
      if angle <= -180 { angle += 360 }
      if angle > 180 { angle -= 360 }
      return angle
    }

    /// The Sun's geometric altitude in degrees, without refraction.
    static func altitude(at date: Date, latitude: Double, longitude: Double) -> Double {
      let declination = radians(position(at: date).declination)
      let phi = radians(latitude)
      let h = radians(hourAngle(at: date, longitude: longitude))
      let sine = sin(phi) * sin(declination) + cos(phi) * cos(declination) * cos(h)
      return degrees(asin(max(-1, min(1, sine))))
    }

    /// The solar noon nearest an instant, where the hour angle is zero.
    static func solarNoon(near date: Date, longitude: Double) -> Date {
      var noon = date
      for _ in 0..<5 {
        noon = noon.addingTimeInterval(-hourAngle(at: noon, longitude: longitude) / 360 * 86_400)
      }
      return noon
    }

    /// When the Sun reaches an altitude between `noon` and the lower culmination before it
    /// (`morning`) or after it, by bisection; `nil` when it doesn't reach it.
    static func crossing(
      altitude target: Double, noon: Date, latitude: Double, longitude: Double, morning: Bool
    ) -> Date? {
      let farSide = noon.addingTimeInterval(morning ? -43_200 : 43_200)
      let low = altitude(at: farSide, latitude: latitude, longitude: longitude)
      let high = altitude(at: noon, latitude: latitude, longitude: longitude)
      guard low < target, target < high else { return nil }
      var below = farSide
      var above = noon
      for _ in 0..<40 {
        let middle = Date(
          timeIntervalSince1970: (below.timeIntervalSince1970 + above.timeIntervalSince1970) / 2)
        if altitude(at: middle, latitude: latitude, longitude: longitude) < target {
          below = middle
        } else {
          above = middle
        }
      }
      return above
    }
  }
}
