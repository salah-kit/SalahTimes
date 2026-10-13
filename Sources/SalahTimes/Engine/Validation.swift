import Foundation

/// Input checks (docs/algorithm.md, section 2), in the order the section lists them.
enum Validation {
  static func validate(
    coordinates: Coordinates, day: GregorianDay, parameters: CalculationParameters
  ) throws {
    guard coordinates.isValid else { throw CalculationError.invalidCoordinates }
    guard (1000...3000).contains(day.year) else { throw CalculationError.unsupportedDate }

    if case .angle(let angle) = parameters.fajr {
      try checkTwilightAngle(angle, name: "fajr.angle")
    }
    if case .angle(let angle) = parameters.isha {
      try checkTwilightAngle(angle, name: "isha.angle")
    }
    if case .angle(let angle) = parameters.maghrib {
      guard angle.isFinite, angle > 0, angle <= 30 else {
        throw CalculationError.invalidParameters(
          "maghrib.angle must be greater than 0 and at most 30 degrees, not \(angle)")
      }
    }
    if case .minutesAfterMaghrib(let minutes) = parameters.isha {
      guard (0...1440).contains(minutes) else {
        throw CalculationError.invalidParameters(
          "isha.minutesAfterMaghrib must be from 0 to 1440 minutes, not \(minutes)")
      }
    }
    if case .interval(let minutes, let hijriDayOffset) = parameters.ramadanIsha {
      guard (1...1440).contains(minutes) else {
        throw CalculationError.invalidParameters(
          "ramadanIsha.interval.minutes must be from 1 to 1440 minutes, not \(minutes)")
      }
      guard (-30...30).contains(hijriDayOffset) else {
        throw CalculationError.invalidParameters(
          "ramadanIsha.interval.hijriDayOffset must be from -30 to 30 days, not \(hijriDayOffset)"
        )
      }
    }
    try checkAdjustments(parameters.methodAdjustments, name: "methodAdjustments")
    try checkAdjustments(parameters.adjustments, name: "adjustments")
  }

  private static func checkTwilightAngle(_ angle: Double, name: String) throws {
    guard angle.isFinite, (1...30).contains(angle) else {
      throw CalculationError.invalidParameters(
        "\(name) must be from 1 to 30 degrees, not \(angle)")
    }
  }

  private static func checkAdjustments(_ adjustments: PrayerAdjustments, name: String) throws {
    let values: [(String, Int)] = [
      ("fajr", adjustments.fajr), ("sunrise", adjustments.sunrise),
      ("dhuhr", adjustments.dhuhr), ("asr", adjustments.asr),
      ("maghrib", adjustments.maghrib), ("isha", adjustments.isha),
    ]
    for (field, minutes) in values where !(-1440...1440).contains(minutes) {
      throw CalculationError.invalidParameters(
        "\(name).\(field) must be from -1440 to 1440 minutes, not \(minutes)")
    }
  }
}
