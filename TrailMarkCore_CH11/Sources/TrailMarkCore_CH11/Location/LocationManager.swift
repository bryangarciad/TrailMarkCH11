import Foundation
import CoreLocation // GPS related activity is done via core location
import Observation

@MainActor
@Observable
public final class LocationManager: NSObject {
    public internal(set) var authorizationStatus: CLAuthorizationStatus
    public internal(set) var currentLocation: CLLocation?
    public internal(set) var isLocationBeingRecorded = false
    
    public internal(set) var track = RouteTrack()
    
    private let manager = CLLocationManager()
    
    public override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
    }

    public var currentCoordinate: CLLocationCoordinate2D? {
        currentLocation?.coordinate
    }
    
    // MARK: - Authorization
    public func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
    
    public func requestOneShotLocation() {
        manager.requestLocation()
    }
    
    // MARK: - Recording a track
    public func startRecordingRoute() {
        isLocationBeingRecorded = true
        manager.startUpdatingLocation()
    }
    
    public func stopRecordingRoute() -> RouteTrack {
        isLocationBeingRecorded = false
        manager.stopUpdatingLocation()
        return track
    }
}

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

