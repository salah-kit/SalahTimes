import Foundation

/// Time scales and the Sun's position (docs/algorithm.md, sections 3 and 4).
///
/// Instants are POSIX seconds (`Double`), as in the specification.
enum Astronomy {
  /// J2000.0, 2000-01-01T12:00:00 UT (JD 2451545.0), in POSIX seconds.
  static let j2000: Double = 946_728_000

  /// Seconds in a day.
  static let secondsPerDay: Double = 86_400

  /// The Julian Day of an instant: `t / 86400 + 2440587.5`.
  static func julianDay(_ t: Double) -> Double {
    t / secondsPerDay + 2_440_587.5
  }

  /// Days since J2000.0 of an instant, `JD - 2451545.0`.
  ///
  /// It's computed from the POSIX seconds directly, which is the same value as subtracting from
  /// the Julian Day but keeps a few more digits.
  static func daysSinceJ2000(_ t: Double) -> Double {
    (t - j2000) / secondsPerDay
  }

  // MARK: ΔT

  /// ΔT = TT - UT in seconds at a decimal year, by Espenak and Meeus's polynomials as section 3
  /// lists them.
  static func deltaT(decimalYear y: Double) -> Double {
    if y < -500 || y >= 2150 {
      let u = (y - 1820) / 100
      return -20 + 32 * u * u
    }
    if y < 500 {
      let u = y / 100
      return 10_583.6
        + u
        * (-1014.41
          + u
          * (33.783_11
            + u * (-5.952_053 + u * (-0.179_845_2 + u * (0.022_174_192 + u * 0.009_031_652_1)))))
    }
    if y < 1600 {
      let u = (y - 1000) / 100
      return 1574.2
        + u
        * (-556.01
          + u
          * (71.234_72
            + u * (0.319_781 + u * (-0.850_346_3 + u * (-0.005_050_998 + u * 0.008_357_207_3)))))
    }
    if y < 1700 {
      let t = y - 1600
      return 120 + t * (-0.9808 + t * (-0.015_32 + t / 7129))
    }
    if y < 1800 {
      let t = y - 1700
      return 8.83 + t * (0.1603 + t * (-0.005_928_5 + t * (0.000_133_36 - t / 1_174_000)))
    }
    if y < 1860 {
      let t = y - 1800
      return 13.72
        + t
        * (-0.332_447
          + t
          * (0.006_861_2
            + t
            * (0.004_111_6
              + t
              * (-0.000_374_36
                + t * (0.000_012_127_2 + t * (-0.000_000_169_9 + t * 0.000_000_000_875))))))
    }
    if y < 1900 {
      let t = y - 1860
      return 7.62
        + t
        * (0.5737 + t * (-0.251_754 + t * (0.016_806_68 + t * (-0.000_447_362_4 + t / 233_174))))
    }
    if y < 1920 {
      let t = y - 1900
      return -2.79 + t * (1.494119 + t * (-0.059_893_9 + t * (0.006_196_6 - t * 0.000_197)))
    }
    if y < 1941 {
      let t = y - 1920
      return 21.20 + t * (0.84493 + t * (-0.076100 + t * 0.002_093_6))
    }
    if y < 1961 {
      let t = y - 1950
      return 29.07 + 0.407 * t - t * t / 233 + t * t * t / 2547
    }
    if y < 1986 {
      let t = y - 1975
      return 45.45 + 1.067 * t - t * t / 260 - t * t * t / 718
    }
    if y < 2005 {
      let t = y - 2000
      let t2 = t * t
      return 63.86 + 0.3345 * t - 0.060374 * t2 + 0.001_727_5 * t2 * t
        + 0.000_651_814 * t2 * t2 + 0.000_023_735_99 * t2 * t2 * t
    }
    if y < 2050 {
      let t = y - 2000
      return 62.92 + t * (0.32217 + t * 0.005589)
    }
    let u = (y - 1820) / 100
    return -20 + 32 * u * u - 0.5628 * (2150 - y)
  }

  /// The decimal year `year + (month - 0.5) / 12` of an instant's UTC calendar date.
  static func decimalYear(_ t: Double) -> Double {
    let utcDay = GregorianDay(daysSince1970: Int((t / secondsPerDay).rounded(.down)))
    return Double(utcDay.year) + (Double(utcDay.month) - 0.5) / 12
  }

  /// ΔT in seconds at an instant.
  static func deltaT(_ t: Double) -> Double {
    deltaT(decimalYear: decimalYear(t))
  }

  // MARK: Sidereal time

