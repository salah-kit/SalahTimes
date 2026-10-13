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

    // The central angle between the two places, by the haversine formula.
    let a =
      pow(sin((phi2 - phi1) / 2), 2) + cos(phi1) * cos(phi2) * pow(sin(deltaLambda / 2), 2)
    let centralAngle = 2 * atan2(sqrt(a), sqrt(max(0, 1 - a)))
    guard centralAngle > 1e-9, centralAngle < Double.pi - 1e-9 else { return nil }

    let y = sin(deltaLambda) * cos(phi2)
    let x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda)
    let bearing = degrees(atan2(y, x))
    let normalized = bearing.truncatingRemainder(dividingBy: 360)
    return normalized < 0 ? normalized + 360 : normalized
  }

  private static func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }
  private static func degrees(_ radians: Double) -> Double { radians * 180 / .pi }
}
