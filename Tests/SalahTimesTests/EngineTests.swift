import Foundation
import Testing

@testable import SalahTimes

/// The composition of prayer times (docs/algorithm.md, sections 2, 5 and 8 to 9).
@Suite("Engine")
struct EngineTests {
  // MARK: Helpers

  private static func zone(_ identifier: String) throws -> TimeZone {
    try #require(TimeZone(identifier: identifier))
  }

  private static func day(_ text: String) throws -> GregorianDay {
    try #require(GregorianDay(text))
  }

  private static func times(
    _ latitude: Double, _ longitude: Double, _ zoneIdentifier: String, _ dayText: String,
    _ parameters: CalculationParameters
  ) throws -> PrayerTimes {
    try PrayerTimes(
      coordinates: Coordinates(latitude: latitude, longitude: longitude),
      day: try day(dayText), timeZone: try zone(zoneIdentifier), parameters: parameters)
  }

  /// POSIX seconds of an event that must occur.
  private static func seconds(_ event: EventTime) throws -> Double {
    try #require(event.date).timeIntervalSince1970
  }

  /// POSIX seconds of a local wall-clock time on a day, at a fixed UTC offset in hours.
  private static func local(
    _ dayText: String, _ hour: Int, _ minute: Int, _ second: Int = 0, offsetHours: Double
  ) throws -> Double {
    Double(try day(dayText).daysSince1970) * 86_400 + Double(hour * 3600 + minute * 60 + second)
      - offsetHours * 3600
  }

  /// Muslim World League without rounding, so tests see exact instants.
  private static var unrounded: CalculationParameters {
    var parameters = CalculationMethod.muslimWorldLeague.parameters
    parameters.rounding = .none
    return parameters
  }

  // MARK: Events against an external authority

  /// Sunrise, solar noon and sunset from NOAA's Solar Calculator
  /// (https://gml.noaa.gov/grad/solcalc/, its calculation functions in main.js evaluated for
  /// these inputs on 2026-10-13). The USNO API (aa.usno.navy.mil/api/rstt) refused connections
  /// that day. NOAA uses no ΔT and its own equation-of-time iteration, so it's an independent
  /// implementation of the same Meeus series; agreement within a minute is expected.
  private struct Reference {
    var place: String
    var latitude: Double
    var longitude: Double
    var offsetHours: Double
    var day: String
    var sunrise: (Int, Int, Int)
    var noon: (Int, Int, Int)
    var sunset: (Int, Int, Int)
  }

  private static let noaa: [Reference] = [
    Reference(
      place: "Makkah", latitude: 21.4225, longitude: 39.8262, offsetHours: 3, day: "2026-03-20",
      sunrise: (6, 24, 57), noon: (12, 28, 18), sunset: (18, 31, 41)),
    Reference(
      place: "Makkah", latitude: 21.4225, longitude: 39.8262, offsetHours: 3, day: "2026-06-21",
      sunrise: (5, 39, 18), noon: (12, 22, 23), sunset: (19, 5, 42)),
    Reference(
      place: "London", latitude: 51.5074, longitude: -0.1278, offsetHours: 1, day: "2026-07-01",
      sunrise: (4, 47, 35), noon: (13, 4, 19), sunset: (21, 20, 54)),
    Reference(
      place: "New York", latitude: 40.7128, longitude: -74.0060, offsetHours: -5,
      day: "2026-12-21", sunrise: (7, 16, 35), noon: (11, 53, 57), sunset: (16, 31, 49)),
    Reference(
      place: "Cape Town", latitude: -33.9249, longitude: 18.4241, offsetHours: 2,
      day: "2026-06-21", sunrise: (7, 51, 19), noon: (12, 48, 0), sunset: (17, 44, 55)),
    Reference(
      place: "Ushuaia", latitude: -54.8019, longitude: -68.3030, offsetHours: -3,
      day: "2026-12-21", sunrise: (4, 51, 25), noon: (13, 31, 8), sunset: (22, 11, 21)),
    Reference(
      place: "Singapore", latitude: 1.3521, longitude: 103.8198, offsetHours: 8,
      day: "2026-09-23", sunrise: (6, 53, 58), noon: (12, 57, 23), sunset: (19, 0, 26)),
    Reference(
      place: "Quito", latitude: -0.1807, longitude: -78.4678, offsetHours: -5, day: "2026-03-20",
      sunrise: (6, 17, 59), noon: (12, 21, 23), sunset: (18, 24, 30)),
  ]

  @Test("Sunrise, transit and sunset agree with NOAA within a minute")
  func eventsAgreeWithNOAA() throws {
    for reference in Self.noaa {
      let zone = try #require(TimeZone(secondsFromGMT: Int(reference.offsetHours * 3600)))
      let times = try PrayerTimes(
        coordinates: Coordinates(latitude: reference.latitude, longitude: reference.longitude),
        day: try Self.day(reference.day), timeZone: zone, parameters: Self.unrounded)
      let pairs: [(EventTime, (Int, Int, Int))] = [
        (times.sunrise, reference.sunrise), (times.dhuhr, reference.noon),
        (times.sunset, reference.sunset),
      ]
      for (event, (hour, minute, second)) in pairs {
        let expected = try Self.local(
          reference.day, hour, minute, second, offsetHours: reference.offsetHours)
        let difference = try Self.seconds(event) - expected
        #expect(abs(difference) < 60, "\(reference.place) \(reference.day): off by \(difference) s")
      }
    }
  }

