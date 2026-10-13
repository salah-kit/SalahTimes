extension CalculationMethod {
  /// A suggested method for a country, or `nil` when SalahTimes has no sourced suggestion.
  ///
  /// This is a starting point, not a ruling. Let users change it: mosques and communities in
  /// one country often follow different methods. METHODS.md gives the source for every entry,
  /// and corrections are welcome as issues labelled `calculation-method`.
  ///
  /// ```swift
  /// let method = CalculationMethod.suggested(forCountryCode: "TR")  // .diyanet
  /// ```
  ///
  /// - Parameter code: An ISO 3166-1 alpha-2 country code, in either case.
  /// - Returns: The suggested method, or `nil`.
  public static func suggested(forCountryCode code: String) -> CalculationMethod? {
    suggestionsByCountryCode[code.uppercased()]
  }

  /// Every suggestion, keyed by upper-case ISO 3166-1 alpha-2 country code.
  ///
  /// Each entry has a source in METHODS.md and `Vectors/country-methods.json`. A country is left
  /// out when no source supports a suggestion for it.
  public static let suggestionsByCountryCode: [String: CalculationMethod] = [
    "AE": .dubai,
    "AF": .karachi,
    "BD": .karachi,
    "BN": .muis,
    "CA": .moonsightingCommittee,
    "DZ": .muslimWorldLeague,
    "EG": .egyptian,
    "ID": .kemenag,
    "IN": .karachi,
    "IR": .tehran,
    "JO": .karachi,
    "KW": .kuwait,
    "MY": .jakim,
    "PK": .karachi,
    "QA": .qatar,
    "SA": .ummAlQura,
    "SG": .muis,
    "TN": .karachi,
    "TR": .diyanet,
    "US": .moonsightingCommittee,
  ]
}
