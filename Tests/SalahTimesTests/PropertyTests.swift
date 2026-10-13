import Foundation
import SalahTimes
import Testing

/// Properties that hold for every place and day, checked over grids of both.
///
/// Continuity bound: an event's day-to-day change, minus 24 hours, may not exceed the largest
/// such change among the Sun's own crossings at that place (transit, sunrise, sunset, the
/// method's twilight angles and Asr, computed with ``SelfConsistencyTests/NOAASun`` over the
/// surrounding three day pairs) plus 60 seconds. Every SalahTimes event is a crossing, a
/// weighted mean of crossings with weights between 0 and 1 (a bound such as `sunrise - p × night`
/// or the night's middle), or a crossing plus an interval that changes by at most about 20
/// seconds a day (the Moonsighting Committee's seasonal minutes). So none can change faster than
/// the fastest crossing, and the 60 seconds cover the seasonal minutes and the two solar models'
/// few seconds of disagreement. A rule switching on or off with a jump breaks the bound.
@Suite("Properties")
struct PropertyTests {
  typealias Sun = SelfConsistencyTests.NOAASun

  static let orderPresets: [CalculationMethod] = [
    .muslimWorldLeague, .isna, .egyptian, .ummAlQura, .tehran, .moonsightingCommittee, .karachi,
  ]

  // MARK: Order

  @Test("Events are in order over latitudes and every day of 2026", arguments: orderPresets)
  func order(method: CalculationMethod) throws {
    let utc = try #require(TimeZone(identifier: "UTC"))
    let days = Self.days(from: GregorianDay(year: 2026, month: 1, day: 1)!, count: 366)
    var intervalOverlaps: [String] = []
    var checked = 0
    for latitude in stride(from: -65.0, through: 65.0, by: 5) {
      let coordinates = Coordinates(latitude: latitude, longitude: 0)
      let series = try Self.series(coordinates, utc, method.parameters, days)
      for index in 0..<(series.count - 1) {
        let report = Self.orderProblems(series[index], next: series[index + 1])
        checked += 1
        for problem in report.problems {
          Issue.record("\(method) at \(latitude)° on \(days[index]): \(problem)")
        }
        if report.ishaAfterNextFajr {
          if case .minutesAfterMaghrib = method.parameters.isha {
            intervalOverlaps.append("\(latitude)° \(days[index])")
          } else {
            Issue.record("\(method) at \(latitude)° on \(days[index]): Isha after next Fajr")
          }
        }
      }
    }
    // An Isha interval isn't bounded (algorithm.md §8.4), so where the night is shorter than
    // the interval plus the bounded Fajr's distance from sunrise, Isha falls after the next
    // Fajr. That happens only beyond 48°, where the recommended rule bounds Fajr by a seventh.
    for overlap in intervalOverlaps {
      let latitude = Double(overlap.split(separator: "°")[0])!
      #expect(abs(latitude) > 48, "\(method): interval Isha after next Fajr at \(overlap)")
    }
    print(
      "Order \(method): \(checked) days checked; interval Isha after the next Fajr on "
        + "\(intervalOverlaps.count) days"
        + (intervalOverlaps.isEmpty ? "" : " (first \(intervalOverlaps[0]), last "
          + "\(intervalOverlaps[intervalOverlaps.count - 1]))"))
  }

  // MARK: Continuity

  @Test("Day-to-day changes stay within the Sun's own", arguments: orderPresets)
  func continuity(method: CalculationMethod) throws {
    let utc = try #require(TimeZone(identifier: "UTC"))
    let days = Self.days(from: GregorianDay(year: 2026, month: 1, day: 1)!, count: 367)
    var parameters = method.parameters
    parameters.rounding = .none
    var worst = 0.0
    var checked = 0
    for latitude in stride(from: -65.0, through: 65.0, by: 5) {
      let coordinates = Coordinates(latitude: latitude, longitude: 0)
      let series = try Self.series(coordinates, utc, parameters, days)
      let report = Self.continuityProblems(series, coordinates, parameters)
      checked += report.checked
      worst = max(worst, report.worstChange)
      for problem in report.problems {
        Issue.record("\(method) at \(latitude)°: \(problem)")
      }
    }
    print(
      "Continuity \(method): \(checked) day pairs checked, largest change minus 24 h "
        + "\(String(format: "%.1f", worst / 60)) min")
  }

