import Foundation
import CoreLocation

final class LocationService: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var locationHandler: ((LocationInfo?) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestCurrentLocation(_ completion: @escaping (LocationInfo?) -> Void) {
        self.locationHandler = completion
        if CLLocationManager.authorizationStatus() == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.requestLocation()
    }

    private func reverseGeocode(_ location: CLLocation, completion: @escaping (LocationInfo?) -> Void) {
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            let placemark = placemarks?.first
            let info = LocationInfo(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                name: placemark?.name,
                address: [placemark?.administrativeArea, placemark?.locality, placemark?.subLocality, placemark?.thoroughfare].compactMap { $0 }.joined(),
                city: placemark?.locality,
                country: placemark?.country
            )
            completion(info)
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { locationHandler?(nil); return }
        reverseGeocode(loc) { info in
            self.locationHandler?(info)
            self.locationHandler = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationHandler?(nil)
        locationHandler = nil
    }
}

struct LocationInfo {
    let latitude: Double
    let longitude: Double
    let name: String?
    let address: String?
    let city: String?
    let country: String?
}
