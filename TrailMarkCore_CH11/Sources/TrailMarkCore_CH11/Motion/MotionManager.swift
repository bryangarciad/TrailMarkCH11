import Foundation
import CoreMotion
import Observation

@MainActor
@Observable
public final class MotionManager {
    
    public enum Activity: String, Sendable {
        case stationary, walking, running, cycling, automotive, unknown
        
        private var label: String { rawValue.capitalized }
        
        public var symbolName: String {
            switch self {
                case .stationary: return "figure.stand"
                case .walking: return "figure.walk"
                case .running: return "figure.run"
                case .cycling: return "bicycle"
                case .automotive: return "car"
                case .unknown: return "questionmark"
            }
        }
    }
    
    
    public private(set) var stepsToday: Int = 0
    public private(set) var cadence: Double = 0 // Steps Per Min
    public private(set) var activity: Activity?
    public private(set) var acceleration: (Double, Double, Double) = (0,0,0)
    
    private let pedometer = CMPedometer()
    private let activityManager = CMMotionActivityManager()
    private let motionManager = CMMotionManager()
        
    public init() {}
    
    // MARK: - Availability Checks
    public static var isPedometerAvailable: Bool {
        return CMPedometer.isStepCountingAvailable()
    }
    
    public static var isActivityAvailable: Bool {
        return CMMotionActivityManager.isActivityAvailable()
    }
    
    // MARK: - Data Access
    public func startPedometer() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        
        pedometer.startUpdates(from: Date()) { [weak self] data, err in
            guard let data else { return }
            
            let steps = data.numberOfSteps.intValue
            let cadence = (data.currentCadence?.doubleValue ?? 0) * 60
            
            Task { @MainActor in
                self?.stepsToday = steps
                self?.cadence = cadence
            }
        }
    }
    
    public func startActivityUpdate() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let activity else { return }
            
            let resolvedActivity: Activity
            
            if activity.walking { resolvedActivity = .walking }
            else if activity.running { resolvedActivity = .running }
            else if activity.cycling { resolvedActivity = .cycling }
            else if activity.automotive { resolvedActivity = .automotive }
            else if activity.stationary { resolvedActivity = .stationary }
            else { resolvedActivity = .unknown }
            
            self?.activity = resolvedActivity
        }
    }
    
    public func startAccelerometerUpdates() {
        guard motionManager.isDeviceMotionActive else { return }
        
        motionManager.deviceMotionUpdateInterval = 0.1
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                
            guard let data = motion?.userAcceleration else { return }
            
            self?.acceleration = (data.x, data.y, data.z)
        }
    }
    
    
}