  // MARK: Daylight saving time

  static let daylightSavingPlaces: [(String, Double, Double, Int)] = [
    ("Europe/London", 51.5074, -0.1278, 0),
    ("America/New_York", 40.7128, -74.0060, -18_000),
    ("Australia/Sydney", -33.8688, 151.2093, 36_000),
  ]

  @Test("A DST zone and its fixed-offset equivalent give the same instants")
  func daylightSaving() throws {
    let days = Self.days(from: GregorianDay(year: 2026, month: 1, day: 1)!, count: 367)
    var parameters = CalculationMethod.muslimWorldLeague.parameters
    // Rounding can differ when an instant lies within a millisecond of a half minute, because
    // the two zones' instants agree to well under a millisecond but not bit for bit.
    parameters.rounding = .none
    for (identifier, latitude, longitude, offset) in Self.daylightSavingPlaces {
      let zone = try #require(TimeZone(identifier: identifier))
      let fixed = try #require(TimeZone(secondsFromGMT: offset))
      let coordinates = Coordinates(latitude: latitude, longitude: longitude)
      let withDST = try Self.series(coordinates, zone, parameters, days)
      let withoutDST = try Self.series(coordinates, fixed, parameters, days)
      var largest = 0.0
      for (a, b) in zip(withDST, withoutDST) {
        for event in PrayerTimes.Event.allCases {
          switch (a[event], b[event]) {
          case (.occurs(let x), .occurs(let y)):
            largest = max(largest, abs(x.timeIntervalSince(y)))
            #expect(abs(x.timeIntervalSince(y)) < 0.5, "\(identifier) \(a.day) \(event)")
          default:
            #expect(a[event] == b[event], "\(identifier) \(a.day) \(event)")
          }
        }
      }

      // The days whose UTC offset at noon differs from the previous day's.
      var transitions: [Int] = []
      for index in 1..<days.count {
        if Self.noonOffset(days[index], zone) != Self.noonOffset(days[index - 1], zone) {
          transitions.append(index)
        }
      }
      #expect(transitions.count == 2, "\(identifier) should have two transitions in 2026")
      for index in transitions {
        let dhuhrChange = withDST[index].dhuhr.date!.timeIntervalSince(
          withDST[index - 1].dhuhr.date!)
        #expect(abs(dhuhrChange - 86_400) < 60, "\(identifier) \(days[index]): Dhuhr jumps")
      }
      let report = Self.continuityProblems(withDST, coordinates, parameters)
      for problem in report.problems {
        Issue.record("\(identifier): \(problem)")
      }
      print(
        "DST \(identifier): largest DST/fixed difference \(largest) s; transitions on "
          + transitions.map { "\(days[$0])" }.joined(separator: ", "))
    }
  }

  // MARK: Polar regimes

