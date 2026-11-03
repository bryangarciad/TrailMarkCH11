// a Macro starts always with #, and is an instruction to XCode not swift
#if os(watchOS)
import Foundation
import HealthKit
import Observation

@MainActor
@Observable
public final class WorkoutSessionManager: NSObject {
    public private(set) var isWorkoutRunning: Bool = false
    
    // For a Hike type of workout the health data that is relevant
    // is the heart rate, energy consumed, and distance
    //
    public private(set) var heartRate: Double = 0.0
    public private(set) var activeEnergy: Double = 0.0
    public private(set) var distanceMeters: Double = 0.0
    public private(set) var startDate: Date?
    
    public private(set) var journeyID: UUID?
    
    public var onFinish: ((WorkoutRecord) -> Void)?
    
    public let store = HKHealthStore()
    // This is the obj that represents the workout session
    public var session: HKWorkoutSession?
    // This is the interface that allows us to build a workout
    public var builder: HKLiveWorkoutBuilder?
    
    
    private let bpmUnit = HKUnit.count().unitDivided(by: .minute())
    
    public override init() { super.init() }
    
    public var elapsed: TimeInterval {
        guard let startDate else { return 0 }
        return Date().timeIntervalSince(startDate)
    }
    
    // MARK: - Auth
    public func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
            
        var energyType: HKQuantityType = HKQuantityType(.activeEnergyBurned)
        var distanceType: HKQuantityType = HKQuantityType(.distanceWalkingRunning)
        var heartRateType: HKQuantityType = HKQuantityType(.heartRate)
        
        try? await store.requestAuthorization(
            toShare: [HKObjectType.workoutType(), energyType, distanceType],
            read: [heartRateType, energyType, distanceType]
        )
    }
    
    
    public func reset() {
        isWorkoutRunning = false
        journeyID = nil
        session = nil
        builder = nil
    }
    
    // MARK: - Start Workout
    
    public func start(journeyID: UUID? = nil) {
        if let journeyID, self.journeyID == nil {
            self.journeyID = journeyID
        }
        
        guard session == nil else { return }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .hiking
        configuration.locationType = .outdoor
        
        do {
            let session = try HKWorkoutSession(
                healthStore: store,
                configuration: configuration
            )
            let builder = session.associatedWorkoutBuilder()
            
            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: store,
                workoutConfiguration: configuration
            )
            
            session.delegate = self
            builder.delegate = self
            
            self.session = session
            self.builder = builder
            
            let now = Date()
            
            startDate = now
            heartRate = 0
            activeEnergy = 0
            distanceMeters = 0
            
            session.startActivity(with: now)
            builder.beginCollection(withStart: now) { [weak self] success, _ in
                Task { @MainActor in
                    if success {
                        self?.isWorkoutRunning = true
                    } else {
                        self?.reset()
                    }
                }
            }
        } catch {
            reset()
        }
    }
    

    // MARK: - Stop Session and Workout

    public func end() {
        guard let session, let builder else { return }
        let endDate = Date()
        session.end()
        builder.endCollection(withEnd: endDate) { [weak self] _, _ in
            Task { @MainActor in self?.finishWorkout(end: endDate) }
        }
    }
    
    private func finishWorkout(end: Date) {
        builder?.finishWorkout { [weak self] _, _ in
            Task { @MainActor in self?.finalize(end: end) }
        }
    }
    
    private func finalize(end: Date) {
        let avgBPM = builder?.statistics(
            for: HKQuantityType(.heartRate)
        )?.averageQuantity()?.doubleValue(for: bpmUnit)
        
        let record = WorkoutRecord(
            start: startDate ?? end,
            end: end,
            activeEnergyKcal: activeEnergy,
            distanceMeters:  distanceMeters,
            avgHeartRate:  avgBPM ?? (heartRate > 0 ? heartRate : nil)
        )
        reset()
        onFinish?(record)
    }
    
}


// MARK: - Session And Workout Builder Delegate
extension WorkoutSessionManager: HKWorkoutSessionDelegate {
    nonisolated public func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor in
            self.isWorkoutRunning = toState == .running // true when new stae is running
        }
    }

    nonisolated public func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: any Error
    ) {
        Task { @MainActor in self.reset() }
    }
}

extension WorkoutSessionManager: HKLiveWorkoutBuilderDelegate {
    nonisolated public func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            // This guard is checking the current type is quantity and contains statistcis
            guard let quantityType = type as? HKQuantityType,
                  let statistics = workoutBuilder.statistics(for: quantityType) else { continue }
            
            switch quantityType {
            case HKQuantityType(.heartRate):
                let bpm = statistics.mostRecentQuantity()?.doubleValue(for: bpmUnit) ?? 0.0
                Task { @MainActor in self.heartRate = bpm }
            case HKQuantityType(.activeEnergyBurned):
                let kcal = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0.0
                Task { @MainActor in self.activeEnergy = kcal }
            case HKQuantityType(.distanceWalkingRunning):
                let distance = statistics.sumQuantity()?.doubleValue(for: .meter()) ?? 0.0
                Task { @MainActor in self.distanceMeters = distance }
            default:
                break
            }
        }
        
    }

    nonisolated public func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
#endif
