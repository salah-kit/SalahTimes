import Foundation

/// Computes prayer times as docs/algorithm.md specifies.
enum Engine {
  static func prayerTimes(
    coordinates: Coordinates, day: GregorianDay, timeZone: TimeZone,
    parameters: CalculationParameters
  ) throws -> PrayerTimes {
    // Placeholder until the engine lands; the public API compiles against it.
    throw CalculationError.invalidParameters("The engine isn't implemented yet")
  }
}
