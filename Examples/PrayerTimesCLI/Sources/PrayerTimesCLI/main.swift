// Prints one day's prayer times for a place. From this directory:
//
//   swift run PrayerTimesCLI <latitude> <longitude> <time-zone> <method> [yyyy-mm-dd]
//
// For example, Istanbul today with Diyanet's method:
//
//   swift run PrayerTimesCLI 41.0082 28.9784 Europe/Istanbul diyanet

import Foundation
import SalahTimes

/// What an app stores for a place: where it is, its time zone and the calculation settings.
///
/// It's `nonisolated`, so it stays a plain value whatever the module's default isolation: an app
/// can encode it, compare it and hand it to a background task, as a widget or a scheduler does.
nonisolated struct PlaceSettings: Codable, Hashable, Sendable {
  var coordinates: Coordinates
  var timeZoneIdentifier: String
  var method: CalculationMethod
  var parameters: CalculationParameters

  /// The day's times, computed on whatever thread calls it.
  func times(on day: GregorianDay) throws -> PrayerTimes {
    guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
      throw CalculationError.invalidParameters("Unknown time zone \(timeZoneIdentifier)")
    }
    return try PrayerTimes(
      coordinates: coordinates, day: day, timeZone: timeZone, parameters: parameters)
  }
}

func fail(_ message: String) -> Never {
  let methods = CalculationMethod.allCases.map(\.rawValue).joined(separator: ", ")
  let usage = """
    \(message)

    Usage: PrayerTimesCLI <latitude> <longitude> <time-zone> <method> [yyyy-mm-dd]

      time-zone  An IANA identifier, such as Europe/Istanbul.
      method     One of: \(methods).
      yyyy-mm-dd The day. Defaults to today in the time zone.

    """
  FileHandle.standardError.write(Data(usage.utf8))
  exit(1)
}

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count == 4 || arguments.count == 5 else {
  fail("Expected four or five arguments.")
}
guard let latitude = Double(arguments[0]), let longitude = Double(arguments[1]) else {
  fail("The latitude and longitude must be numbers.")
}
guard let timeZone = TimeZone(identifier: arguments[2]) else {
  fail("Unknown time zone \(arguments[2]).")
}
guard let method = CalculationMethod(rawValue: arguments[3]) else {
  fail("Unknown method \(arguments[3]).")
}
let day: GregorianDay
if arguments.count == 5 {
  guard let parsed = GregorianDay(arguments[4]) else {
    fail("The day must be a date such as 2026-03-20.")
  }
  day = parsed
} else {
  day = GregorianDay(containing: Date(), in: timeZone)
}

// Store and restore the settings, as an app does between launches.
let settings = PlaceSettings(
  coordinates: Coordinates(latitude: latitude, longitude: longitude),
  timeZoneIdentifier: timeZone.identifier, method: method, parameters: method.parameters)
let restored: PlaceSettings
do {
  restored = try JSONDecoder().decode(
    PlaceSettings.self, from: try JSONEncoder().encode(settings))
} catch {
  fail("Can't store the settings: \(error)")
}
guard restored == settings else { fail("The settings changed when stored and restored.") }

// Compute away from the main actor, as a widget or a background task does.
let times: PrayerTimes
do {
  times = try await Task.detached { [restored, day] in try restored.times(on: day) }.value
} catch {
  fail("Can't compute prayer times: \(error)")
}

let formatter = DateFormatter()
formatter.locale = Locale(identifier: "en_US_POSIX")
formatter.timeZone = timeZone
formatter.dateFormat = "HH:mm"

print("\(day) in \(timeZone.identifier), \(method.rawValue)")
for event in PrayerTimes.Event.allCases {
  let name = event.rawValue.padding(toLength: 20, withPad: " ", startingAt: 0)
  switch times[event] {
  case .occurs(let date):
    // An event can fall on a neighboring civil day, such as an Isha after midnight.
    let civilDay = GregorianDay(containing: date, in: timeZone)
    let note = civilDay == day ? "" : " (\(civilDay))"
    print("\(name)\(formatter.string(from: date))\(note)")
  case .doesNotOccur(let reason):
    print("\(name)doesn't occur (\(reason.rawValue))")
  }
}

if let qibla = Qibla.direction(from: settings.coordinates) {
  print("Qibla \(String(format: "%.1f", qibla))° from true north")
}
