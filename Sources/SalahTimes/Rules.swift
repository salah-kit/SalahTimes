/// How Fajr is determined.
public enum FajrRule: Hashable, Codable, Sendable {
  /// Fajr begins when the Sun, rising, reaches this many degrees below the horizon.
  case angle(Double)

  /// The Moonsighting Committee's definition: the Sun 18° below the horizon, but no earlier than
  /// the committee's seasonal time before sunrise. From 55° of latitude, also no earlier than
  /// the start of the night's last seventh.
  ///
  /// This rule replaces ``CalculationParameters/highLatitudeRule`` for Fajr. METHODS.md cites
  /// the committee's published formula.
  case moonsightingCommittee

  private enum CodingKeys: String, CodingKey {
    case angle
  }

  /// Decodes `{"angle": 18}` or `"moonsightingCommittee"`.
  ///
  /// - Parameter decoder: The decoder to read from.
  public init(from decoder: any Decoder) throws {
    if let name = try? decoder.singleValueContainer().decode(String.self) {
      guard name == "moonsightingCommittee" else {
        throw DecodingError.dataCorrupted(
          .init(codingPath: decoder.codingPath, debugDescription: "Unknown Fajr rule \(name)"))
      }
      self = .moonsightingCommittee
      return
    }
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self = .angle(try container.decode(Double.self, forKey: .angle))
  }

  /// Encodes `{"angle": 18}` or `"moonsightingCommittee"`.
  ///
  /// - Parameter encoder: The encoder to write to.
  public func encode(to encoder: any Encoder) throws {
    switch self {
    case .angle(let degrees):
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(degrees, forKey: .angle)
    case .moonsightingCommittee:
      var container = encoder.singleValueContainer()
      try container.encode("moonsightingCommittee")
    }
  }
}

/// How Isha is determined.
public enum IshaRule: Hashable, Codable, Sendable {
  /// Isha begins when the Sun, setting, reaches this many degrees below the horizon.
  case angle(Double)

  /// Isha begins this many minutes after Maghrib, measured before any minute adjustments.
  ///
  /// High-latitude rules don't change an interval. ``RamadanIshaRule`` can replace the interval
  /// during Ramadan.
  case minutesAfterMaghrib(Int)

  /// The Moonsighting Committee's definition: the Sun 18° below the horizon, but no later than
  /// the committee's seasonal time after sunset for the chosen twilight. From 55° of latitude,
  /// also no later than the end of the night's first seventh.
  ///
  /// This rule replaces ``CalculationParameters/highLatitudeRule`` for Isha.
  case moonsightingCommittee(Shafaq)

  private enum CodingKeys: String, CodingKey {
    case angle
    case minutesAfterMaghrib
    case moonsightingCommittee
  }

  /// Decodes `{"angle": 17}`, `{"minutesAfterMaghrib": 90}` or
  /// `{"moonsightingCommittee": "general"}`.
  ///
  /// - Parameter decoder: The decoder to read from.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    guard container.allKeys.count == 1, let key = container.allKeys.first else {
      throw DecodingError.dataCorrupted(
        .init(
          codingPath: decoder.codingPath,
          debugDescription: "An Isha rule has exactly one of angle, minutesAfterMaghrib or "
            + "moonsightingCommittee"))
    }
    switch key {
    case .angle:
      self = .angle(try container.decode(Double.self, forKey: .angle))
    case .minutesAfterMaghrib:
      self = .minutesAfterMaghrib(try container.decode(Int.self, forKey: .minutesAfterMaghrib))
    case .moonsightingCommittee:
      self = .moonsightingCommittee(
        try container.decode(Shafaq.self, forKey: .moonsightingCommittee))
    }
  }

  /// Encodes `{"angle": 17}`, `{"minutesAfterMaghrib": 90}` or
  /// `{"moonsightingCommittee": "general"}`.
  ///
  /// - Parameter encoder: The encoder to write to.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .angle(let degrees):
      try container.encode(degrees, forKey: .angle)
    case .minutesAfterMaghrib(let minutes):
      try container.encode(minutes, forKey: .minutesAfterMaghrib)
    case .moonsightingCommittee(let shafaq):
      try container.encode(shafaq, forKey: .moonsightingCommittee)
    }
  }
}

/// How Maghrib is determined.
public enum MaghribRule: Hashable, Codable, Sendable {
  /// Maghrib is sunset.
  case sunset

  /// Maghrib begins when the Sun, setting, reaches this many degrees below the horizon, as in
  /// the Tehran method.
  case angle(Double)

  private enum CodingKeys: String, CodingKey {
    case angle
  }

