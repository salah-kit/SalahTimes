import Foundation

/// An event time inside the engine: POSIX seconds, or why the event doesn't occur.
enum RawEvent: Equatable {
  case occurs(Double)
  case doesNotOccur(NonOccurrence)

  /// The instant in POSIX seconds, or `nil`.
  var seconds: Double? {
    if case .occurs(let t) = self { t } else { nil }
  }

  /// The public form.
  var eventTime: EventTime {
    switch self {
    case .occurs(let t): .occurs(Date(timeIntervalSince1970: t))
    case .doesNotOccur(let reason): .doesNotOccur(reason)
    }
  }

  /// Applies `transform` to an instant and keeps a non-occurrence as it is.
  func map(_ transform: (Double) -> Double) -> RawEvent {
    switch self {
    case .occurs(let t): .occurs(transform(t))
    case .doesNotOccur: self
    }
  }
}

/// The observer's place with its latitude's sine and cosine precomputed (sections 4 to 7).
struct Observer {
  var latitude: Double
  var longitude: Double
  var sinLatitude: Double
  var cosLatitude: Double

  init(latitude: Double, longitude: Double) {
    self.latitude = latitude
    self.longitude = longitude
    sinLatitude = sin(radians(latitude))
    cosLatitude = cos(radians(latitude))
  }

  /// The most iterations a convergence loop makes (sections 5 and 6).
  static let maximumIterations = 20

  /// The step below which a loop stops, in seconds (1 ms).
  static let convergence: Double = 0.001

  /// The local hour angle at an instant, in degrees in (-180, 180].
  func hourAngle(at t: Double) -> Double {
    Astronomy.sun(at: t).hourAngle(longitude: longitude)
  }

  /// The Sun's geometric altitude at an instant, in degrees.
  func altitude(at t: Double) -> Double {
    let sun = Astronomy.sun(at: t)
    let delta = radians(sun.declination)
    let h = radians(sun.hourAngle(longitude: longitude))
    return degrees(asin(sinLatitude * sin(delta) + cosLatitude * cos(delta) * cos(h)))
  }

  /// Local noon of a civil day in a time zone (section 5, step 1), in POSIX seconds.
  static func localNoon(of day: GregorianDay, in timeZone: TimeZone) -> Double {
    let u = Double(day.daysSince1970) * Astronomy.secondsPerDay + 43_200
    let o1 = timeZone.secondsFromGMT(for: Date(timeIntervalSince1970: u))
    let o2 = timeZone.secondsFromGMT(for: Date(timeIntervalSince1970: u - Double(o1)))
    return u - Double(o2)
  }

  /// The solar transit nearest an instant (section 5, step 2).
  ///
  /// Spec note: section 5 says the instants don't depend on whether the zone observes DST. They
  /// agree to the loop's 1 ms tolerance, not bit for bit: a local noon an hour away starts the
  /// iteration elsewhere, and the converged transits differ by well under a millisecond. Times
  /// rounded to the minute are equal unless one lies within that distance of a half minute.
  func transit(near start: Double) -> Double {
    var t = start
    for _ in 0..<Self.maximumIterations {
      let step = -hourAngle(at: t) / 360 * Astronomy.secondsPerDay
      t += step
      if abs(step) < Self.convergence { break }
    }
    return t
  }

  /// The transit that belongs to a civil day in a time zone (section 5).
  func transit(of day: GregorianDay, in timeZone: TimeZone) -> Double {
    transit(near: Self.localNoon(of: day, in: timeZone))
  }

  /// When the Sun reaches `altitude` before (`side == -1`) or after (`side == +1`) the transit
  /// `transit` (section 6).
  func crossing(transit: Double, altitude: Double, side: Double) -> RawEvent {
    let sinAltitude = sin(radians(altitude))
    func cosine(_ sun: SunState) -> Double {
      let delta = radians(sun.declination)
      return (sinAltitude - sinLatitude * sin(delta)) / (cosLatitude * cos(delta))
    }
    // The Sun is highest at the transit and lowest at the antitransit on this side, so the
    // event's existence is decided there.
    let sunAtTransit = Astronomy.sun(at: transit)
    let atTransit = cosine(sunAtTransit)
    if atTransit > 1 { return .doesNotOccur(.sunStaysBelow) }
    let antitransit = transit + side * Astronomy.secondsPerDay / 2
    let sunAtAntitransit = Astronomy.sun(at: antitransit)
    if cosine(sunAtAntitransit) < -1 { return .doesNotOccur(.sunStaysAbove) }

    // Start from the first estimate: the hour angle the transit's declination gives, which is the
    // antitransit when the Sun stays above the altitude there. From the transit, a first step of
    // nearly 180° could wrap around to the wrong side.
    var t = antitransit
    var sun = sunAtAntitransit
    if atTransit > -1 {
      t = transit + side * degrees(acos(atTransit)) / 360 * Astronomy.secondsPerDay
      sun = Astronomy.sun(at: t)
    }
    for _ in 0..<Self.maximumIterations {
      let h0 = degrees(acos(min(1, max(-1, cosine(sun)))))
      let step =
        normalize180(side * h0 - sun.hourAngle(longitude: longitude)) / 360
        * Astronomy.secondsPerDay
      t += step
      if abs(step) < Self.convergence { break }
      sun = Astronomy.sun(at: t)
    }
    return .occurs(t)
  }

  /// The altitude of the Sun's upper limb at sunrise and sunset: 34' of refraction and a 16'
  /// semidiameter (section 7).
  static let horizonAltitude: Double = -50.0 / 60.0

  /// Sunrise before a transit.
  func sunrise(transit: Double) -> RawEvent {
    crossing(transit: transit, altitude: Self.horizonAltitude, side: -1)
  }

  /// Sunset after a transit.
  func sunset(transit: Double) -> RawEvent {
    crossing(transit: transit, altitude: Self.horizonAltitude, side: 1)
  }

  /// When the Sun is `angle` degrees below the horizon before sunrise.
  func morningTwilight(transit: Double, angle: Double) -> RawEvent {
    crossing(transit: transit, altitude: -angle, side: -1)
  }

  /// When the Sun is `angle` degrees below the horizon after sunset.
  func eveningTwilight(transit: Double, angle: Double) -> RawEvent {
    crossing(transit: transit, altitude: -angle, side: 1)
  }

  /// Asr for a shadow factor (section 7).
  func asr(transit: Double, shadowFactor k: Double) -> RawEvent {
    let declination = Astronomy.sun(at: transit).declination
    let z = abs(latitude - declination)
    if z >= 90 { return .doesNotOccur(.sunStaysBelow) }
    let altitude = degrees(atan(1 / (k + tan(radians(z)))))
    return crossing(transit: transit, altitude: altitude, side: 1)
  }
}