  @Test("Polar day and polar night in Tromsø and Longyearbyen")
  func polarRegimes() throws {
    let above = EventTime.doesNotOccur(.sunStaysAbove)
    let below = EventTime.doesNotOccur(.sunStaysBelow)
    let places = [
      ("Tromsø", 69.65, 18.96, "Europe/Oslo"),
      ("Longyearbyen", 78.22, 15.65, "Arctic/Longyearbyen"),
    ]
    for (name, latitude, longitude, identifier) in places {
      let zone = try #require(TimeZone(identifier: identifier))
      let coordinates = Coordinates(latitude: latitude, longitude: longitude)
      for madhab in [Madhab.shafi, .hanafi] {
        var parameters = CalculationMethod.muslimWorldLeague.parameters
        parameters.madhab = madhab

        // Polar day: the Sun never sets, but it still descends past the Asr altitude.
        let june = try PrayerTimes(
          coordinates: coordinates, day: GregorianDay(year: 2026, month: 6, day: 21)!,
          timeZone: zone, parameters: parameters)
        #expect(june.fajr == above, "\(name) June Fajr")
        #expect(june.sunrise == above, "\(name) June sunrise")
        #expect(june.dhuhr.date != nil, "\(name) June Dhuhr")
        #expect(june.asr.date != nil, "\(name) June Asr \(madhab)")
        #expect(june.sunset == above, "\(name) June sunset")
        #expect(june.maghrib == above, "\(name) June Maghrib")
        #expect(june.isha == above, "\(name) June Isha")
        #expect(june.middleOfTheNight == above, "\(name) June middle of the night")
        #expect(june.lastThirdOfTheNight == above, "\(name) June last third")

        // Polar night: no sunrise or Asr, but the Sun still climbs past 18° and 17° below the
        // horizon, and with no night to bound them those times stand.
        let december = try PrayerTimes(
          coordinates: coordinates, day: GregorianDay(year: 2026, month: 12, day: 21)!,
          timeZone: zone, parameters: parameters)
        #expect(december.fajr.date != nil, "\(name) December Fajr")
        #expect(december.sunrise == below, "\(name) December sunrise")
        #expect(december.dhuhr.date != nil, "\(name) December Dhuhr")
        #expect(december.asr == below, "\(name) December Asr")
        #expect(december.sunset == below, "\(name) December sunset")
        #expect(december.maghrib == below, "\(name) December Maghrib")
        #expect(december.isha.date != nil, "\(name) December Isha")
        #expect(december.middleOfTheNight == below, "\(name) December middle of the night")
        #expect(december.lastThirdOfTheNight == below, "\(name) December last third")
      }
    }

    // A white night in Tromsø: the Sun sets but never reaches 17° below the horizon. The
    // seventh-of-the-night bound supplies Isha; without a bound it doesn't occur.
    let tromso = Coordinates(latitude: 69.65, longitude: 18.96)
    let oslo = try #require(TimeZone(identifier: "Europe/Oslo"))
    let may = GregorianDay(year: 2026, month: 5, day: 1)!
    var parameters = CalculationMethod.muslimWorldLeague.parameters
    let bounded = try PrayerTimes(
      coordinates: tromso, day: may, timeZone: oslo, parameters: parameters)
    #expect(bounded.sunset.date != nil)
    #expect(bounded.isha.date != nil)
    #expect(bounded.fajr.date != nil)
    parameters.highLatitudeRule = .disabled
    let unbounded = try PrayerTimes(
      coordinates: tromso, day: may, timeZone: oslo, parameters: parameters)
    #expect(unbounded.sunset.date != nil)
    #expect(unbounded.isha == above)
    #expect(unbounded.fajr == above)
  }

  // MARK: The equator and the date line

  static let equatorPlaces: [(String, Double, Double, String)] = [
    ("Kiritimati", 1.87, -157.43, "Pacific/Kiritimati"),
    ("Apia", -13.83, -171.76, "Pacific/Apia"),
    ("Adak", 51.88, -176.66, "America/Adak"),
    ("Quito", -0.18, -78.47, "America/Guayaquil"),
    ("Singapore", 1.35, 103.82, "Asia/Singapore"),
    ("Pontianak", -0.03, 109.33, "Asia/Pontianak"),
  ]

