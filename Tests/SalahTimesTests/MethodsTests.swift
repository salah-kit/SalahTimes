import Foundation
import Testing

@testable import SalahTimes

/// The decoded form of `Vectors/methods.json`.
private struct MethodsFile: Decodable {
  let schemaVersion: Int
  let description: String
  let methods: [String: CalculationParameters]
  let sources: [String: [String]]
}

/// One entry of `Vectors/country-methods.json`.
private struct CountrySuggestion: Decodable {
  let method: String
  let source: String
}

/// The decoded form of `Vectors/country-methods.json`.
private struct CountryMethodsFile: Decodable {
  let schemaVersion: Int
  let description: String
  let suggestions: [String: CountrySuggestion]
}

/// The repository's `Vectors` directory, found from this file's path.
private func vectorsDirectory() -> URL {
  URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appendingPathComponent("Vectors")
}

private func decodeVector<T: Decodable>(_ type: T.Type, named name: String) throws -> T {
  let data = try Data(contentsOf: vectorsDirectory().appendingPathComponent(name))
  return try JSONDecoder().decode(type, from: data)
}

@Suite("Methods")
struct MethodsTests {
  @Test("methods.json lists exactly the enum's cases")
  func methodsFileListsEveryCase() throws {
    let file = try decodeVector(MethodsFile.self, named: "methods.json")
    #expect(file.schemaVersion == 1)
    #expect(Set(file.methods.keys) == Set(CalculationMethod.allCases.map(\.rawValue)))
    #expect(Set(file.sources.keys) == Set(file.methods.keys))
    for (method, urls) in file.sources {
      #expect(!urls.isEmpty, "\(method) has no source")
    }
  }

  @Test("Every preset equals its methods.json entry", arguments: CalculationMethod.allCases)
  func presetMatchesVector(method: CalculationMethod) throws {
    let file = try decodeVector(MethodsFile.self, named: "methods.json")
    let entry = try #require(file.methods[method.rawValue])
    #expect(method.parameters == entry)
  }

  @Test(
    "Every preset keeps the user's settings at their defaults",
    arguments: CalculationMethod.allCases)
  func presetDefaults(method: CalculationMethod) {
    let parameters = method.parameters
    #expect(parameters.adjustments == .zero)
    #expect(parameters.highLatitudeRule == .recommended)
    #expect(parameters.ramadanIsha == .off)
  }

  @Test("Suggestions equal country-methods.json")
  func suggestionsMatchVector() throws {
    let file = try decodeVector(CountryMethodsFile.self, named: "country-methods.json")
    #expect(file.schemaVersion == 1)
    let expected = try file.suggestions.mapValues { suggestion in
      try #require(CalculationMethod(rawValue: suggestion.method))
    }
    #expect(CalculationMethod.suggestionsByCountryCode == expected)
    for (code, suggestion) in file.suggestions {
      #expect(code.count == 2 && code == code.uppercased(), "\(code) isn't an alpha-2 code")
      #expect(!suggestion.source.isEmpty, "\(code) has no source")
    }
  }

  @Test("Suggestions ignore case and return nil for unknown codes")
  func suggestionLookup() {
    #expect(CalculationMethod.suggested(forCountryCode: "TR") == .diyanet)
    #expect(CalculationMethod.suggested(forCountryCode: "tr") == .diyanet)
    #expect(CalculationMethod.suggested(forCountryCode: "sG") == .muis)
    #expect(CalculationMethod.suggested(forCountryCode: "ZZ") == nil)
    #expect(CalculationMethod.suggested(forCountryCode: "") == nil)
    #expect(CalculationMethod.suggested(forCountryCode: "UK") == nil)
  }
}