  /// Decodes `"sunset"` or `{"angle": 4.5}`.
  ///
  /// - Parameter decoder: The decoder to read from.
  public init(from decoder: any Decoder) throws {
    if let name = try? decoder.singleValueContainer().decode(String.self) {
      guard name == "sunset" else {
        throw DecodingError.dataCorrupted(
          .init(codingPath: decoder.codingPath, debugDescription: "Unknown Maghrib rule \(name)"))
      }
      self = .sunset
      return
    }
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self = .angle(try container.decode(Double.self, forKey: .angle))
  }

  /// Encodes `"sunset"` or `{"angle": 4.5}`.
  ///
  /// - Parameter encoder: The encoder to write to.
  public func encode(to encoder: any Encoder) throws {
    switch self {
    case .sunset:
      var container = encoder.singleValueContainer()
      try container.encode("sunset")
    case .angle(let degrees):
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(degrees, forKey: .angle)
    }
  }
}

/// The juristic school that sets the shadow length for Asr.
public enum Madhab: String, Hashable, Codable, Sendable, CaseIterable {
  /// Asr begins when an object's shadow equals its length plus its shadow at noon. This is the
  /// position of the Shafi'i, Maliki and Hanbali schools, and of the Ja'fari school.
  case shafi

  /// Asr begins when an object's shadow equals twice its length plus its shadow at noon. This
  /// is the position of the Hanafi school.
  case hanafi

  /// The shadow length, as a multiple of the object's length, added to the noon shadow.
  public var shadowFactor: Double {
    switch self {
    case .shafi: 1
    case .hanafi: 2
    }
  }
}

/// How Fajr and Isha are kept reasonable where twilight lasts long or all night.
///
/// Each rule bounds Fajr and Isha by a portion of the night, measured from sunset to sunrise:
/// Fajr is no earlier than sunrise minus the portion, and Isha is no later than sunset plus the
/// portion. A rule replaces a time only when the Sun's angle gives a time beyond that bound, or
/// no time at all. Read the high-latitudes article for the details.
public enum HighLatitudeRule: String, Hashable, Codable, Sendable, CaseIterable {
  /// The rule ``recommended(for:)`` picks for the location.
  case recommended

  /// Fajr no earlier, and Isha no later, than the middle of the night.
  case middleOfTheNight

  /// Fajr no earlier than the start of the night's last seventh, and Isha no later than the end
  /// of its first seventh.
  case seventhOfTheNight

  /// The portion is the twilight angle divided by 60, so 18° gives 18/60 of the night.
  case twilightAngle

  /// No bound. Fajr and Isha come from the Sun's angle alone, and are reported as not occurring
  /// when the Sun doesn't reach it.
  case disabled

  /// The rule SalahTimes recommends at a location: ``seventhOfTheNight`` beyond 48° of latitude,
  /// north or south, and ``middleOfTheNight`` elsewhere.
  ///
  /// The choice depends on the absolute latitude, so it works the same in both hemispheres.
  /// Beyond about 48.6°, the Sun stays less than 18° below the horizon all night around the
  /// summer solstice.
  ///
  /// - Parameter coordinates: The location.
  /// - Returns: ``seventhOfTheNight`` or ``middleOfTheNight``.
  public static func recommended(for coordinates: Coordinates) -> HighLatitudeRule {
    abs(coordinates.latitude) > 48 ? .seventhOfTheNight : .middleOfTheNight
  }
}

/// The span of night that the middle of the night and its last third divide.
public enum NightSpan: String, Hashable, Codable, Sendable, CaseIterable {
  /// From sunset to the next day's Fajr.
  case sunsetToFajr

  /// From sunset to the next day's sunrise.
  case sunsetToSunrise
}

/// The twilight that ends at Isha in the Moonsighting Committee's method.
public enum Shafaq: String, Hashable, Codable, Sendable, CaseIterable {
  /// A combination of the red and white twilights that the committee recommends. It gives more
  /// reasonable times at higher latitudes.
  case general

  /// The red twilight (al-shafaq al-ahmar), followed by the Shafi'i, Maliki and Hanbali schools.
  /// It gives an earlier Isha.
  case ahmer

  /// The white twilight (al-shafaq al-abyad), followed by the Hanafi school. It gives a later
  /// Isha.
  case abyad
}

/// How computed times are rounded to whole minutes.
public enum Rounding: String, Hashable, Codable, Sendable, CaseIterable {
  /// To the nearest minute, with 30 seconds rounding up.
  case nearest

  /// Up to the next whole minute, unless the time is already on one.
  case up

  /// No rounding; times keep their seconds.
  case none
}

