import Foundation
import SalahTimes
import Testing

/// Runs the language-neutral vectors in `Vectors/` (see `Vectors/README.md`) against the engine.
@Suite("Vectors")
struct VectorTests {
  @Test("Every vector file loads")
  func everyFileLoads() {
    let catalog = Self.catalog
    for problem in catalog.problems {
      Issue.record(Comment(rawValue: problem))
    }
    #expect(catalog.fileCount >= 11)
    #expect(catalog.times.count >= 700)
    #expect(catalog.qibla.count >= 20)
    #expect(catalog.errors.count >= 20)
    let ids = catalog.times.map(\.id) + catalog.qibla.map(\.id) + catalog.errors.map(\.id)
    #expect(Set(ids).count == ids.count, "Vector ids are unique")
    for vector in catalog.times {
      #expect(
        Set(vector.expected.keys) == Set(PrayerTimes.Event.allCases),
        "\(vector.id) lists every event")
    }
  }

  @Test("Prayer times match the vectors", arguments: VectorTests.catalog.times)
  func prayerTimes(_ vector: TimeVector) throws {
    let timeZone = try #require(TimeZone(identifier: vector.timeZone), "\(vector.timeZone)")
    let times = try PrayerTimes(
      coordinates: vector.coordinates, day: vector.day, timeZone: timeZone,
      parameters: vector.parameters)
    for event in PrayerTimes.Event.allCases {
      guard let expected = vector.expected[event] else { continue }
      let actual = times[event]
      switch (expected, actual) {
      case (.occurs(let want), .occurs(let got)):
        let difference = got.timeIntervalSince(want)
        #expect(
          abs(difference) <= vector.toleranceSeconds,
          "\(vector.id) \(event.rawValue): expected \(want), got \(got) (\(difference) s)")
      default:
        #expect(actual == expected, "\(vector.id) \(event.rawValue)")
      }
    }
  }

  @Test("Calculations fail as the vectors expect", arguments: VectorTests.catalog.errors)
  func errors(_ vector: ErrorVector) throws {
    let timeZone = try #require(TimeZone(identifier: vector.timeZone), "\(vector.timeZone)")
    do {
      let times = try PrayerTimes(
        coordinates: vector.coordinates, day: vector.day, timeZone: timeZone,
        parameters: vector.parameters)
      Issue.record("\(vector.id): expected \(vector.error), got times for \(times.day)")
    } catch let error as CalculationError {
      #expect(Self.caseName(error) == vector.error, "\(vector.id): got \(error)")
    }
  }

  @Test("Qibla bearings match the vectors", arguments: VectorTests.catalog.qibla)
  func qibla(_ vector: QiblaVector) {
    let bearing = Qibla.direction(from: vector.coordinates)
    guard let expected = vector.bearing else {
      #expect(
        bearing == nil, "\(vector.id): expected no bearing, got \(String(describing: bearing))")
      return
    }
    guard let bearing else {
      Issue.record("\(vector.id): expected \(expected)°, got no bearing")
      return
    }
    // Compare on the circle, so 359.9999° and 0.0001° are close.
    var difference = (bearing - expected).truncatingRemainder(dividingBy: 360)
    if difference > 180 { difference -= 360 }
    if difference < -180 { difference += 360 }
    #expect(
      abs(difference) <= vector.toleranceDegrees,
      "\(vector.id): expected \(expected)°, got \(bearing)°")
  }

  private static func caseName(_ error: CalculationError) -> String {
    switch error {
    case .invalidCoordinates: "invalidCoordinates"
    case .invalidParameters: "invalidParameters"
    case .unsupportedDate: "unsupportedDate"
    }
  }
}

// MARK: - Loading

extension VectorTests {
  /// A prayer-time vector, resolved to the engine's types.
  struct TimeVector: Sendable, CustomTestStringConvertible {
    var id: String
    var day: GregorianDay
    var timeZone: String
    var coordinates: Coordinates
    var parameters: CalculationParameters
    var expected: [PrayerTimes.Event: EventTime]
    var toleranceSeconds: Double

    var testDescription: String { id }
  }

  /// A vector whose calculation must throw.
  struct ErrorVector: Sendable, CustomTestStringConvertible {
    var id: String
    var day: GregorianDay
    var timeZone: String
    var coordinates: Coordinates
    var parameters: CalculationParameters
    var error: String

    var testDescription: String { id }
  }

