import Foundation

/// The direction of the Kaaba.
///
/// ```swift
/// let london = Coordinates(latitude: 51.5072, longitude: -0.1276)
/// let bearing = Qibla.direction(from: london)  // about 119° from true north
/// ```
public enum Qibla {
  /// The Kaaba's coordinates that the direction points to.
  public static let kaaba = Coordinates(latitude: 21.4225241, longitude: 39.8261818)

  /// The direction of the Kaaba from a place, in degrees clockwise from true north.
  ///
  /// This is the initial bearing of the great circle to the Kaaba, on a spherical Earth. It's
  /// relative to true north, not magnetic north.
  ///
  /// - Parameter coordinates: The place.
  /// - Returns: A bearing from 0 up to 360, or `nil` when the coordinates aren't valid, or at the
  ///   Kaaba itself or its antipode, where no single direction exists.
  public static func direction(from coordinates: Coordinates) -> Double? {
    guard coordinates.isValid else { return nil }
    let phi1 = radians(coordinates.latitude)
    let phi2 = radians(kaaba.latitude)
    let deltaLambda = radians(kaaba.longitude - coordinates.longitude)

    // The central angle between the two places, from their unit vectors. Unlike the haversine
    // formula, it keeps its precision near the antipode (docs/algorithm.md, section 10).
    let place = unitVector(latitude: coordinates.latitude, longitude: coordinates.longitude)
    let target = unitVector(latitude: kaaba.latitude, longitude: kaaba.longitude)
    let cross = (
      place.y * target.z - place.z * target.y,
      place.z * target.x - place.x * target.z,
      place.x * target.y - place.y * target.x
    )
    let crossLength = sqrt(cross.0 * cross.0 + cross.1 * cross.1 + cross.2 * cross.2)
    let dot = place.x * target.x + place.y * target.y + place.z * target.z
    let centralAngle = atan2(crossLength, dot)
    guard centralAngle > 1e-9, centralAngle < Double.pi - 1e-9 else { return nil }

    let y = sin(deltaLambda) * cos(phi2)
    let x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda)
    // normalize360 maps a tiny negative bearing to 0, not to 360 (section 1).
    return normalize360(degrees(atan2(y, x)))
  }

  /// The unit vector `(cos φ cos L, cos φ sin L, sin φ)` of a place, from degrees.
  private static func unitVector(latitude: Double, longitude: Double) -> (
    x: Double, y: Double, z: Double
  ) {
    let phi = radians(latitude)
    let lambda = radians(longitude)
    return (cos(phi) * cos(lambda), cos(phi) * sin(lambda), sin(phi))
  }

  private static func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }
  private static func degrees(_ radians: Double) -> Double { radians * 180 / .pi }
}