  @Test("Fajr to Maghrib fall on the civil day, and Dhuhr at solar noon")
  func equatorAndDateLine() throws {
    let days = Self.days(from: GregorianDay(year: 2026, month: 1, day: 1)!, count: 365)
    var exact = CalculationMethod.muslimWorldLeague.parameters
    exact.rounding = .none
    var worstNoon = 0.0
    for (name, latitude, longitude, identifier) in Self.equatorPlaces {
      let zone = try #require(TimeZone(identifier: identifier))
      let coordinates = Coordinates(latitude: latitude, longitude: longitude)
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = zone
      let rounded = try Self.series(
        coordinates, zone, CalculationMethod.muslimWorldLeague.parameters, days)
      let unrounded = try Self.series(coordinates, zone, exact, days)
      for (index, day) in days.enumerated() {
        let start = calendar.date(
          from: DateComponents(year: day.year, month: day.month, day: day.day))!
        let next = day.adding(days: 1)
        let end = calendar.date(
          from: DateComponents(year: next.year, month: next.month, day: next.day))!
        for event in [PrayerTimes.Event.fajr, .sunrise, .dhuhr, .asr, .sunset, .maghrib] {
          let instant = try #require(rounded[index][event].date, "\(name) \(day) \(event)")
          #expect(start <= instant && instant < end, "\(name) \(day) \(event) off its day")
        }
        let dhuhr = unrounded[index].dhuhr.date!
        let noon = Sun.solarNoon(near: dhuhr, longitude: longitude)
        worstNoon = max(worstNoon, abs(dhuhr.timeIntervalSince(noon)))
        // NOAA's equation of time differs from the right-ascension form by up to ~7 s.
        #expect(abs(dhuhr.timeIntervalSince(noon)) < 10, "\(name) \(day) Dhuhr vs solar noon")
      }
    }
    print("Equator and date line: largest |Dhuhr - NOAA solar noon| \(worstNoon) s")
  }

  // MARK: Southern high latitudes

  static let southernPlaces: [(String, Double, Double, String)] = [
    ("Ushuaia", -54.80, -68.30, "America/Argentina/Ushuaia"),
    ("Punta Arenas", -53.16, -70.91, "America/Punta_Arenas"),
  ]

  /// The largest allowed difference, in seconds, between an event's distance from Dhuhr at a
  /// southern place and at its northern mirror on the day the Sun's declination is opposite.
  /// Pairing by declination and interpolating linearly between two northern days leaves an
  /// error of a few seconds; the rest is the asymmetry of the orbit, which changes how fast the
  /// declination moves and so the neighboring nights that a bound uses.
  static let mirrorTolerance = 120.0