  // MARK: High-latitude rules (sections 8.1 to 8.4)

  @Test(
    "Angle Fajr and Isha are bounded by each rule's portion of their own night",
    arguments: [
      HighLatitudeRule.middleOfTheNight, .seventhOfTheNight, .twilightAngle, .recommended,
    ])
  func highLatitudeBounds(rule: HighLatitudeRule) throws {
    // Oslo at the solstice: the Sun stays above -7°, so 18° Fajr and 17° Isha never happen.
    var parameters = Self.unrounded
    parameters.highLatitudeRule = rule
    let today = try Self.times(59.91, 10.75, "Europe/Oslo", "2026-06-21", parameters)
    let yesterday = try Self.times(59.91, 10.75, "Europe/Oslo", "2026-06-20", parameters)
    let tomorrow = try Self.times(59.91, 10.75, "Europe/Oslo", "2026-06-22", parameters)
    let sunrise = try Self.seconds(today.sunrise)
    let sunset = try Self.seconds(today.sunset)
    let nightBefore = sunrise - (try Self.seconds(yesterday.sunset))
    let nightAfter = try Self.seconds(tomorrow.sunrise) - sunset

    let (fajrPortion, ishaPortion): (Double, Double) =
      switch rule {
      case .middleOfTheNight: (1 / 2, 1 / 2)
      case .seventhOfTheNight, .recommended: (1 / 7, 1 / 7)
      case .twilightAngle: (18.0 / 60, 17.0 / 60)
      case .disabled: (0, 0)
      }
    #expect(abs(try Self.seconds(today.fajr) - (sunrise - fajrPortion * nightBefore)) < 1e-3)
    #expect(abs(try Self.seconds(today.isha) - (sunset + ishaPortion * nightAfter)) < 1e-3)
  }

  @Test("A disabled rule reports the white night's missing Fajr and Isha")
  func disabledRule() throws {
    var parameters = Self.unrounded
    parameters.highLatitudeRule = .disabled
    let oslo = try Self.times(59.91, 10.75, "Europe/Oslo", "2026-06-21", parameters)
    #expect(oslo.fajr == .doesNotOccur(.sunStaysAbove))
    #expect(oslo.isha == .doesNotOccur(.sunStaysAbove))
    #expect(oslo.sunset.date != nil)
    // The night ends at tomorrow's Fajr, which doesn't occur: its reason carries over.
    #expect(oslo.middleOfTheNight == .doesNotOccur(.sunStaysAbove))
    #expect(oslo.lastThirdOfTheNight == .doesNotOccur(.sunStaysAbove))
    parameters.nightSpan = .sunsetToSunrise
    let bySunrise = try Self.times(59.91, 10.75, "Europe/Oslo", "2026-06-21", parameters)
    #expect(bySunrise.middleOfTheNight.date != nil)
  }

  @Test("A bound replaces a time beyond it and leaves a time within it")
  func boundOnlyWhenBeyond() throws {
    // London in mid-April: 18° Isha exists, about two hours after sunset.
    var parameters = Self.unrounded
    parameters.isha = .angle(18)
    parameters.highLatitudeRule = .disabled
    let raw = try Self.seconds(
      try Self.times(51.5074, -0.1278, "Europe/London", "2026-04-15", parameters).isha)

    parameters.highLatitudeRule = .middleOfTheNight
    let middle = try Self.times(51.5074, -0.1278, "Europe/London", "2026-04-15", parameters)
    #expect(try Self.seconds(middle.isha) == raw)

    parameters.highLatitudeRule = .recommended  // seventhOfTheNight beyond 48°
    let seventh = try Self.times(51.5074, -0.1278, "Europe/London", "2026-04-15", parameters)
    let tomorrow = try Self.times(51.5074, -0.1278, "Europe/London", "2026-04-16", parameters)
    let sunset = try Self.seconds(seventh.sunset)
    let bound = sunset + (try Self.seconds(tomorrow.sunrise) - sunset) / 7
    #expect(bound < raw)
    #expect(abs(try Self.seconds(seventh.isha) - bound) < 1e-3)
  }

  @Test("Maghrib by angle, as in the Tehran method")
  func tehranMaghrib() throws {
    var parameters = CalculationMethod.tehran.parameters
    parameters.rounding = .none
    let tehran = try Self.times(35.6892, 51.389, "Asia/Tehran", "2026-06-21", parameters)
    let observer = Observer(latitude: 35.6892, longitude: 51.389)
    let transit = try Self.seconds(tehran.dhuhr)
    let expected = try #require(observer.eveningTwilight(transit: transit, angle: 4.5).seconds)
    #expect(try Self.seconds(tehran.maghrib) == expected)
    let afterSunset = expected - (try Self.seconds(tehran.sunset))
    #expect(afterSunset > 15 * 60 && afterSunset < 25 * 60)
    #expect(try Self.seconds(tehran.isha) > expected)

    // Where the Sun never sinks that far, the high-latitude rule bounds Maghrib too.
    parameters.maghrib = .angle(10)
    let oslo = try Self.times(59.91, 10.75, "Europe/Oslo", "2026-06-21", parameters)
    let tomorrow = try Self.times(59.91, 10.75, "Europe/Oslo", "2026-06-22", parameters)
    let sunset = try Self.seconds(oslo.sunset)
    let night = try Self.seconds(tomorrow.sunrise) - sunset
    #expect(abs(try Self.seconds(oslo.maghrib) - (sunset + night / 7)) < 1e-3)
  }

