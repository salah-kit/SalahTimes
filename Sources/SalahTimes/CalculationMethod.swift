/// A published calculation method.
///
/// Each method's ``parameters`` reproduce its authority's published definition. METHODS.md lists
/// the values with their sources. Start from a method and customize the parameters, or build
/// ``CalculationParameters`` from scratch for a custom method.
///
/// ```swift
/// var parameters = CalculationMethod.ummAlQura.parameters
/// parameters.ramadanIsha = .interval(minutes: 120, hijriDayOffset: 0)
/// ```
public enum CalculationMethod: String, Hashable, Codable, Sendable, CaseIterable {
  /// Muslim World League: Fajr at 18°, Isha at 17°.
  case muslimWorldLeague

  /// Islamic Society of North America: Fajr and Isha at 15°.
  case isna

  /// Egyptian General Authority of Survey: Fajr at 19.5°, Isha at 17.5°.
  case egyptian

  /// Umm al-Qura University, Makkah: Fajr at 18.5°, Isha 90 minutes after Maghrib.
  case ummAlQura

  /// University of Islamic Sciences, Karachi: Fajr and Isha at 18°.
  case karachi

  /// Institute of Geophysics, University of Tehran: Fajr at 17.7°, Maghrib at 4.5°, Isha at 14°.
  case tehran

  /// Presidency of Religious Affairs of Turkey (Diyanet): Fajr at 18°, Isha at 17°, with its
  /// precautionary minutes.
  case diyanet

  /// The United Arab Emirates' General Authority of Islamic Affairs and Endowments, as used in
  /// Dubai: Fajr and Isha at 18.2°, with its precautionary minutes.
  case dubai

  /// Kuwait's Ministry of Awqaf and Islamic Affairs: Fajr at 18°, Isha at 17.5°.
  case kuwait

  /// Qatar's Ministry of Endowments and Islamic Affairs: Fajr at 18°, Isha 90 minutes after
  /// Maghrib.
  case qatar

  /// Majlis Ugama Islam Singapura (MUIS): Fajr at 20°, Isha at 18°.
  case muis

  /// Jabatan Kemajuan Islam Malaysia (JAKIM): Fajr at 20°, Isha at 18°.
  case jakim

  /// Indonesia's Ministry of Religious Affairs (Kemenag): Fajr at 20°, Isha at 18°.
  case kemenag

  /// The Moonsighting Committee Worldwide: 18° with its seasonal adjustments for Fajr and Isha.
  case moonsightingCommittee

  /// The method's published parameters.
  ///
  /// Every preset uses ``HighLatitudeRule/recommended``, ``Madhab/shafi``, no user adjustments
  /// and ``RamadanIshaRule/off``. Change any of them on the returned value.
  public var parameters: CalculationParameters {
    switch self {
    case .muslimWorldLeague:
      CalculationParameters(fajr: .angle(18), isha: .angle(17))
    case .isna:
      CalculationParameters(fajr: .angle(15), isha: .angle(15))
    case .egyptian:
      CalculationParameters(fajr: .angle(19.5), isha: .angle(17.5))
    case .ummAlQura:
      CalculationParameters(fajr: .angle(18.5), isha: .minutesAfterMaghrib(90))
    case .karachi:
      CalculationParameters(fajr: .angle(18), isha: .angle(18))
    case .tehran:
      CalculationParameters(fajr: .angle(17.7), isha: .angle(14), maghrib: .angle(4.5))
    case .diyanet:
      CalculationParameters(
        fajr: .angle(18), isha: .angle(17),
        methodAdjustments: PrayerAdjustments(sunrise: -7, dhuhr: 5, asr: 4, maghrib: 7))
    case .dubai:
      CalculationParameters(
        fajr: .angle(18.2), isha: .angle(18.2),
        methodAdjustments: PrayerAdjustments(sunrise: -3, dhuhr: 3, asr: 3, maghrib: 3))
    case .kuwait:
      CalculationParameters(fajr: .angle(18), isha: .angle(17.5))
    case .qatar:
      CalculationParameters(fajr: .angle(18), isha: .minutesAfterMaghrib(90))
    case .muis:
      CalculationParameters(fajr: .angle(20), isha: .angle(18))
    case .jakim:
      CalculationParameters(fajr: .angle(20), isha: .angle(18))
    case .kemenag:
      CalculationParameters(fajr: .angle(20), isha: .angle(18))
    case .moonsightingCommittee:
      CalculationParameters(
        fajr: .moonsightingCommittee, isha: .moonsightingCommittee(.general),
        methodAdjustments: PrayerAdjustments(dhuhr: 5, maghrib: 3))
    }
  }
}
