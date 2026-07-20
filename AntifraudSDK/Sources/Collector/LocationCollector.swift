import Foundation
import CoreLocation

class LocationCollector: NSObject, CLLocationManagerDelegate {
    static let shared = LocationCollector()

    private let locationManager = CLLocationManager()

    private override init() {
        super.init()
        locationManager.delegate = self
    }

    func getLocationInfo() -> LocationInfo {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            if let loc = locationManager.location {
                return LocationInfo(
                    latitude: loc.coordinate.latitude,
                    longitude: loc.coordinate.longitude,
                    accuracy: loc.horizontalAccuracy
                )
            }
        default:
            break
        }

        return LocationInfo(latitude: 0.0, longitude: 0.0, accuracy: 0.0)
    }
}