  // MARK: Interval Isha and the Ramadan rule (sections 8.4 and 8.7)

  private static func ummAlQura(_ ramadan: RamadanIshaRule) -> CalculationParameters {
    var parameters = CalculationMethod.ummAlQura.parameters
    parameters.rounding = .none
    parameters.ramadanIsha = ramadan
    return parameters
  }

  private static func ishaInterval(_ dayText: String, _ parameters: CalculationParameters)
    throws -> Double
  {
    let times = try Self.times(21.4225, 39.8262, "Asia/Riyadh", dayText, parameters)
    return (try Self.seconds(times.isha) - Self.seconds(times.maghrib)) / 60
  }

  @Test("Interval Isha follows Maghrib, and the Ramadan rule replaces it in Ramadan")
  func intervalAndRamadan() throws {
    // Umm al-Qura Ramadan 1447 runs from 2026-02-18 to 2026-03-19.
    let ramadan = Self.ummAlQura(.interval(minutes: 120, hijriDayOffset: 0))
    #expect(try Self.ishaInterval("2026-03-01", Self.ummAlQura(.off)) == 90)
    #expect(try Self.ishaInterval("2026-03-01", ramadan) == 120)
    #expect(try Self.ishaInterval("2026-04-01", ramadan) == 90)
    #expect(try Self.ishaInterval("2026-02-17", ramadan) == 90)
    #expect(try Self.ishaInterval("2026-02-18", ramadan) == 120)
    #expect(try Self.ishaInterval("2026-03-19", ramadan) == 120)
    #expect(try Self.ishaInterval("2026-03-20", ramadan) == 90)

    // An offset of 1 starts and ends the month a day earlier.
    let early = Self.ummAlQura(.interval(minutes: 120, hijriDayOffset: 1))
    #expect(try Self.ishaInterval("2026-02-17", early) == 120)
    #expect(try Self.ishaInterval("2026-03-19", early) == 90)
    let late = Self.ummAlQura(.interval(minutes: 120, hijriDayOffset: -1))
    #expect(try Self.ishaInterval("2026-02-18", late) == 90)
    #expect(try Self.ishaInterval("2026-03-20", late) == 120)

    // A zero interval and angle-based Isha are left alone.
    var zero = ramadan
    zero.isha = .minutesAfterMaghrib(0)
    #expect(try Self.ishaInterval("2026-03-01", zero) == 0)
    var angle = ramadan
    angle.isha = .angle(17)
    var angleOff = angle
    angleOff.ramadanIsha = .off
    let withRule = try Self.times(21.4225, 39.8262, "Asia/Riyadh", "2026-03-01", angle)
    let withoutRule = try Self.times(21.4225, 39.8262, "Asia/Riyadh", "2026-03-01", angleOff)
    #expect(withRule.isha == withoutRule.isha)
  }

  @Test("Interval Isha counts from the unadjusted Maghrib and takes its reason")
  func intervalUsesUnadjustedMaghrib() throws {
    var parameters = Self.ummAlQura(.off)
    let plain = try Self.times(21.4225, 39.8262, "Asia/Riyadh", "2026-05-01", parameters)
    parameters.adjustments.maghrib = 5
    let adjusted = try Self.times(21.4225, 39.8262, "Asia/Riyadh", "2026-05-01", parameters)
    #expect(adjusted.isha == plain.isha)
    #expect(try Self.seconds(adjusted.maghrib) == Self.seconds(plain.maghrib) + 300)

    let polarDay = try Self.times(69.65, 18.96, "Europe/Oslo", "2026-06-21", parameters)
    #expect(polarDay.isha == .doesNotOccur(.sunStaysAbove))
    let polarNight = try Self.times(69.65, 18.96, "Europe/Oslo", "2026-12-21", parameters)
    #expect(polarNight.isha == .doesNotOccur(.sunStaysBelow))
  }

  // MARK: Neighboring solar days (section 5)

  @Test("A zone that skips a calendar day keeps the nights around it")
  func skippedCalendarDay() throws {
    // Pacific/Apia skipped 2011-12-30 when it moved to the other side of the date line.
    func times(_ text: String) throws -> PrayerTimes {
      try Self.times(-13.8333, -171.75, "Pacific/Apia", text, Self.unrounded)
    }
    for text in ["2011-12-29", "2011-12-31", "2012-01-01"] {
      let day = try times(text)
      let instants = try [
        day.fajr, day.sunrise, day.dhuhr, day.asr, day.sunset, day.isha, day.middleOfTheNight,
        day.lastThirdOfTheNight,
      ].map(Self.seconds)
      #expect(instants == instants.sorted(), "\(text)'s events are out of order")
    }
    // The skipped day gets the next day's events.
    let skipped = try times("2011-12-30")
    let next = try times("2011-12-31")
    for event in PrayerTimes.Event.allCases {
      #expect(skipped[event] == next[event], "\(event)")
    }
  }

  // MARK: Existence at the edges of a season (section 6)

