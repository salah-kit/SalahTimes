/// Everything that decides how prayer times are computed.
///
/// Start from a method's published parameters and change what you need:
///
/// ```swift
/// var parameters = CalculationMethod.muslimWorldLeague.parameters
/// parameters.madhab = .hanafi
/// parameters.adjustments.isha = 2
/// ```
///
/// Or build fully custom parameters:
///
/// ```swift
/// let custom = CalculationParameters(fajr: .angle(16), isha: .minutesAfterMaghrib(75))
/// ```
///
/// The `Codable` form is the JSON that SalahTimes' vectors use. Decoding requires `fajr` and
/// `isha`, and gives every other missing key its default. The calculation checks the values and
/// throws ``CalculationError/invalidParameters(_:)`` for one it can't use.
public struct CalculationParameters: Hashable, Codable, Sendable {
  /// How Fajr is determined.
  public var fajr: FajrRule

  /// How Maghrib is determined. Defaults to ``MaghribRule/sunset``.
  public var maghrib: MaghribRule

  /// How Isha is determined.
  public var isha: IshaRule

  /// The shadow length for Asr. Defaults to ``Madhab/shafi``.
  public var madhab: Madhab

  /// How Fajr and Isha are bounded where twilight lasts long. Defaults to
  /// ``HighLatitudeRule/recommended``.
  ///
  /// The Moonsighting Committee's rules apply their own bounds instead.
  public var highLatitudeRule: HighLatitudeRule

  /// The night that the middle of the night and its last third divide. Defaults to
  /// ``NightSpan/sunsetToFajr``.
  public var nightSpan: NightSpan

  /// Minutes that the method itself adds, such as Diyanet's precautionary minutes.
  ///
  /// They're kept apart from ``adjustments`` so that a user's own adjustments don't erase them.
  public var methodAdjustments: PrayerAdjustments

  /// The user's own minutes, added on top of ``methodAdjustments``.
  public var adjustments: PrayerAdjustments

  /// How times are rounded to minutes. Defaults to ``Rounding/nearest``.
  public var rounding: Rounding

  /// An opt-in change to interval-based Isha during Ramadan. Defaults to ``RamadanIshaRule/off``.
  public var ramadanIsha: RamadanIshaRule

  /// Creates parameters from the rules for Fajr and Isha, with defaults for everything else.
  ///
  /// - Parameters:
  ///   - fajr: How Fajr is determined.
  ///   - isha: How Isha is determined.
  ///   - maghrib: How Maghrib is determined.
  ///   - madhab: The shadow length for Asr.
  ///   - highLatitudeRule: How Fajr and Isha are bounded where twilight lasts long.
  ///   - nightSpan: The night that the middle of the night and its last third divide.
  ///   - methodAdjustments: Minutes the method itself adds.
  ///   - adjustments: The user's own minutes.
  ///   - rounding: How times are rounded to minutes.
  ///   - ramadanIsha: An opt-in change to interval-based Isha during Ramadan.
  public init(
    fajr: FajrRule,
    isha: IshaRule,
    maghrib: MaghribRule = .sunset,
    madhab: Madhab = .shafi,
    highLatitudeRule: HighLatitudeRule = .recommended,
    nightSpan: NightSpan = .sunsetToFajr,
    methodAdjustments: PrayerAdjustments = .zero,
    adjustments: PrayerAdjustments = .zero,
    rounding: Rounding = .nearest,
    ramadanIsha: RamadanIshaRule = .off
  ) {
    self.fajr = fajr
    self.isha = isha
    self.maghrib = maghrib
    self.madhab = madhab
    self.highLatitudeRule = highLatitudeRule
    self.nightSpan = nightSpan
    self.methodAdjustments = methodAdjustments
    self.adjustments = adjustments
    self.rounding = rounding
    self.ramadanIsha = ramadanIsha
  }

  private enum CodingKeys: String, CodingKey {
    case fajr
    case maghrib
    case isha
    case madhab
    case highLatitudeRule
    case nightSpan
    case methodAdjustments
    case adjustments
    case rounding
    case ramadanIsha
  }

  /// Decodes parameters. `fajr` and `isha` are required; other missing keys take their defaults.
  ///
  /// - Parameter decoder: The decoder to read from.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      fajr: try container.decode(FajrRule.self, forKey: .fajr),
      isha: try container.decode(IshaRule.self, forKey: .isha),
      maghrib: try container.decodeIfPresent(MaghribRule.self, forKey: .maghrib) ?? .sunset,
      madhab: try container.decodeIfPresent(Madhab.self, forKey: .madhab) ?? .shafi,
      highLatitudeRule: try container.decodeIfPresent(
        HighLatitudeRule.self, forKey: .highLatitudeRule) ?? .recommended,
      nightSpan: try container.decodeIfPresent(NightSpan.self, forKey: .nightSpan)
        ?? .sunsetToFajr,
      methodAdjustments: try container.decodeIfPresent(
        PrayerAdjustments.self, forKey: .methodAdjustments) ?? .zero,
      adjustments: try container.decodeIfPresent(PrayerAdjustments.self, forKey: .adjustments)
        ?? .zero,
      rounding: try container.decodeIfPresent(Rounding.self, forKey: .rounding) ?? .nearest,
      ramadanIsha: try container.decodeIfPresent(RamadanIshaRule.self, forKey: .ramadanIsha)
        ?? .off)
  }
}
