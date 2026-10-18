/// A published calculation method.
///
/// Each method's ``parameters`` reproduce its authority's times. When the authority documents
/// its rules, the preset follows them: the Sun's angles or intervals, plus the precautionary
/// minutes and rounding it documents. When it publishes only timetables, as in Singapore and the
/// United Arab Emirates, the values are fitted to those timetables. METHODS.md gives every value
/// with its source and the measured differences from official timetables.
///
/// A method is a starting point. Start from one and customize the parameters, or build
/// ``CalculationParameters`` from scratch for a custom method.
///
/// ```swift
/// var parameters = CalculationMethod.ummAlQura.parameters
/// parameters.ramadanIsha = .interval(minutes: 120, hijriDayOffset: 0)
/// ```
public enum CalculationMethod: String, Hashable, Codable, Sendable, CaseIterable {
  /// Muslim World League: Fajr at 18°, Isha at 17°.
  case muslimWorldLeague

  /// Islamic Society of North America: Fajr and Isha at 15°, what the Fiqh Council of North
  /// America has suggested for the United States since 2017.
  ///
  /// The council's published positions have changed over time: 18° in 2010, and in 2011 the
  /// Moonsighting Committee's seasonal method, which ``moonsightingCommittee`` reproduces.
  /// METHODS.md gives the history and its sources.
  case isna

  /// Egyptian General Authority of Survey: Fajr at 19.5°, Isha at 17.5°.
  case egyptian

  /// Umm al-Qura University, Makkah, as used in Saudi Arabia's Umm al-Qura calendar: Fajr at
  /// 18.5°, Isha 90 minutes after Maghrib.
  ///
  /// The calendar puts Isha 120 minutes after Maghrib during Ramadan. Opt in with
  /// ``CalculationParameters/ramadanIsha``.
  case ummAlQura

  /// University of Islamic Sciences, Karachi: Fajr and Isha at 18°.
  case karachi

  /// Institute of Geophysics, University of Tehran: Fajr at 17.7°, Maghrib at 4.5°, Isha at 14°,
  /// and the night measured from sunset to Fajr.
  case tehran

  /// Presidency of Religious Affairs of Turkey (Diyanet İşleri Başkanlığı): Fajr at 18°, Isha at
  /// 17°, with Diyanet's precautionary minutes (temkin): sunrise 7 minutes earlier, Dhuhr 5,
  /// Asr 4 and Maghrib 7 minutes later.
  case diyanet

  /// The United Arab Emirates, as used in Dubai and Abu Dhabi: Fajr and Isha at 18.2°, sunrise
  /// 3 minutes earlier, and Dhuhr, Asr and Maghrib 3 minutes later.
  ///
  /// The authority doesn't publish its method; every value is fitted to its official timetables.
  case dubai

  /// Kuwait: Fajr at 18°, Isha at 17.5°.
  ///
  /// Neither the Al-Ojeiri Scientific Centre, whose calendar is Kuwait's official one, nor the
  /// Ministry of Awqaf and Islamic Affairs states the angles. These values are fitted to the
  /// Centre's official calendar, as METHODS.md describes.
  case kuwait

  /// Qatar Calendar House, for Qatar's Ministry of Endowments and Islamic Affairs: Fajr at 18°,
  /// Isha 90 minutes after Maghrib.
  case qatar

  /// Majlis Ugama Islam Singapura (MUIS): Fajr at 20°, Isha at 18°, Dhuhr a minute after the
  /// Sun's transit, and times rounded up to the minute.
  ///
  /// MUIS doesn't publish its method; every value is fitted to its official timetable.
  case muis

  /// Jabatan Kemajuan Islam Malaysia (JAKIM): Fajr at 18° since 2019, Isha at 18°, and Dhuhr a
  /// minute after the Sun's transit.
  case jakim

  /// Indonesia's Ministry of Religious Affairs (Kemenag): Fajr at 20°, Maghrib with the Sun 1°
  /// below the horizon, Isha at 18°, times rounded up to the minute, then 2 minutes of precaution
  /// (ihtiyat) added, 3 for Dhuhr.
  ///
  /// Kemenag drops sunrise's seconds and subtracts 2 minutes. With rounding up, the preset's
  /// −3 minutes for sunrise gives the same minute.
  case kemenag

  /// The Moonsighting Committee Worldwide (Khalid Shaukat): 18° bounded by the committee's
  /// seasonal values for Fajr and Isha, with Dhuhr 5 and Maghrib 3 minutes later.
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
      CalculationParameters(
        fajr: .angle(17.7), isha: .angle(14), maghrib: .angle(4.5), nightSpan: .sunsetToFajr)
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
      CalculationParameters(
        fajr: .angle(20), isha: .angle(18), methodAdjustments: PrayerAdjustments(dhuhr: 1),
        rounding: .up)
    case .jakim:
      CalculationParameters(
        fajr: .angle(18), isha: .angle(18), methodAdjustments: PrayerAdjustments(dhuhr: 1))
    case .kemenag:
      CalculationParameters(
        fajr: .angle(20), isha: .angle(18), maghrib: .angle(1),
        methodAdjustments: PrayerAdjustments(
          fajr: 2, sunrise: -3, dhuhr: 3, asr: 2, maghrib: 2, isha: 2),
        rounding: .up)
    case .moonsightingCommittee:
      CalculationParameters(
        fajr: .moonsightingCommittee, isha: .moonsightingCommittee(.general),
        methodAdjustments: PrayerAdjustments(dhuhr: 5, maghrib: 3))
    }
  }
}