  /// Meeus's mean sidereal time at Greenwich (equation 12.4), in degrees in [0, 360), for a UT
  /// instant given as days since J2000.0.
  static func meanSiderealTime(daysSinceJ2000 d: Double) -> Double {
    let tu = d / 36_525
    return normalize360(
      280.460_618_37 + 360.985_647_366_29 * d + 0.000_387_933 * tu * tu
        - tu * tu * tu / 38_710_000)
  }

  // MARK: The Sun at an instant

  /// The Sun's apparent place and the apparent sidereal time at an instant.
  static func sun(at t: Double) -> SunState {
    let daysUT = daysSinceJ2000(t)
    let daysTT = daysUT + deltaT(t) / secondsPerDay
    let coordinates = SolarCoordinates(julianCenturies: daysTT / 36_525)
    let nutation = -0.00478 * sin(radians(coordinates.omega))
    let sidereal =
      meanSiderealTime(daysSinceJ2000: daysUT) + nutation * cos(radians(coordinates.obliquity))
    return SunState(
      rightAscension: coordinates.rightAscension, declination: coordinates.declination,
      siderealTime: sidereal)
  }
}

/// The Sun's apparent right ascension and declination, and Greenwich apparent sidereal time, in
/// degrees.
struct SunState {
  var rightAscension: Double
  var declination: Double
  var siderealTime: Double

  /// The local hour angle `normalize180(θ + L - α)` at a longitude, positive west of the
  /// meridian (after transit).
  func hourAngle(longitude: Double) -> Double {
    normalize180(siderealTime + longitude - rightAscension)
  }
}

/// Meeus chapter 25's lower-accuracy solar coordinates with the apparent-place correction
/// (section 4). Every angle is in degrees.
struct SolarCoordinates {
  /// Julian centuries of TT since J2000.0.
  var t: Double
  /// The geometric mean longitude L0, in [0, 360).
  var meanLongitude: Double
  /// The mean anomaly M, in [0, 360).
  var meanAnomaly: Double
  /// The equation of the center C.
  var equationOfCenter: Double
  /// The true longitude Θ = L0 + C.
  var trueLongitude: Double
  /// The longitude of the Moon's ascending node Ω (unnormalized).
  var omega: Double
  /// The apparent longitude λ.
  var apparentLongitude: Double
  /// The mean obliquity ε0.
  var meanObliquity: Double
  /// The true obliquity ε, corrected for the apparent place.
  var obliquity: Double
  /// The apparent right ascension α, in (-180, 180].
  var rightAscension: Double
  /// The apparent declination δ.
  var declination: Double

  /// - Parameter t: Julian centuries of TT since J2000.0, `(JDE - 2451545.0) / 36525`.
  init(julianCenturies t: Double) {
    self.t = t
    meanLongitude = normalize360(280.46646 + t * (36_000.76983 + t * 0.000_303_2))
    meanAnomaly = normalize360(357.52911 + t * (35_999.05029 - t * 0.000_153_7))
    let m = radians(meanAnomaly)
    equationOfCenter =
      (1.914602 - t * (0.004817 + t * 0.000_014)) * sin(m)
      + (0.019993 - t * 0.000_101) * sin(2 * m)
      + 0.000_289 * sin(3 * m)
    trueLongitude = meanLongitude + equationOfCenter
    omega = 125.04 - 1934.136 * t
    let sinOmega = sin(radians(omega))
    apparentLongitude = trueLongitude - 0.00569 - 0.00478 * sinOmega
    meanObliquity =
      23 + 26 / 60 + 21.448 / 3600 - t * (46.8150 + t * (0.00059 - t * 0.001813)) / 3600
    obliquity = meanObliquity + 0.00256 * cos(radians(omega))
    let lambda = radians(apparentLongitude)
    let epsilon = radians(obliquity)
    let sinLambda = sin(lambda)
    rightAscension = degrees(atan2(cos(epsilon) * sinLambda, cos(lambda)))
    declination = degrees(asin(sin(epsilon) * sinLambda))
  }
}

// MARK: Angles

/// Degrees to radians.
@inline(__always)
func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }

/// Radians to degrees.
@inline(__always)
func degrees(_ radians: Double) -> Double { radians * 180 / .pi }

/// Maps an angle in degrees into [0, 360).
func normalize360(_ x: Double) -> Double {
  let r = x - 360 * (x / 360).rounded(.down)
  // A tiny negative x can round up to exactly 360.
  return r >= 360 ? r - 360 : r
}

/// Maps an angle in degrees into (-180, 180].
func normalize180(_ x: Double) -> Double {
  let r = normalize360(x)
  return r > 180 ? r - 360 : r
}