  @Test("Ushuaia and Punta Arenas: seventh of the night, ordered, continuous, mirrored")
  func southernHighLatitudes() throws {
    let southDays = Self.days(from: GregorianDay(year: 2026, month: 1, day: 1)!, count: 367)
    let northDays = Self.days(from: GregorianDay(year: 2025, month: 7, day: 1)!, count: 731)
    var worstMirror = 0.0
    var mirrored = 0
    for (name, latitude, longitude, identifier) in Self.southernPlaces {
      let zone = try #require(TimeZone(identifier: identifier))
      let south = Coordinates(latitude: latitude, longitude: longitude)
      #expect(HighLatitudeRule.recommended(for: south) == .seventhOfTheNight)

      var recommended = CalculationMethod.muslimWorldLeague.parameters
      var seventh = recommended
      seventh.highLatitudeRule = .seventhOfTheNight
      let viaRecommended = try Self.series(south, zone, recommended, southDays)
      let viaSeventh = try Self.series(south, zone, seventh, southDays)
      #expect(viaRecommended == viaSeventh, "\(name): recommended isn't the seventh")

      for index in 0..<(viaRecommended.count - 1) {
        for problem in Self.orderProblems(viaRecommended[index], next: viaRecommended[index + 1])
          .problems
        {
          Issue.record("\(name) \(southDays[index]): \(problem)")
        }
      }

      recommended.rounding = .none
      let exactSouth = try Self.series(south, zone, recommended, southDays)
      for problem in Self.continuityProblems(exactSouth, south, recommended).problems {
        Issue.record("\(name): \(problem)")
      }

      // The mirror: the same latitude north, compared by distance from Dhuhr.
      let north = Coordinates(latitude: -latitude, longitude: longitude)
      let exactNorth = try Self.series(north, zone, recommended, northDays)
      let southDeclinations = exactSouth.map { Sun.position(at: $0.dhuhr.date!).declination }
      let northDeclinations = exactNorth.map { Sun.position(at: $0.dhuhr.date!).declination }
      for index in 1..<(exactSouth.count - 1) {
        let target = -southDeclinations[index]
        let southTrend = southDeclinations[index + 1] - southDeclinations[index - 1]
        // The northern day pair that brackets the opposite declination, with the opposite
        // trend, nearest half a year later or earlier.
        let expected = [index + 184 + 182, index + 184 - 183]
        var best: Int?
        for n in 0..<(northDeclinations.count - 1) {
          let a = northDeclinations[n] - target
          let b = northDeclinations[n + 1] - target
          guard a * b <= 0, a != b else { continue }
          let northTrend = northDeclinations[n + 1] - northDeclinations[n]
          guard northTrend * southTrend < 0 else { continue }
          let distance = expected.map { abs($0 - n) }.min()!
          if best == nil || distance < expected.map({ abs($0 - best!) }).min()! {
            best = n
          }
        }
        guard let n = best else { continue }
        let fraction =
          (target - northDeclinations[n]) / (northDeclinations[n + 1] - northDeclinations[n])
        for event in [PrayerTimes.Event.fajr, .sunrise, .asr, .sunset, .isha] {
          guard let southOffset = Self.offsetFromDhuhr(exactSouth[index], event),
            let northA = Self.offsetFromDhuhr(exactNorth[n], event),
            let northB = Self.offsetFromDhuhr(exactNorth[n + 1], event)
          else { continue }
          let northOffset = northA + (northB - northA) * fraction
          let difference = abs(southOffset - northOffset)
          worstMirror = max(worstMirror, difference)
          mirrored += 1
          #expect(
            difference <= Self.mirrorTolerance,
            "\(name) \(southDays[index]) \(event): \(difference) s from its northern mirror")
        }
      }
    }
    #expect(mirrored > 3_000)
    print("Southern mirror: \(mirrored) comparisons, largest difference \(worstMirror) s")
  }

  // MARK: Helpers

  static func days(from start: GregorianDay, count: Int) -> [GregorianDay] {
    (0..<count).map { start.adding(days: $0) }
  }

  static func series(
    _ coordinates: Coordinates, _ timeZone: TimeZone, _ parameters: CalculationParameters,
    _ days: [GregorianDay]
  ) throws -> [PrayerTimes] {
    try days.map {
      try PrayerTimes(
        coordinates: coordinates, day: $0, timeZone: timeZone, parameters: parameters)
    }
  }

  static func noonOffset(_ day: GregorianDay, _ zone: TimeZone) -> Int {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = zone
    let noon = calendar.date(
      from: DateComponents(year: day.year, month: day.month, day: day.day, hour: 12))!
    return zone.secondsFromGMT(for: noon)
  }

  static func offsetFromDhuhr(_ times: PrayerTimes, _ event: PrayerTimes.Event) -> Double? {
    guard let instant = times[event].date, let dhuhr = times.dhuhr.date else { return nil }
    return instant.timeIntervalSince(dhuhr)
  }

  static let chain: [PrayerTimes.Event] = [
    .fajr, .sunrise, .dhuhr, .asr, .sunset, .maghrib, .isha,
  ]

  /// Order problems on one day, and whether Isha falls after the next day's Fajr.
  static func orderProblems(_ times: PrayerTimes, next: PrayerTimes) -> (
    problems: [String], ishaAfterNextFajr: Bool
  ) {
    var problems: [String] = []
    let occurring = chain.compactMap { event in times[event].date.map { (event, $0) } }
    for (first, second) in zip(occurring, occurring.dropFirst()) {
      let allowsEqual = first.0 == .sunset && second.0 == .maghrib
      let ordered = allowsEqual ? first.1 <= second.1 : first.1 < second.1
      if !ordered {
        problems.append("\(first.0) \(first.1) not before \(second.0) \(second.1)")
      }
    }
    if let middle = times.middleOfTheNight.date, let third = times.lastThirdOfTheNight.date,
      !(middle < third)
    {
      problems.append("middle of the night \(middle) not before last third \(third)")
    }
    var ishaAfterNextFajr = false
    if let isha = times.isha.date, let fajr = next.fajr.date, isha > fajr {
      ishaAfterNextFajr = true
    }
    return (problems, ishaAfterNextFajr)
  }

  /// The altitudes whose crossings bound how fast events can move, for the parameters.
  static func crossingAltitudes(_ parameters: CalculationParameters) -> [(Double, Bool)] {
    var altitudes: [(Double, Bool)] = [(-50.0 / 60, true), (-50.0 / 60, false)]
    switch parameters.fajr {
    case .angle(let angle): altitudes.append((-angle, true))
    case .moonsightingCommittee: altitudes.append((-18, true))
    }
    switch parameters.isha {
    case .angle(let angle): altitudes.append((-angle, false))
    case .moonsightingCommittee: altitudes.append((-18, false))
    case .minutesAfterMaghrib: break
    }
    if case .angle(let angle) = parameters.maghrib {
      altitudes.append((-angle, false))
    }
    return altitudes
  }

  /// Checks ``PropertyTests``' continuity bound over consecutive days of a series computed
  /// with `rounding: .none`.
  static func continuityProblems(
    _ series: [PrayerTimes], _ coordinates: Coordinates, _ parameters: CalculationParameters
  ) -> (problems: [String], checked: Int, worstChange: Double) {
    let latitude = coordinates.latitude
    let longitude = coordinates.longitude
    let altitudes = crossingAltitudes(parameters)
    // The Sun's own crossings for each day: transit, the altitudes, and Asr.
    let own: [[Date?]] = series.map { times in
      let noon = Sun.solarNoon(near: times.dhuhr.date!, longitude: longitude)
      var crossings: [Date?] = [noon]
      for (altitude, morning) in altitudes {
        crossings.append(
          Sun.crossing(
            altitude: altitude, noon: noon, latitude: latitude, longitude: longitude,
            morning: morning))
      }
      let zenith = abs(latitude - Sun.position(at: noon).declination)
      if zenith < 90 {
        let asr = Sun.degrees(
          atan(1 / (parameters.madhab.shadowFactor + tan(Sun.radians(zenith)))))
        crossings.append(
          Sun.crossing(
            altitude: asr, noon: noon, latitude: latitude, longitude: longitude, morning: false))
      } else {
        crossings.append(nil)
      }
      return crossings
    }
    // The fastest own change for each day pair.
    let ownChange: [Double] = (0..<(series.count - 1)).map { index in
      var fastest = 0.0
      for (a, b) in zip(own[index], own[index + 1]) {
        if let a, let b {
          fastest = max(fastest, abs(b.timeIntervalSince(a) - 86_400))
        }
      }
      return fastest
    }
    var problems: [String] = []
    var checked = 0
    var worst = 0.0
    for index in 0..<(series.count - 1) {
      let window = ownChange[max(0, index - 1)...min(ownChange.count - 1, index + 1)]
      let bound = window.max()! + 60
      for event in PrayerTimes.Event.allCases {
        guard let a = series[index][event].date, let b = series[index + 1][event].date else {
          continue
        }
        let change = abs(b.timeIntervalSince(a) - 86_400)
        worst = max(worst, change)
        checked += 1
        if change > bound {
          problems.append(
            "\(event) from \(series[index].day) to \(series[index + 1].day) changes by "
              + "\(Int(change)) s beyond 24 h; the bound is \(Int(bound)) s")
        }
      }
    }
    return (problems, checked, worst)
  }
}
