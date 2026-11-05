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