  @Test("A season's first night exists for the evening before and the morning after")
  func existenceAtSeasonEdges() throws {
    // Longyearbyen's midnight sun ends on the night of 24 to 25 August 2026. The Sun sets about
    // 12 hours after the 24th's transit, when the declination has moved on.
    func longyearbyen(_ text: String) throws -> PrayerTimes {
      try Self.times(78.22, 15.65, "Arctic/Longyearbyen", text, Self.unrounded)
    }
    let night = (evening: try longyearbyen("2026-08-24"), morning: try longyearbyen("2026-08-25"))
    #expect(try Self.seconds(night.evening.sunset) < Self.seconds(night.morning.sunrise))
    #expect(try longyearbyen("2026-08-23").sunset == .doesNotOccur(.sunStaysAbove))
    #expect(night.evening.sunrise == .doesNotOccur(.sunStaysAbove))

    // At 60° N the Sun first reaches 18° below the horizon again on the night of 21 to 22
    // August 2026, dipping to about 18.16°.
    let parameters = CalculationParameters(
      fajr: .angle(18), isha: .angle(18), highLatitudeRule: .disabled, rounding: .none)
    func sixty(_ text: String) throws -> PrayerTimes {
      try Self.times(60, 0, "UTC", text, parameters)
    }
    let isha = try Self.seconds(sixty("2026-08-21").isha)
    let fajr = try Self.seconds(sixty("2026-08-22").fajr)
    #expect(isha < fajr)
    let observer = Observer(latitude: 60, longitude: 0)
    #expect(abs(observer.altitude(at: isha) + 18) < 0.01)
    #expect(abs(observer.altitude(at: fajr) + 18) < 0.01)
    // A night earlier the Sun stays above 18° below the horizon.
    #expect(try sixty("2026-08-20").isha == .doesNotOccur(.sunStaysAbove))
    #expect(try sixty("2026-08-21").fajr == .doesNotOccur(.sunStaysAbove))
  }

  // MARK: Moonsighting Committee (sections 8.2, 8.4 and 8.6)

  @Test("Moonsighting Committee at London matches the committee's timetable")
  func moonsightingLondon() throws {
    // The committee's London timetable for 2016-01-01 (Hanafi Asr): Fajr 06:25, Dhuhr 12:09,
    // Asr 14:15, Maghrib 16:05, Isha 17:38, GMT.
    var parameters = CalculationMethod.moonsightingCommittee.parameters
    parameters.madhab = .hanafi
    let london = try Self.times(51.5074, -0.1278, "Europe/London", "2016-01-01", parameters)
    let expected: [(EventTime, Int, Int)] = [
      (london.fajr, 6, 25), (london.dhuhr, 12, 9), (london.asr, 14, 15),
      (london.maghrib, 16, 5), (london.isha, 17, 38),
    ]
    for (event, hour, minute) in expected {
      let published = try Self.local("2016-01-01", hour, minute, offsetHours: 0)
      #expect(abs(try Self.seconds(event) - published) <= 60)
    }
  }

  @Test(
    "Moonsighting Committee Isha uses each shafaq's seasonal minutes",
    arguments: [Shafaq.general, .ahmer, .abyad])
  func moonsightingShafaq(shafaq: Shafaq) throws {
    var parameters = CalculationParameters(
      fajr: .moonsightingCommittee, isha: .moonsightingCommittee(shafaq), rounding: .none)
    let london = try Self.times(51.5074, -0.1278, "Europe/London", "2016-01-01", parameters)
    // 2016-01-01 is 11 days after the winter solstice (s = 1 + 10), in the first segment.
    let x = 51.5074 / 55
    let (a, b): (Double, Double) =
      switch shafaq {
      case .general: (75 + 25.60 * x, 75 + 2.050 * x)
      case .ahmer: (62 + 17.40 * x, 62 - 7.16 * x)
      case .abyad: (75 + 25.60 * x, 75 + 7.16 * x)
      }
    let minutes = a + (b - a) / 91 * 11
    let sunset = try Self.seconds(london.sunset)
    #expect(abs(try Self.seconds(london.isha) - (sunset + 60 * minutes)) < 1e-3)
    let fajrMinutes = (75 + 28.65 * x) + ((75 + 19.44 * x) - (75 + 28.65 * x)) / 91 * 11
    #expect(
      abs(try Self.seconds(london.fajr) - (Self.seconds(london.sunrise) - 60 * fajrMinutes)) < 1e-3)

