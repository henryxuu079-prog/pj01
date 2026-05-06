import CoreLocation

final class LocationService {
    static let shared = LocationService()

    private let geocoder = CLGeocoder()

    func reverseGeocode(latitude: Double, longitude: Double) async -> String? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let placemarks = try? await geocoder.reverseGeocodeLocation(location)
        return placemarks?.first?.locality ?? placemarks?.first?.administrativeArea
    }
}
