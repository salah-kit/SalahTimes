import Foundation

/// Computes prayer times as docs/algorithm.md specifies.
enum Engine {
  static func prayerTimes(
    coordinates: Coordinates, day: GregorianDay, timeZone: TimeZone,
    parameters: CalculationParameters
  ) throws -> PrayerTimes {
    try Validation.validate(coordinates: coordinates, day: day, parameters: parameters)
    let raw = Composition(
      coordinates: coordinates, day: day, timeZone: timeZone, parameters: parameters
    ).compute()
    return finish(raw, day: day, timeZone: timeZone, parameters: parameters)
  }

  /// Applies the adjustments (section 8.8) and the rounding (section 8.9).
  static func finish(
    _ raw: Composition.Times, day: GregorianDay, timeZone: TimeZone,
    parameters: CalculationParameters
  ) -> PrayerTimes {
    let method = parameters.methodAdjustments
    let user = parameters.adjustments
    func adjust(_ event: RawEvent, _ methodMinutes: Int, _ userMinutes: Int) -> RawEvent {
      let seconds = 60 * Double(methodMinutes + userMinutes)
      return event.map { $0 + seconds }
    }
    func finish(_ event: RawEvent) -> EventTime {
      event.map { round($0, parameters.rounding) }.eventTime
    }
    return PrayerTimes(
      day: day, timeZone: timeZone,
      fajr: finish(adjust(raw.fajr, method.fajr, user.fajr)),
      sunrise: finish(adjust(raw.sunrise, method.sunrise, user.sunrise)),
      dhuhr: finish(adjust(raw.dhuhr, method.dhuhr, user.dhuhr)),
      asr: finish(adjust(raw.asr, method.asr, user.asr)),
      sunset: finish(raw.sunset),
      maghrib: finish(adjust(raw.maghrib, method.maghrib, user.maghrib)),
      isha: finish(adjust(raw.isha, method.isha, user.isha)),
      middleOfTheNight: finish(raw.middleOfTheNight),
      lastThirdOfTheNight: finish(raw.lastThirdOfTheNight))
  }

  /// Rounds POSIX seconds to a minute (section 8.9).
  static func round(_ t: Double, _ rounding: Rounding) -> Double {
    switch rounding {
    case .nearest: 60 * (t / 60 + 0.5).rounded(.down)
    case .up: 60 * (t / 60).rounded(.up)
    case .none: t
    }
  }
}

/// The composition of one civil day's events before adjustments and rounding
/// (docs/algorithm.md, sections 8.1 to 8.7 and 9).
struct Composition {
  /// The unadjusted, unrounded events of `D`.
  struct Times: Equatable {
    var fajr: RawEvent
    var sunrise: RawEvent
    var dhuhr: RawEvent
    var asr: RawEvent
    var sunset: RawEvent
    var maghrib: RawEvent
    var isha: RawEvent
    var middleOfTheNight: RawEvent
    var lastThirdOfTheNight: RawEvent
  }

  let observer: Observer
  let day: GregorianDay
  let timeZone: TimeZone
  let parameters: CalculationParameters

  init(
    coordinates: Coordinates, day: GregorianDay, timeZone: TimeZone,
    parameters: CalculationParameters
  ) {
    observer = Observer(latitude: coordinates.latitude, longitude: coordinates.longitude)
    self.day = day
    self.timeZone = timeZone
    self.parameters = parameters
  }

  func compute() -> Times {
    let previousDay = day.adding(days: -1)
    let nextDay = day.adding(days: 1)
    let transitPrevious = observer.transit(of: previousDay, in: timeZone)
    let transit = observer.transit(of: day, in: timeZone)
    let transitNext = observer.transit(of: nextDay, in: timeZone)

    let sunrise = observer.sunrise(transit: transit)
    let sunset = observer.sunset(transit: transit)
    let sunsetPrevious = observer.sunset(transit: transitPrevious)
    let sunriseNext = observer.sunrise(transit: transitNext)
    let nightBefore = Self.night(from: sunsetPrevious, to: sunrise)
    let nightAfter = Self.night(from: sunset, to: sunriseNext)

    let fajr = fajr(
      of: day, transit: transit, sunrise: sunrise, nightBefore: nightBefore)
    let maghrib = maghrib(transit: transit, sunset: sunset, nightAfter: nightAfter)
    let isha = isha(transit: transit, sunset: sunset, maghrib: maghrib, nightAfter: nightAfter)
    let asr = observer.asr(transit: transit, shadowFactor: parameters.madhab.shadowFactor)

    // Section 8.5: the night ends at D+1's Fajr (before adjustments and rounding) or sunrise.
    let nightEnd: RawEvent
    switch parameters.nightSpan {
    case .sunsetToFajr:
      nightEnd = self.fajr(
        of: nextDay, transit: transitNext, sunrise: sunriseNext, nightBefore: nightAfter)
    case .sunsetToSunrise:
      nightEnd = sunriseNext
    }
    let middle: RawEvent
    let lastThird: RawEvent
    switch (sunset, nightEnd) {
    case (.occurs(let start), .occurs(let end)):
      let length = end - start
      middle = .occurs(start + length / 2)
      lastThird = .occurs(start + 2 * length / 3)
    case (.doesNotOccur, _):
      middle = sunset
      lastThird = sunset
    case (.occurs, .doesNotOccur):
      middle = nightEnd
      lastThird = nightEnd
    }

    return Times(
      fajr: fajr, sunrise: sunrise, dhuhr: .occurs(transit), asr: asr, sunset: sunset,
      maghrib: maghrib, isha: isha, middleOfTheNight: middle, lastThirdOfTheNight: lastThird)
  }

