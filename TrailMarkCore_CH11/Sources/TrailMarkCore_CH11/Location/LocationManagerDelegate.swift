import Foundation
import CoreLocation // GPS related activity is done via core location
import Observation

extension LocationManager: CLLocationManagerDelegate {
    nonisolated public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }
    
    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let points = locations.map(TrackPoint.init(location:))
        Task { @MainActor in
            self.currentLocation = locations.last
            
            if self.isLocationBeingRecorded {
                self.track.points.append(contentsOf: points)
            }
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        // Location failures are common but transient; most of the time doing nothing is fine
        // but you may want to implement better errror handling than proffesor Ramses
        // cause he is a little lazy
    }
}
