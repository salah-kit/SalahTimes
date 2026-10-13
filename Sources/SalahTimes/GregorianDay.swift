import Foundation

/// A day in the proleptic Gregorian calendar, without a time zone.
///
/// SalahTimes computes the events that belong to one civil day in a time zone. A
/// `GregorianDay` names that day; the time zone that gives it meaning is passed alongside it.
/// It's always a Gregorian date, whatever calendar the user reads it in.
///
/// ```swift
/// let day = GregorianDay(year: 2026, month: 3, day: 20)
/// let today = GregorianDay(containing: Date(), in: TimeZone(identifier: "Asia/Riyadh")!)
/// ```
///
/// Years use astronomical numbering, so year 0 is 1 BC. Its string form and its `Codable`
/// representation are the ISO 8601 calendar date, such as `"2026-03-20"`.
public struct GregorianDay: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
  /// The year, in astronomical numbering.
  public let year: Int

  /// The month, from 1 to 12.
  public let month: Int

  /// The day of the month, from 1 to 31.
  public let day: Int

  /// Creates a day, or returns `nil` if the month or the day doesn't exist.
  ///
  /// - Parameters:
  ///   - year: The year, in astronomical numbering.
  ///   - month: The month, from 1 to 12.
  ///   - day: The day of the month.
  public init?(year: Int, month: Int, day: Int) {
    guard (1...12).contains(month), day >= 1, day <= Self.daysInMonth(month, year: year) else {
      return nil
    }
    self.year = year
    self.month = month
    self.day = day
  }

  /// Creates the civil day that contains an instant in a time zone.
  ///
  /// - Parameters:
  ///   - date: The instant.
  ///   - timeZone: The time zone whose clock decides which day contains `date`.
  public init(containing date: Date, in timeZone: TimeZone) {
    let local = date.timeIntervalSince1970 + Double(timeZone.secondsFromGMT(for: date))
    self.init(daysSince1970: Int((local / 86_400).rounded(.down)))
  }

  /// Parses an ISO 8601 calendar date such as `"2026-03-20"`, or returns `nil`.
  ///
  /// The year has at least four digits. A year outside 0 to 9999 carries a sign, such as
  /// `"+10000-01-01"` or `"-0001-12-31"`.
  ///
  /// - Parameter string: The date to parse.
  public init?(_ string: String) {
    var text = Substring(string)
    var sign = 1
    var signed = false
    if let first = text.first, first == "+" || first == "-" {
      sign = first == "-" ? -1 : 1
      signed = true
      text = text.dropFirst()
    }
    let parts = text.split(separator: "-", omittingEmptySubsequences: false)
    guard parts.count == 3, parts[0].count >= 4, parts[1].count == 2, parts[2].count == 2,
      parts.allSatisfy({ $0.allSatisfy(\.isASCIIDigit) }),
      let magnitude = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2])
    else { return nil }
    let year = sign * magnitude
    guard signed || (0...9999).contains(year) else { return nil }
    self.init(year: year, month: month, day: day)
  }

  /// The day a number of days later, or earlier when `days` is negative.
  ///
  /// - Parameter days: The number of days to add.
  /// - Returns: The resulting day.
  public func adding(days: Int) -> GregorianDay {
    GregorianDay(daysSince1970: daysSince1970 + days)
  }

  /// The ISO 8601 calendar date, such as `"2026-03-20"`.
  public var description: String {
    let monthText = month < 10 ? "0\(month)" : "\(month)"
    let dayText = day < 10 ? "0\(day)" : "\(day)"
    let digits = String(abs(year))
    let padded = String(repeating: "0", count: max(0, 4 - digits.count)) + digits
    let yearText: String
    if (0...9999).contains(year) {
      yearText = padded
    } else {
      yearText = (year < 0 ? "-" : "+") + padded
    }
    return "\(yearText)-\(monthText)-\(dayText)"
  }

  public static func < (lhs: GregorianDay, rhs: GregorianDay) -> Bool {
    (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
  }

  /// Decodes a day from its ISO 8601 string, such as `"2026-03-20"`.
  ///
  /// - Parameter decoder: The decoder to read from.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let text = try container.decode(String.self)
    guard let day = GregorianDay(text) else {
      throw DecodingError.dataCorruptedError(
        in: container, debugDescription: "Expected an ISO 8601 date such as 2026-03-20: \(text)")
    }
    self = day
  }

  /// Encodes the day as its ISO 8601 string, such as `"2026-03-20"`.
  ///
  /// - Parameter encoder: The encoder to write to.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }
}

extension GregorianDay {
  /// Days from 1970-01-01 to this day.
  ///
  /// The conversions follow Howard Hinnant's public-domain `days_from_civil` and
  /// `civil_from_days` algorithms (https://howardhinnant.github.io/date_algorithms.html).
  var daysSince1970: Int {
    let y = month <= 2 ? year - 1 : year
    let era = (y >= 0 ? y : y - 399) / 400
    let yearOfEra = y - era * 400
    let shiftedMonth = month > 2 ? month - 3 : month + 9
    let dayOfYear = (153 * shiftedMonth + 2) / 5 + day - 1
    let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
    return era * 146_097 + dayOfEra - 719_468
  }

  init(daysSince1970 days: Int) {
    let z = days + 719_468
    let era = (z >= 0 ? z : z - 146_096) / 146_097
    let dayOfEra = z - era * 146_097
    let yearOfEra =
      (dayOfEra - dayOfEra / 1_460 + dayOfEra / 36_524 - dayOfEra / 146_096) / 365
    let dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra / 4 - yearOfEra / 100)
    let shiftedMonth = (5 * dayOfYear + 2) / 153
    let day = dayOfYear - (153 * shiftedMonth + 2) / 5 + 1
    let month = shiftedMonth < 10 ? shiftedMonth + 3 : shiftedMonth - 9
    self.year = yearOfEra + era * 400 + (month <= 2 ? 1 : 0)
    self.month = month
    self.day = day
  }

  /// The day's position in its year, from 1 to 366.
  var dayOfYear: Int {
    daysSince1970 - GregorianDay(january1Of: year).daysSince1970 + 1
  }

  /// Whether the day's year has 366 days.
  var isInLeapYear: Bool { Self.isLeapYear(year) }

  private init(january1Of year: Int) {
    self.year = year
    self.month = 1
    self.day = 1
  }

  static func isLeapYear(_ year: Int) -> Bool {
    (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
  }

  static func daysInMonth(_ month: Int, year: Int) -> Int {
    switch month {
    case 2: isLeapYear(year) ? 29 : 28
    case 4, 6, 9, 11: 30
    default: 31
    }
  }
}

extension Character {
  fileprivate var isASCIIDigit: Bool { ("0"..."9").contains(self) }
}
