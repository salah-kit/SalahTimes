import Foundation

/// The Moonsighting Committee's seasonal values (docs/algorithm.md, section 8.6).
enum MoonsightingCommittee {
  /// The latitude from which the committee's rules also bound by the night's seventh.
  static let seventhLatitude: Double = 55

  /// Whether the seventh of the night bounds Fajr and Isha at a latitude: from 55°, north or
  /// south, inclusive.
  static func usesSeventh(latitude: Double) -> Bool {
    abs(latitude) >= seventhLatitude
  }

  /// The depression angle of the committee's raw Fajr and Isha.
  static let angle: Double = 18

  /// Days since the winter solstice of a day at a latitude, `s` in section 8.6.
  static func daysSinceWinterSolstice(of day: GregorianDay, latitude: Double) -> Int {
    let n = day.dayOfYear
    let daysInYear = day.isInLeapYear ? 366 : 365
    if latitude >= 0 {
      let s = n + 10
      return s >= daysInYear ? s - daysInYear : s
    }
    let s = n - (daysInYear == 366 ? 173 : 172)
    return s < 0 ? s + daysInYear : s
  }

  /// The piecewise-linear value through the coefficients `a`, `b`, `c` and `d` at `s` days since
  /// the winter solstice, in minutes.
  static func interpolate(_ s: Int, a: Double, b: Double, c: Double, d: Double) -> Double {
    let s = Double(s)
    if s < 91 { return a + (b - a) / 91 * s }
    if s < 137 { return b + (c - b) / 46 * (s - 91) }
    if s < 183 { return c + (d - c) / 46 * (s - 137) }
    if s < 229 { return d + (c - d) / 46 * (s - 183) }
    if s < 275 { return c + (b - c) / 46 * (s - 229) }
    return b + (a - b) / 91 * (s - 275)
  }

  /// `S_fajr`: minutes before sunrise, unrounded.
  static func fajrMinutes(day: GregorianDay, latitude: Double) -> Double {
    let x = abs(latitude) / 55
    return interpolate(
      daysSinceWinterSolstice(of: day, latitude: latitude),
      a: 75 + 28.65 * x, b: 75 + 19.44 * x, c: 75 + 32.74 * x, d: 75 + 48.10 * x)
  }

  /// `S_isha(shafaq)`: minutes after sunset, unrounded.
  static func ishaMinutes(day: GregorianDay, latitude: Double, shafaq: Shafaq) -> Double {
    let x = abs(latitude) / 55
    let s = daysSinceWinterSolstice(of: day, latitude: latitude)
    switch shafaq {
    case .general:
      return interpolate(
        s, a: 75 + 25.60 * x, b: 75 + 2.050 * x, c: 75 - 9.21 * x, d: 75 + 6.14 * x)
    case .ahmer:
      return interpolate(
        s, a: 62 + 17.40 * x, b: 62 - 7.16 * x, c: 62 + 5.12 * x, d: 62 + 19.44 * x)
    case .abyad:
      return interpolate(
        s, a: 75 + 25.60 * x, b: 75 + 7.16 * x, c: 75 + 36.84 * x, d: 75 + 81.84 * x)
    }
  }
}

/// The Ramadan Isha rule's calendar test (docs/algorithm.md, section 8.7).
enum Ramadan {
  /// Whether a civil day, read at 12:00 UTC, falls in month 9 of the Umm al-Qura calendar.
  static func contains(_ day: GregorianDay) -> Bool {
    guard let utc = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0) else {
      return false
    }
    var calendar = Calendar(identifier: .islamicUmmAlQura)
    calendar.timeZone = utc
    let noon = Date(
      timeIntervalSince1970: Double(day.daysSince1970) * Astronomy.secondsPerDay + 43_200)
    return calendar.component(.month, from: noon) == 9
  }
}
