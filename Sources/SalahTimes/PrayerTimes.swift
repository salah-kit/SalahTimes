import Foundation

/// The prayer times that belong to one civil day at one place.
///
/// Compute them for a day in the location's time zone:
///
/// ```swift
/// let riyadh = TimeZone(identifier: "Asia/Riyadh")!
/// let times = try PrayerTimes(
///   coordinates: Coordinates(latitude: 21.4225, longitude: 39.8262),
///   day: GregorianDay(containing: Date(), in: riyadh),
///   timeZone: riyadh,
///   parameters: CalculationMethod.ummAlQura.parameters)
/// if let isha = times.isha.date {
///   print(isha)
/// }
/// ```
///
/// Every event is an instant, a `Date`. Formatting it, in whatever time zone and calendar, is up
/// to you.
///
/// ## Owning day
///
/// Every event in a `PrayerTimes` value belongs to the ``day`` you asked for, even when its
/// instant falls on a neighboring civil day in ``timeZone``:
/// - Isha can fall after midnight, in summer at high latitudes, or where the clock runs far
///   ahead of the Sun.
/// - The middle of the night and its last third usually fall after midnight.
/// - At a few high-latitude places east of their time zone's meridian, a Fajr bounded by a
///   high-latitude rule can fall shortly before the day begins.
///
/// ## Events that don't occur
///
/// When an event doesn't happen on a day, such as sunset during polar day, its ``EventTime`` is
/// ``EventTime/doesNotOccur(_:)`` with the reason. SalahTimes never invents a time.
public struct PrayerTimes: Hashable, Codable, Sendable {
  /// The civil day these events belong to.
  public let day: GregorianDay

  /// The time zone that defines ``day``.
  public let timeZone: TimeZone

  /// The start of Fajr.
  public let fajr: EventTime

  /// Sunrise, which ends Fajr. It includes sunrise's minute adjustments.
  public let sunrise: EventTime

  /// The start of Dhuhr, at the Sun's transit plus Dhuhr's minute adjustments.
  public let dhuhr: EventTime

  /// The start of Asr.
  public let asr: EventTime

  /// The astronomical sunset, without adjustments.
  public let sunset: EventTime

  /// The start of Maghrib.
  public let maghrib: EventTime

  /// The start of Isha.
  public let isha: EventTime

  /// The middle of the night, from sunset to the end chosen by ``CalculationParameters/nightSpan``.
  public let middleOfTheNight: EventTime

  /// The start of the night's last third, on the same span as ``middleOfTheNight``.
  public let lastThirdOfTheNight: EventTime

  /// Computes the events that belong to a civil day in a time zone.
  ///
  /// - Parameters:
  ///   - coordinates: Where to compute.
  ///   - day: The civil day the events belong to.
  ///   - timeZone: The time zone that defines `day`. Use the location's time zone, not the
  ///     device's.
  ///   - parameters: How to compute.
  /// - Throws: ``CalculationError`` when the coordinates or parameters can't be used, or the
  ///   year is outside the supported range.
  public init(
    coordinates: Coordinates, day: GregorianDay, timeZone: TimeZone,
    parameters: CalculationParameters
  ) throws {
    self = try Engine.prayerTimes(
      coordinates: coordinates, day: day, timeZone: timeZone, parameters: parameters)
  }

  init(
    day: GregorianDay, timeZone: TimeZone, fajr: EventTime, sunrise: EventTime, dhuhr: EventTime,
    asr: EventTime, sunset: EventTime, maghrib: EventTime, isha: EventTime,
    middleOfTheNight: EventTime, lastThirdOfTheNight: EventTime
  ) {
    self.day = day
    self.timeZone = timeZone
    self.fajr = fajr
    self.sunrise = sunrise
    self.dhuhr = dhuhr
    self.asr = asr
    self.sunset = sunset
    self.maghrib = maghrib
    self.isha = isha
    self.middleOfTheNight = middleOfTheNight
    self.lastThirdOfTheNight = lastThirdOfTheNight
  }

  /// The time of an event.
  ///
  /// - Parameter event: The event.
  public subscript(event: Event) -> EventTime {
    switch event {
    case .fajr: fajr
    case .sunrise: sunrise
    case .dhuhr: dhuhr
    case .asr: asr
    case .sunset: sunset
    case .maghrib: maghrib
    case .isha: isha
    case .middleOfTheNight: middleOfTheNight
    case .lastThirdOfTheNight: lastThirdOfTheNight
    }
  }

  /// The events SalahTimes computes, in the order they normally occur.
  public enum Event: String, Hashable, Codable, Sendable, CaseIterable {
    /// The start of Fajr.
    case fajr
    /// Sunrise, which ends Fajr.
    case sunrise
    /// The start of Dhuhr.
    case dhuhr
    /// The start of Asr.
    case asr
    /// The astronomical sunset.
    case sunset
    /// The start of Maghrib.
    case maghrib
    /// The start of Isha.
    case isha
    /// The middle of the night.
    case middleOfTheNight
    /// The start of the night's last third.
    case lastThirdOfTheNight
  }
}

/// When an event happens on a day, or why it doesn't.
public enum EventTime: Hashable, Codable, Sendable {
  /// The event happens at this instant.
  case occurs(Date)

  /// The event doesn't happen on this day.
  case doesNotOccur(NonOccurrence)

  /// The instant, or `nil` when the event doesn't occur.
  public var date: Date? {
    if case .occurs(let date) = self { date } else { nil }
  }

  private enum CodingKeys: String, CodingKey {
    case occurs
    case doesNotOccur
  }

  /// Decodes `{"occurs": <date>}` or `{"doesNotOccur": "<reason>"}`, with exactly one of the
  /// two keys. The date uses the decoder's date strategy.
  ///
  /// - Parameter decoder: The decoder to read from.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    guard container.allKeys.count == 1, let key = container.allKeys.first else {
      throw DecodingError.dataCorrupted(
        .init(
          codingPath: decoder.codingPath,
          debugDescription: "An event time has exactly one of occurs and doesNotOccur"))
    }
    switch key {
    case .occurs:
      self = .occurs(try container.decode(Date.self, forKey: .occurs))
    case .doesNotOccur:
      self = .doesNotOccur(try container.decode(NonOccurrence.self, forKey: .doesNotOccur))
    }
  }

  /// Encodes `{"occurs": <date>}` or `{"doesNotOccur": "<reason>"}`. The date uses the encoder's
  /// date strategy.
  ///
  /// - Parameter encoder: The encoder to write to.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .occurs(let date):
      try container.encode(date, forKey: .occurs)
    case .doesNotOccur(let reason):
      try container.encode(reason, forKey: .doesNotOccur)
    }
  }
}

/// Why an event doesn't occur on a day.
///
/// An event defined from another event, such as Isha a fixed interval after Maghrib, or the
/// middle of the night, takes the reason of the event it depends on.
public enum NonOccurrence: String, Hashable, Codable, Sendable, CaseIterable {
  /// The Sun stays above the altitude that defines the event for the whole day. There's no
  /// sunset during polar day, and no Isha at 18° where twilight lasts all night.
  case sunStaysAbove

  /// The Sun stays below the altitude that defines the event for the whole day. There's no
  /// sunrise during polar night.
  case sunStaysBelow
}

/// A reason SalahTimes can't compute prayer times.
public enum CalculationError: Error, Hashable, Sendable {
  /// A latitude or longitude is out of range or not finite.
  case invalidCoordinates

  /// A parameter is out of range, such as a negative angle. The text names it.
  case invalidParameters(String)

  /// The day's year is outside the supported range, 1000 to 3000.
  case unsupportedDate
}