  /// A Qibla vector. `bearing` is `nil` when there's no direction.
  struct QiblaVector: Sendable, CustomTestStringConvertible {
    var id: String
    var coordinates: Coordinates
    var bearing: Double?
    var toleranceDegrees: Double

    var testDescription: String { id }
  }

  /// Every vector in `Vectors/`, plus the problems met while loading them.
  struct Catalog: Sendable {
    var times: [TimeVector] = []
    var errors: [ErrorVector] = []
    var qibla: [QiblaVector] = []
    var problems: [String] = []
    var fileCount = 0
  }

  static let catalog = loadCatalog()

  /// `Vectors/`, found from this file's path: `Tests/SalahTimesTests/VectorTests.swift`.
  static var vectorsDirectory: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("Vectors")
  }

  /// The decoder for parameters and coordinates. Non-finite numbers are written as strings.
  private static func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.nonConformingFloatDecodingStrategy = .convertFromString(
      positiveInfinity: "+Infinity", negativeInfinity: "-Infinity", nan: "NaN")
    return decoder
  }

  private static func loadCatalog() -> Catalog {
    var catalog = Catalog()
    let directory = vectorsDirectory
    let presets: [String: [String: Any]]
    do {
      presets = try loadPresets(directory.appendingPathComponent("methods.json"))
    } catch {
      catalog.problems.append("methods.json: \(error)")
      presets = [:]
    }
    let files: [URL]
    do {
      files = try vectorFiles(in: directory)
    } catch {
      catalog.problems.append("Can't list \(directory.path): \(error)")
      return catalog
    }
    for file in files {
      do {
        try load(file, presets: presets, into: &catalog)
        catalog.fileCount += 1
      } catch {
        catalog.problems.append("\(file.lastPathComponent): \(error)")
      }
    }
    return catalog
  }

  /// Every vector file: the `.json` files in `Vectors/` and `Vectors/times/`, except
  /// `methods.json`, which holds presets.
  private static func vectorFiles(in directory: URL) throws -> [URL] {
    var files: [URL] = []
    for folder in [directory, directory.appendingPathComponent("times")] {
      let names = try FileManager.default.contentsOfDirectory(atPath: folder.path)
      for name in names.sorted() where name.hasSuffix(".json") {
        if folder == directory && name == "methods.json" { continue }
        files.append(folder.appendingPathComponent(name))
      }
    }
    return files
  }

  /// The presets of `methods.json`, as JSON objects keyed by method name. A missing file gives
  /// no presets; vectors that name a method then fail to load.
  private static func loadPresets(_ url: URL) throws -> [String: [String: Any]] {
    guard FileManager.default.fileExists(atPath: url.path) else { return [:] }
    let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
    guard let root = object as? [String: Any] else { throw LoadError("not an object") }
    let methods = root["methods"] ?? root
    var presets: [String: [String: Any]] = [:]
    if let list = methods as? [[String: Any]] {
      for entry in list {
        guard let key = (entry["key"] ?? entry["id"] ?? entry["name"]) as? String,
          let parameters = entry["parameters"] as? [String: Any]
        else { throw LoadError("a method without a key or parameters") }
        presets[key] = parameters
      }
    } else if let map = methods as? [String: Any] {
      for (key, value) in map where key != "schemaVersion" && key != "description" {
        guard let entry = value as? [String: Any] else { continue }
        presets[key] = (entry["parameters"] as? [String: Any]) ?? entry
      }
    }
    return presets
  }

  private static func load(
    _ file: URL, presets: [String: [String: Any]], into catalog: inout Catalog
  ) throws {
    let object = try JSONSerialization.jsonObject(with: Data(contentsOf: file))
    guard let root = object as? [String: Any] else { throw LoadError("not an object") }
    guard root["schemaVersion"] as? Int == 1 else { throw LoadError("schemaVersion isn't 1") }
    guard let kind = root["kind"] as? String, let vectors = root["vectors"] as? [[String: Any]]
    else { throw LoadError("missing kind or vectors") }
    for vector in vectors {
      let id = vector["id"] as? String ?? "?"
      do {
        switch kind {
        case "prayerTimes":
          catalog.times.append(try timeVector(vector, id: id, presets: presets))
        case "calculationErrors":
          catalog.errors.append(try errorVector(vector, id: id))
        case "qibla":
          catalog.qibla.append(try qiblaVector(vector, id: id))
        default:
          throw LoadError("unknown kind \(kind)")
        }
      } catch {
        catalog.problems.append("\(file.lastPathComponent) \(id): \(error)")
      }
    }
  }

  private static func timeVector(
    _ vector: [String: Any], id: String, presets: [String: [String: Any]]
  ) throws -> TimeVector {
    let input = try object(vector["input"], "input")
    let expectedObject = try object(vector["expected"], "expected")
    var expected: [PrayerTimes.Event: EventTime] = [:]
    for (key, value) in expectedObject {
      guard let event = PrayerTimes.Event(rawValue: key) else {
        throw LoadError("unknown event \(key)")
      }
      expected[event] = try eventTime(value)
    }
    let tolerance = try number(vector["toleranceSeconds"], "toleranceSeconds")
    return TimeVector(
      id: id, day: try day(input), timeZone: try string(input["timeZone"], "timeZone"),
      coordinates: try coordinates(input),
      parameters: try parameters(input, presets: presets), expected: expected,
      toleranceSeconds: tolerance)
  }

  private static func errorVector(_ vector: [String: Any], id: String) throws -> ErrorVector {
    let input = try object(vector["input"], "input")
    let expected = try object(vector["expected"], "expected")
    return ErrorVector(
      id: id, day: try day(input), timeZone: try string(input["timeZone"], "timeZone"),
      coordinates: try coordinates(input), parameters: try parameters(input, presets: [:]),
      error: try string(expected["error"], "error"))
  }

  private static func qiblaVector(_ vector: [String: Any], id: String) throws -> QiblaVector {
    let input = try object(vector["input"], "input")
    let expected = try object(vector["expected"], "expected")
    let tolerance = try number(vector["toleranceDegrees"], "toleranceDegrees")
    var bearing: Double?
    if !(expected["bearing"] is NSNull) {
      bearing = try number(expected["bearing"], "bearing")
    }
    return QiblaVector(
      id: id, coordinates: try coordinates(input), bearing: bearing, toleranceDegrees: tolerance)
  }

  /// `parameters`, or the preset named by `method` with `parameters`' top-level keys replacing
  /// the preset's.
  private static func parameters(
    _ input: [String: Any], presets: [String: [String: Any]]
  ) throws -> CalculationParameters {
    var resolved = (input["parameters"] as? [String: Any]) ?? [:]
    if let method = input["method"] as? String {
      guard var preset = presets[method] else { throw LoadError("unknown method \(method)") }
      preset.merge(resolved) { _, override in override }
      resolved = preset
    }
    let data = try JSONSerialization.data(withJSONObject: resolved)
    return try makeDecoder().decode(CalculationParameters.self, from: data)
  }

  private static func coordinates(_ input: [String: Any]) throws -> Coordinates {
    let data = try JSONSerialization.data(withJSONObject: try object(input["coordinates"], "c"))
    return try makeDecoder().decode(Coordinates.self, from: data)
  }

  private static func day(_ input: [String: Any]) throws -> GregorianDay {
    let text = try string(input["date"], "date")
    guard let day = GregorianDay(text) else { throw LoadError("bad date \(text)") }
    return day
  }

  private static func eventTime(_ value: Any) throws -> EventTime {
    if let text = value as? String {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime]
      guard let date = formatter.date(from: text) else { throw LoadError("bad instant \(text)") }
      return .occurs(date)
    }
    let reasonText = try string(try object(value, "event")["doesNotOccur"], "doesNotOccur")
    guard let reason = NonOccurrence(rawValue: reasonText) else {
      throw LoadError("unknown reason \(reasonText)")
    }
    return .doesNotOccur(reason)
  }

  private static func object(_ value: Any?, _ name: String) throws -> [String: Any] {
    guard let object = value as? [String: Any] else { throw LoadError("\(name) isn't an object") }
    return object
  }

  private static func string(_ value: Any?, _ name: String) throws -> String {
    guard let text = value as? String else { throw LoadError("\(name) isn't a string") }
    return text
  }

  /// A JSON number. Linux's JSONSerialization gives `Int` for whole numbers, Darwin's gives
  /// `NSNumber`; both cast to one of these.
  private static func number(_ value: Any?, _ name: String) throws -> Double {
    if let number = value as? Double { return number }
    if let number = value as? Int { return Double(number) }
    throw LoadError("\(name) isn't a number")
  }

  private struct LoadError: Error, CustomStringConvertible {
    var description: String
    init(_ description: String) { self.description = description }
  }
}
