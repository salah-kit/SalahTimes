/// A place on the Earth, in degrees.
///
/// Latitude is positive north of the equator, and longitude is positive east of the Greenwich
/// meridian. SalahTimes ignores the observer's elevation.
///
/// ```swift
/// let makkah = Coordinates(latitude: 21.4225, longitude: 39.8262)
/// ```
public struct Coordinates: Hashable, Codable, Sendable {
  /// Degrees north of the equator, from -90 to 90.
  public var latitude: Double

  /// Degrees east of the Greenwich meridian, from -180 to 180.
  public var longitude: Double

  /// Creates coordinates from a latitude and a longitude in degrees.
  ///
  /// The initializer doesn't check the values. A calculation throws
  /// ``CalculationError/invalidCoordinates`` when either value is out of range or not finite,
  /// and ``Qibla/direction(from:)`` returns `nil`.
  ///
  /// - Parameters:
  ///   - latitude: Degrees north of the equator, from -90 to 90.
  ///   - longitude: Degrees east of the Greenwich meridian, from -180 to 180.
  public init(latitude: Double, longitude: Double) {
    self.latitude = latitude
    self.longitude = longitude
  }

  /// Whether both values are finite and within their ranges.
  public var isValid: Bool {
    latitude.isFinite && longitude.isFinite && (-90...90).contains(latitude)
      && (-180...180).contains(longitude)
  }
}