    // On the equator at the equinox, 18° twilight lasts about 69 minutes. That's within
    // 75 minutes, so the raw times stand, except the red twilight's 62 minutes, which bound Isha.
    parameters.highLatitudeRule = .disabled
    let equator = try Self.times(0, 103.8, "Asia/Singapore", "2026-03-20", parameters)
    var angles = parameters
    angles.fajr = .angle(18)
    angles.isha = .angle(18)
    let raw = try Self.times(0, 103.8, "Asia/Singapore", "2026-03-20", angles)
    #expect(equator.fajr == raw.fajr)
    if shafaq == .ahmer {
      let bound = try Self.seconds(equator.sunset) + 62 * 60
      #expect(bound < (try Self.seconds(raw.isha)))
      #expect(abs(try Self.seconds(equator.isha) - bound) < 1e-3)
    } else {
      #expect(equator.isha == raw.isha)
    }
  }

  @Test("From 55°, the Moonsighting Committee adds the night's seventh to its seasonal bounds")
  func moonsightingSeventh() throws {
    let parameters = CalculationParameters(
      fajr: .moonsightingCommittee, isha: .moonsightingCommittee(.general), rounding: .none)
    // Aberdeen at the summer solstice: no 18° twilight, and the seventh is tighter than the
    // seasonal values, so it decides.
    let june = try Self.times(57.15, -2.09, "Europe/London", "2026-06-21", parameters)
    let before = try Self.times(57.15, -2.09, "Europe/London", "2026-06-20", parameters)
    let after = try Self.times(57.15, -2.09, "Europe/London", "2026-06-22", parameters)
    let sunrise = try Self.seconds(june.sunrise)
    let sunset = try Self.seconds(june.sunset)
    let nightBefore = sunrise - (try Self.seconds(before.sunset))
    let nightAfter = try Self.seconds(after.sunrise) - sunset
    #expect(abs(try Self.seconds(june.fajr) - (sunrise - nightBefore / 7)) < 1e-3)
    #expect(abs(try Self.seconds(june.isha) - (sunset + nightAfter / 7)) < 1e-3)

    // In December the seasonal values are tighter than both the 18° times and the seventh, so
    // they decide, as they do below 55°: Fajr about 105 minutes before sunrise rather than the
    // 18° time, about 148 minutes before it.
    let december = try Self.times(57.15, -2.09, "Europe/London", "2026-12-21", parameters)
    let day = try Self.day("2026-12-21")
    let fajrMinutes = MoonsightingCommittee.fajrMinutes(day: day, latitude: 57.15)
    let ishaMinutes = MoonsightingCommittee.ishaMinutes(
      day: day, latitude: 57.15, shafaq: .general)
    let decemberSunrise = try Self.seconds(december.sunrise)
    let decemberSunset = try Self.seconds(december.sunset)
    #expect(abs(try Self.seconds(december.fajr) - (decemberSunrise - 60 * fajrMinutes)) < 1e-3)
    #expect(abs(try Self.seconds(december.isha) - (decemberSunset + 60 * ishaMinutes)) < 1e-3)
    var angles = parameters
    angles.fajr = .angle(18)
    angles.isha = .angle(18)
    angles.highLatitudeRule = .disabled
    let raw = try Self.times(57.15, -2.09, "Europe/London", "2026-12-21", angles)
    #expect(try Self.seconds(raw.fajr) < Self.seconds(december.fajr) - 30 * 60)
    #expect(try Self.seconds(raw.isha) > Self.seconds(december.isha) + 30 * 60)
  }

  @Test(
    "The committee's seventh starts at exactly 55°, north and south",
    arguments: [
      (55.0, -1.6, "Europe/London", "2026-06-21"),
      (-55.0, -68.3, "America/Argentina/Ushuaia", "2026-12-21"),
    ])
  func moonsightingSeventhBoundary(
    latitude: Double, longitude: Double, zone: String, dayText: String
  ) throws {
    let parameters = CalculationParameters(
      fajr: .moonsightingCommittee, isha: .moonsightingCommittee(.general), rounding: .none)
    let day = try Self.day(dayText)
    func times(_ latitude: Double, _ offset: Int) throws -> PrayerTimes {
      try PrayerTimes(
        coordinates: Coordinates(latitude: latitude, longitude: longitude),
        day: day.adding(days: offset), timeZone: try Self.zone(zone), parameters: parameters)
    }
    // At the summer solstice at 55° there's no 18° twilight. The seventh of the night, about
    // 57 minutes, is tighter than the seasonal values, about 123 and 81 minutes, so it decides
    // at 55° exactly.
    let edge = try times(latitude, 0)
    let sunrise = try Self.seconds(edge.sunrise)
    let sunset = try Self.seconds(edge.sunset)
    let nightBefore = sunrise - (try Self.seconds(times(latitude, -1).sunset))
    let nightAfter = try Self.seconds(times(latitude, 1).sunrise) - sunset
    #expect(abs(try Self.seconds(edge.fajr) - (sunrise - nightBefore / 7)) < 1e-3)
    #expect(abs(try Self.seconds(edge.isha) - (sunset + nightAfter / 7)) < 1e-3)

    // A hundredth of a degree closer to the equator, only the seasonal values bound.
    let inside = latitude - (latitude > 0 ? 0.01 : -0.01)
    let below = try times(inside, 0)
    let fajrMinutes = MoonsightingCommittee.fajrMinutes(day: day, latitude: inside)
    let ishaMinutes = MoonsightingCommittee.ishaMinutes(
      day: day, latitude: inside, shafaq: .general)
    #expect(fajrMinutes > 120 && ishaMinutes > 80)
    let belowSunrise = try Self.seconds(below.sunrise)
    let belowSunset = try Self.seconds(below.sunset)
    #expect(abs(try Self.seconds(below.fajr) - (belowSunrise - 60 * fajrMinutes)) < 1e-3)
    #expect(abs(try Self.seconds(below.isha) - (belowSunset + 60 * ishaMinutes)) < 1e-3)
  }

  @Test("The committee's seasonal values follow section 8.6")
  func seasonalValues() throws {
    // At 55°, A / 55 = 1, so the coefficients are the table's sums.
    let s = { (dayText: String, latitude: Double) throws -> Int in
      MoonsightingCommittee.daysSinceWinterSolstice(of: try Self.day(dayText), latitude: latitude)
    }
    #expect(try s("2026-01-01", 55) == 11)
    #expect(try s("2026-12-21", 55) == 0)
    #expect(try s("2024-12-21", 55) == 0)
    #expect(try s("2024-12-22", 55) == 1)
    #expect(try s("2026-06-21", -33) == 0)
    #expect(try s("2024-06-21", -33) == 0)
    #expect(try s("2026-06-20", -33) == 364)

    let (a, b, c, d) = (103.65, 94.44, 107.74, 123.10)
    let expected: [(Int, Double)] = [
      (0, a), (45, a + (b - a) / 91 * 45), (91, b), (114, b + (c - b) / 46 * 23), (137, c),
      (160, c + (d - c) / 46 * 23), (183, d), (206, d + (c - d) / 46 * 23), (229, c),
      (252, c + (b - c) / 46 * 23), (275, b), (320, b + (a - b) / 91 * 45),
    ]
    for (days, minutes) in expected {
      let value = MoonsightingCommittee.interpolate(days, a: a, b: b, c: c, d: d)
      #expect(abs(value - minutes) < 1e-9)
    }
    let june = try Self.day("2026-06-21")  // s = 172 + 10 = 182
    #expect(
      abs(MoonsightingCommittee.fajrMinutes(day: june, latitude: 55) - (c + (d - c) / 46 * 45))
        < 1e-9)
    #expect(
      abs(
        MoonsightingCommittee.ishaMinutes(day: june, latitude: -55, shafaq: .general)
          - (75 + 25.60)) < 1e-9)
  }

  // MARK: Adjustments and rounding (sections 8.8 and 8.9)

  @Test("Adjustments move the six prayer events and nothing else")
  func adjustments() throws {
    var parameters = Self.unrounded
    let plain = try Self.times(21.4225, 39.8262, "Asia/Riyadh", "2026-05-01", parameters)
    parameters.methodAdjustments = PrayerAdjustments(
      fajr: 1, sunrise: -2, dhuhr: 3, asr: 4, maghrib: 5, isha: 6)
    parameters.adjustments = PrayerAdjustments(
      fajr: 10, sunrise: 20, dhuhr: -30, asr: 0, maghrib: -1, isha: 1440)
    let adjusted = try Self.times(21.4225, 39.8262, "Asia/Riyadh", "2026-05-01", parameters)
    let moves: [(PrayerTimes.Event, Double)] = [
      (.fajr, 11), (.sunrise, 18), (.dhuhr, -27), (.asr, 4), (.sunset, 0), (.maghrib, 4),
      (.isha, 1446), (.middleOfTheNight, 0), (.lastThirdOfTheNight, 0),
    ]
    for (event, minutes) in moves {
      let shift = try Self.seconds(adjusted[event]) - Self.seconds(plain[event])
      #expect(abs(shift - 60 * minutes) < 1e-6, "\(event)")
    }
  }

  @Test("Rounding to the nearest minute, up, or not at all")
  func rounding() throws {
    #expect(Engine.round(90, .nearest) == 120)
    #expect(Engine.round(89.999, .nearest) == 60)
    #expect(Engine.round(-30, .nearest) == 0)
    #expect(Engine.round(-30.001, .nearest) == -60)
    #expect(Engine.round(60, .up) == 60)
    #expect(Engine.round(60.001, .up) == 120)
    #expect(Engine.round(61.5, .none) == 61.5)

    let exact = try Self.times(21.4225, 39.8262, "Asia/Riyadh", "2026-05-01", Self.unrounded)
    for rounding in [Rounding.nearest, .up] {
      var parameters = Self.unrounded
      parameters.rounding = rounding
      let rounded = try Self.times(21.4225, 39.8262, "Asia/Riyadh", "2026-05-01", parameters)
      for event in PrayerTimes.Event.allCases {
        let value = try Self.seconds(rounded[event])
        #expect(value == Engine.round(try Self.seconds(exact[event]), rounding))
        #expect(value.truncatingRemainder(dividingBy: 60) == 0)
      }
    }
  }

  // MARK: The night (section 8.5)

  @Test("The night's divisions span sunset to the next Fajr or sunrise")
  func nightDivisions() throws {
    var parameters = Self.unrounded
    let today = try Self.times(21.4225, 39.8262, "Asia/Riyadh", "2026-05-01", parameters)
    let tomorrow = try Self.times(21.4225, 39.8262, "Asia/Riyadh", "2026-05-02", parameters)
    let sunset = try Self.seconds(today.sunset)
    var night = try Self.seconds(tomorrow.fajr) - sunset
    #expect(abs(try Self.seconds(today.middleOfTheNight) - (sunset + night / 2)) < 1e-3)
    #expect(abs(try Self.seconds(today.lastThirdOfTheNight) - (sunset + 2 * night / 3)) < 1e-3)

    // Adjusting Fajr doesn't move the night's end.
    parameters.adjustments.fajr = 10
    let adjusted = try Self.times(21.4225, 39.8262, "Asia/Riyadh", "2026-05-01", parameters)
    #expect(adjusted.middleOfTheNight == today.middleOfTheNight)

    parameters.nightSpan = .sunsetToSunrise
    parameters.adjustments.sunrise = 10
    let bySunrise = try Self.times(21.4225, 39.8262, "Asia/Riyadh", "2026-05-01", parameters)
    night = try Self.seconds(tomorrow.sunrise) - sunset
    #expect(abs(try Self.seconds(bySunrise.middleOfTheNight) - (sunset + night / 2)) < 1e-3)
    #expect(
      abs(try Self.seconds(bySunrise.lastThirdOfTheNight) - (sunset + 2 * night / 3)) < 1e-3)
  }

  // MARK: Validation (section 2)

  private static func error(
    _ coordinates: Coordinates = Coordinates(latitude: 21.4, longitude: 39.8),
    day: GregorianDay? = GregorianDay(year: 2026, month: 5, day: 1),
    change: (inout CalculationParameters) -> Void = { _ in }
  ) throws -> CalculationError? {
    var parameters = CalculationMethod.muslimWorldLeague.parameters
    change(&parameters)
    do {
      _ = try PrayerTimes(
        coordinates: coordinates, day: try #require(day), timeZone: try zone("UTC"),
        parameters: parameters)
      return nil
    } catch let error as CalculationError {
      return error
    }
  }

  private static func isInvalidParameters(_ error: CalculationError?) -> Bool {
    if case .invalidParameters = error { true } else { false }
  }

  @Test("Invalid coordinates and unsupported dates throw")
  func coordinateAndDateErrors() throws {
    for coordinates in [
      Coordinates(latitude: 90.0001, longitude: 0), Coordinates(latitude: -91, longitude: 0),
      Coordinates(latitude: 0, longitude: 180.5), Coordinates(latitude: 0, longitude: -181),
      Coordinates(latitude: .nan, longitude: 0), Coordinates(latitude: 0, longitude: .infinity),
    ] {
      #expect(try Self.error(coordinates) == .invalidCoordinates)
    }
    #expect(try Self.error(Coordinates(latitude: 90, longitude: 180)) == nil)
    #expect(try Self.error(Coordinates(latitude: -90, longitude: -180)) == nil)

    #expect(try Self.error(day: GregorianDay(year: 999, month: 12, day: 31)) == .unsupportedDate)
    #expect(try Self.error(day: GregorianDay(year: 3001, month: 1, day: 1)) == .unsupportedDate)
    #expect(try Self.error(day: GregorianDay(year: 1000, month: 1, day: 1)) == nil)
    #expect(try Self.error(day: GregorianDay(year: 3000, month: 12, day: 31)) == nil)
    // Coordinates are checked first.
    #expect(
      try Self.error(
        Coordinates(latitude: 100, longitude: 0), day: GregorianDay(year: 900, month: 1, day: 1))
        == .invalidCoordinates)
  }

  @Test("Out-of-range parameters throw invalidParameters")
  func parameterErrors() throws {
    let invalid: [(inout CalculationParameters) -> Void] = [
      { $0.fajr = .angle(0.99) }, { $0.fajr = .angle(30.01) }, { $0.fajr = .angle(.nan) },
      { $0.isha = .angle(0.5) }, { $0.isha = .angle(31) }, { $0.isha = .angle(.infinity) },
      { $0.maghrib = .angle(0) }, { $0.maghrib = .angle(-1) }, { $0.maghrib = .angle(30.5) },
      { $0.maghrib = .angle(.nan) },
      { $0.isha = .minutesAfterMaghrib(-1) }, { $0.isha = .minutesAfterMaghrib(1441) },
      { $0.ramadanIsha = .interval(minutes: 0, hijriDayOffset: 0) },
      { $0.ramadanIsha = .interval(minutes: 1441, hijriDayOffset: 0) },
      { $0.ramadanIsha = .interval(minutes: 120, hijriDayOffset: 31) },
      { $0.ramadanIsha = .interval(minutes: 120, hijriDayOffset: -31) },
      { $0.methodAdjustments.fajr = 1441 }, { $0.methodAdjustments.isha = -1441 },
      { $0.adjustments.sunrise = 1441 }, { $0.adjustments.dhuhr = -1441 },
      { $0.adjustments.asr = 2000 }, { $0.adjustments.maghrib = -2000 },
    ]
    for change in invalid {
      #expect(Self.isInvalidParameters(try Self.error(change: change)))
    }

    let valid: [(inout CalculationParameters) -> Void] = [
      { $0.fajr = .angle(1) }, { $0.fajr = .angle(30) }, { $0.isha = .angle(1) },
      { $0.isha = .angle(30) }, { $0.maghrib = .angle(0.01) }, { $0.maghrib = .angle(30) },
      { $0.isha = .minutesAfterMaghrib(0) }, { $0.isha = .minutesAfterMaghrib(1440) },
      { $0.ramadanIsha = .interval(minutes: 1, hijriDayOffset: -30) },
      { $0.ramadanIsha = .interval(minutes: 1440, hijriDayOffset: 30) },
      { $0.methodAdjustments.fajr = 1440 }, { $0.adjustments.isha = -1440 },
      { $0.fajr = .moonsightingCommittee }, { $0.isha = .moonsightingCommittee(.abyad) },
    ]
    for change in valid {
      #expect(try Self.error(change: change) == nil)
    }
  }

  // MARK: Polar day and polar night (section 9)

  @Test("Polar day at Tromsø and Longyearbyen")
  func polarDay() throws {
    for (latitude, longitude, zone) in [
      (69.65, 18.96, "Europe/Oslo"), (78.22, 15.65, "Arctic/Longyearbyen"),
    ] {
      let times = try Self.times(latitude, longitude, zone, "2026-06-21", Self.unrounded)
      let above = EventTime.doesNotOccur(.sunStaysAbove)
      #expect(times.fajr == above)
      #expect(times.sunrise == above)
      #expect(times.sunset == above)
      #expect(times.maghrib == above)
      #expect(times.isha == above)
      #expect(times.middleOfTheNight == above)
      #expect(times.lastThirdOfTheNight == above)
      #expect(times.dhuhr.date != nil)
      #expect(times.asr.date != nil)
    }
  }

  @Test("Polar night at Tromsø and Longyearbyen")
  func polarNight() throws {
    for (latitude, longitude, zone) in [
      (69.65, 18.96, "Europe/Oslo"), (78.22, 15.65, "Arctic/Longyearbyen"),
    ] {
      var parameters = Self.unrounded
      let times = try Self.times(latitude, longitude, zone, "2026-12-21", parameters)
      let below = EventTime.doesNotOccur(.sunStaysBelow)
      #expect(times.sunrise == below)
      #expect(times.sunset == below)
      #expect(times.maghrib == below)
      #expect(times.asr == below)
      #expect(times.middleOfTheNight == below)
      #expect(times.lastThirdOfTheNight == below)
      #expect(times.dhuhr.date != nil)
      // The Sun still climbs past 18° and 17° below the horizon. Without nights, no bound
      // applies, so the angle times stand.
      #expect(times.fajr.date != nil)
      #expect(times.isha.date != nil)
      parameters.highLatitudeRule = .disabled
      let unbounded = try Self.times(latitude, longitude, zone, "2026-12-21", parameters)
      #expect(unbounded.fajr == times.fajr)
      #expect(unbounded.isha == times.isha)
    }
    // At Longyearbyen the Sun stays below -11.7°, so a 10° Isha never comes.
    var parameters = Self.unrounded
    parameters.isha = .angle(10)
    let svalbard = try Self.times(78.22, 15.65, "Arctic/Longyearbyen", "2026-12-21", parameters)
    #expect(svalbard.isha == .doesNotOccur(.sunStaysBelow))
  }

  // MARK: Time zones (section 5)

  @Test("Kiritimati's Dhuhr falls inside its civil day at UTC+14")
  func dateLine() throws {
    let zone = try Self.zone("Pacific/Kiritimati")
    let day = try Self.day("2026-03-20")
    let times = try Self.times(1.87, -157.4, "Pacific/Kiritimati", "2026-03-20", Self.unrounded)
    let dhuhr = try #require(times.dhuhr.date)
    #expect(GregorianDay(containing: dhuhr, in: zone) == day)
    let utc = try Self.zone("UTC")
    #expect(GregorianDay(containing: dhuhr, in: utc) == day.adding(days: -1))
    let localStart = try Self.local("2026-03-20", 0, 0, offsetHours: 14)
    let localHours = (dhuhr.timeIntervalSince1970 - localStart) / 3600
    #expect(localHours > 12 && localHours < 13)
    for event in [times.fajr, times.sunrise, times.asr, times.sunset, times.isha] {
      #expect(GregorianDay(containing: try #require(event.date), in: zone) == day)
    }
  }

  @Test("Kashgar's 18° Isha falls after midnight and still belongs to its day")
  func ishaAfterMidnight() throws {
    var parameters = Self.unrounded
    parameters.isha = .angle(18)
    let zone = try Self.zone("Asia/Shanghai")
    let today = try Self.times(39.47, 75.99, "Asia/Shanghai", "2026-06-21", parameters)
    let tomorrow = try Self.times(39.47, 75.99, "Asia/Shanghai", "2026-06-22", parameters)
    let isha = try #require(today.isha.date)
    #expect(GregorianDay(containing: isha, in: zone) == (try Self.day("2026-06-22")))
    #expect(isha > (try #require(today.maghrib.date)))
    #expect(isha < (try #require(today.middleOfTheNight.date)))
    #expect(isha < (try #require(tomorrow.fajr.date)))
    let nextIsha = try #require(tomorrow.isha.date)
    #expect(abs(nextIsha.timeIntervalSince(isha) - 86_400) < 120)
  }

  @Test(
    "A zone with daylight saving time gives the same instants as its fixed offset",
    arguments: ["2026-03-29", "2026-07-01", "2026-10-25", "2026-12-01"])
  func daylightSavingTime(dayText: String) throws {
    // Local noon moves by an hour, so the transit iteration starts elsewhere and converges to
    // the same transit within its 1 ms tolerance. Rounded to the minute, the times are equal.
    let pairs = [
      (51.5074, -0.1278, "Europe/London", "GMT"),
      (40.7128, -74.006, "America/New_York", "Etc/GMT+5"),
    ]
    for (latitude, longitude, zone, fixedZone) in pairs {
      let exact = try Self.times(latitude, longitude, zone, dayText, Self.unrounded)
      let exactFixed = try Self.times(latitude, longitude, fixedZone, dayText, Self.unrounded)
      let rounded = try Self.times(
        latitude, longitude, zone, dayText, CalculationMethod.muslimWorldLeague.parameters)
      let roundedFixed = try Self.times(
        latitude, longitude, fixedZone, dayText, CalculationMethod.muslimWorldLeague.parameters)
      for event in PrayerTimes.Event.allCases {
        let difference = try Self.seconds(exact[event]) - Self.seconds(exactFixed[event])
        #expect(abs(difference) < 1e-3, "\(zone) \(event)")
        #expect(rounded[event] == roundedFixed[event], "\(zone) \(event)")
      }
    }
  }

  @Test("Computing a day is repeatable and independent of other days")
  func deterministic() throws {
    let parameters = CalculationMethod.moonsightingCommittee.parameters
    let first = try Self.times(51.5074, -0.1278, "Europe/London", "2026-05-01", parameters)
    _ = try Self.times(-33.9, 18.4, "Africa/Johannesburg", "2026-01-01", parameters)
    let second = try Self.times(51.5074, -0.1278, "Europe/London", "2026-05-01", parameters)
    #expect(first == second)
  }
}