  // MARK: Nights and bounds (section 8.1)

  /// A night from a sunset to a sunrise, as its sunset, sunrise and length in seconds, when
  /// both occur.
  struct Night: Equatable {
    var sunset: Double
    var sunrise: Double
    var length: Double { sunrise - sunset }
  }

  static func night(from sunset: RawEvent, to sunrise: RawEvent) -> Night? {
    guard let start = sunset.seconds, let end = sunrise.seconds else { return nil }
    return Night(sunset: start, sunrise: end)
  }

  /// `boundMorning(raw, p)`: no earlier than `sunrise - p × night`.
  static func boundMorning(_ raw: RawEvent, portion: Double, night: Night?) -> RawEvent {
    guard let night else { return raw }
    let bound = night.sunrise - portion * night.length
    guard let t = raw.seconds, t >= bound else { return .occurs(bound) }
    return raw
  }

  /// `boundEvening(raw, p)`: no later than `sunset + p × night`.
  static func boundEvening(_ raw: RawEvent, portion: Double, night: Night?) -> RawEvent {
    guard let night else { return raw }
    let bound = night.sunset + portion * night.length
    guard let t = raw.seconds, t <= bound else { return .occurs(bound) }
    return raw
  }

  /// The high-latitude rule's portion of the night for a twilight angle, or `nil` when the rule
  /// is `disabled`.
  func portion(angle: Double) -> Double? {
    switch parameters.highLatitudeRule {
    case .recommended: abs(observer.latitude) > 48 ? 1.0 / 7.0 : 1.0 / 2.0
    case .middleOfTheNight: 1.0 / 2.0
    case .seventhOfTheNight: 1.0 / 7.0
    case .twilightAngle: angle / 60
    case .disabled: nil
    }
  }

  func boundMorning(_ raw: RawEvent, angle: Double, night: Night?) -> RawEvent {
    guard let portion = portion(angle: angle) else { return raw }
    return Self.boundMorning(raw, portion: portion, night: night)
  }

  func boundEvening(_ raw: RawEvent, angle: Double, night: Night?) -> RawEvent {
    guard let portion = portion(angle: angle) else { return raw }
    return Self.boundEvening(raw, portion: portion, night: night)
  }

  // MARK: Fajr, Maghrib and Isha (sections 8.2 to 8.4, 8.6 and 8.7)

  /// Fajr of a day from its transit, sunrise and the night that ends at that sunrise.
  func fajr(of day: GregorianDay, transit: Double, sunrise: RawEvent, nightBefore: Night?)
    -> RawEvent
  {
    switch parameters.fajr {
    case .angle(let angle):
      let raw = observer.morningTwilight(transit: transit, angle: angle)
      return boundMorning(raw, angle: angle, night: nightBefore)
    case .moonsightingCommittee:
      let raw = observer.morningTwilight(transit: transit, angle: MoonsightingCommittee.angle)
      if abs(observer.latitude) > MoonsightingCommittee.seventhLatitude {
        return Self.boundMorning(raw, portion: 1.0 / 7.0, night: nightBefore)
      }
      guard let sunriseTime = sunrise.seconds else { return raw }
      let minutes = MoonsightingCommittee.fajrMinutes(day: day, latitude: observer.latitude)
      let bound = sunriseTime - 60 * minutes
      guard let t = raw.seconds, t >= bound else { return .occurs(bound) }
      return raw
    }
  }

  func maghrib(transit: Double, sunset: RawEvent, nightAfter: Night?) -> RawEvent {
    switch parameters.maghrib {
    case .sunset:
      return sunset
    case .angle(let angle):
      let raw = observer.eveningTwilight(transit: transit, angle: angle)
      return boundEvening(raw, angle: angle, night: nightAfter)
    }
  }

  func isha(transit: Double, sunset: RawEvent, maghrib: RawEvent, nightAfter: Night?)
    -> RawEvent
  {
    switch parameters.isha {
    case .angle(let angle):
      let raw = observer.eveningTwilight(transit: transit, angle: angle)
      return boundEvening(raw, angle: angle, night: nightAfter)
    case .minutesAfterMaghrib(let minutes):
      let interval = ishaInterval(minutes)
      return maghrib.map { $0 + 60 * Double(interval) }
    case .moonsightingCommittee(let shafaq):
      let raw = observer.eveningTwilight(transit: transit, angle: MoonsightingCommittee.angle)
      if abs(observer.latitude) > MoonsightingCommittee.seventhLatitude {
        return Self.boundEvening(raw, portion: 1.0 / 7.0, night: nightAfter)
      }
      guard let sunsetTime = sunset.seconds else { return raw }
      let minutes = MoonsightingCommittee.ishaMinutes(
        day: day, latitude: observer.latitude, shafaq: shafaq)
      let bound = sunsetTime + 60 * minutes
      guard let t = raw.seconds, t <= bound else { return .occurs(bound) }
      return raw
    }
  }

  /// The Isha interval after the Ramadan rule (section 8.7).
  func ishaInterval(_ minutes: Int) -> Int {
    guard minutes > 0, case .interval(let ramadanMinutes, let offset) = parameters.ramadanIsha,
      Ramadan.contains(day.adding(days: offset))
    else { return minutes }
    return ramadanMinutes
  }
}