/// Minutes added to computed times. Negative values make a time earlier.
///
/// Missing keys decode as zero.
public struct PrayerAdjustments: Hashable, Codable, Sendable {
  /// Minutes added to Fajr.
  public var fajr: Int
  /// Minutes added to sunrise.
  public var sunrise: Int
  /// Minutes added to Dhuhr.
  public var dhuhr: Int
  /// Minutes added to Asr.
  public var asr: Int
  /// Minutes added to Maghrib.
  public var maghrib: Int
  /// Minutes added to Isha.
  public var isha: Int

  /// Creates adjustments. Each defaults to zero.
  ///
  /// - Parameters:
  ///   - fajr: Minutes added to Fajr.
  ///   - sunrise: Minutes added to sunrise.
  ///   - dhuhr: Minutes added to Dhuhr.
  ///   - asr: Minutes added to Asr.
  ///   - maghrib: Minutes added to Maghrib.
  ///   - isha: Minutes added to Isha.
  public init(
    fajr: Int = 0, sunrise: Int = 0, dhuhr: Int = 0, asr: Int = 0, maghrib: Int = 0,
    isha: Int = 0
  ) {
    self.fajr = fajr
    self.sunrise = sunrise
    self.dhuhr = dhuhr
    self.asr = asr
    self.maghrib = maghrib
    self.isha = isha
  }

  /// No adjustments.
  public static let zero = PrayerAdjustments()

  private enum CodingKeys: String, CodingKey {
    case fajr
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha
  }

  /// Decodes adjustments, reading a missing key as zero.
  ///
  /// - Parameter decoder: The decoder to read from.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    fajr = try container.decodeIfPresent(Int.self, forKey: .fajr) ?? 0
    sunrise = try container.decodeIfPresent(Int.self, forKey: .sunrise) ?? 0
    dhuhr = try container.decodeIfPresent(Int.self, forKey: .dhuhr) ?? 0
    asr = try container.decodeIfPresent(Int.self, forKey: .asr) ?? 0
    maghrib = try container.decodeIfPresent(Int.self, forKey: .maghrib) ?? 0
    isha = try container.decodeIfPresent(Int.self, forKey: .isha) ?? 0
  }
}

/// An opt-in rule that lengthens an interval-based Isha during Ramadan.
///
/// Umm al-Qura's timetables put Isha 120 minutes after Maghrib in Ramadan instead of 90, and
/// some mosques that follow other interval methods do the same. Others don't, and Ramadan's
/// start can differ from the calendar by a day, so the rule is off by default.
public enum RamadanIshaRule: Hashable, Codable, Sendable {
  /// No change during Ramadan.
  case off

  /// During Ramadan, an ``IshaRule/minutesAfterMaghrib(_:)`` interval greater than zero becomes
  /// `minutes`. Nothing else changes, and angle-based Isha is left alone.
  ///
  /// A day is in Ramadan when, after adding `hijriDayOffset` days, it falls in the ninth month
  /// of the Umm al-Qura calendar. An offset of 1 treats the month as starting a day earlier
  /// than the calendar does.
  case interval(minutes: Int, hijriDayOffset: Int)

  private enum CodingKeys: String, CodingKey {
    case interval
  }

  private enum IntervalKeys: String, CodingKey {
    case minutes
    case hijriDayOffset
  }

  /// Decodes `"off"` or `{"interval": {"minutes": 120, "hijriDayOffset": 0}}`.
  ///
  /// - Parameter decoder: The decoder to read from.
  public init(from decoder: any Decoder) throws {
    if let name = try? decoder.singleValueContainer().decode(String.self) {
      guard name == "off" else {
        throw DecodingError.dataCorrupted(
          .init(
            codingPath: decoder.codingPath, debugDescription: "Unknown Ramadan rule \(name)"))
      }
      self = .off
      return
    }
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let interval = try container.nestedContainer(keyedBy: IntervalKeys.self, forKey: .interval)
    self = .interval(
      minutes: try interval.decode(Int.self, forKey: .minutes),
      hijriDayOffset: try interval.decodeIfPresent(Int.self, forKey: .hijriDayOffset) ?? 0)
  }

  /// Encodes `"off"` or `{"interval": {"minutes": 120, "hijriDayOffset": 0}}`.
  ///
  /// - Parameter encoder: The encoder to write to.
  public func encode(to encoder: any Encoder) throws {
    switch self {
    case .off:
      var container = encoder.singleValueContainer()
      try container.encode("off")
    case .interval(let minutes, let hijriDayOffset):
      var container = encoder.container(keyedBy: CodingKeys.self)
      var interval = container.nestedContainer(keyedBy: IntervalKeys.self, forKey: .interval)
      try interval.encode(minutes, forKey: .minutes)
      try interval.encode(hijriDayOffset, forKey: .hijriDayOffset)
    }
  }
}
