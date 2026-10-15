import Foundation
import HealthKit
import Observation

@MainActor
@Observable
public final class HealthKitManager {

    public enum AuthorizationState: Equatable {
        case unknown
        case unavailable // Device can't use healthkit
        case requesting
        case authorized
        case denied
    }
    
    public private(set) var authorization: AuthorizationState = .unknown
    public private(set) var todaySummary: ActivitySummary = .empty

    private let store = HKHealthStore()
    
    public init() {
        // We will set the auth state unavailable at construct time if device
        // does not support
        if HKHealthStore.isHealthDataAvailable() {
            authorization = .unavailable
        }
    }
    
    private var stepType: HKQuantityType { HKQuantityType(.stepCount) }
    private var sleepType: HKCategoryType {
        HKCategoryType(.sleepAnalysis)
    }
    private var energyType: HKQuantityType {
        HKQuantityType(.activeEnergyBurned)
    }
    private var distanceType: HKQuantityType {
        HKQuantityType(.distanceWalkingRunning)
    }
    private var heartRateType: HKQuantityType { HKQuantityType(.heartRate) }
 
    private var readTypes: Set<HKObjectType> {
        [stepType, distanceType, energyType, heartRateType, sleepType, HKObjectType.workoutType()]
    }
    private var shareTypes: Set<HKSampleType> {
        [distanceType, energyType, HKObjectType.workoutType()]
    }
    
    // MARK: - Auth
    public func requestAuth() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorization = .unavailable
            return
        }
        authorization = .requesting
        do {
            try await store.requestAuthorization(
                toShare: shareTypes,
                read: readTypes
            )
            // Note: for privacy: IOS never tells us wheter read access
            // was granted. So, we treat "request completed" as authorized and
            // we let a zeroed health data stand in for the denied/empty case.
            authorization = .authorized
        } catch {
            authorization = .denied
        }
    }
    
    public func refreshTodaysSummary() async {
        guard authorization == .authorized else { return }
        
        let startOfDayToday = Calendar.current.startOfDay(for: Date())
        async let steps = sumQuantity(
            stepType, unit: .count(),
            since: startOfDayToday
        )
        async let distance = sumQuantity(
            distanceType,
            unit: .meter(), since: startOfDayToday
        )
        async let energy = sumQuantity(
            energyType,
            unit: .kilocalorie(),
            since: startOfDayToday
        )
        
        todaySummary = ActivitySummary(
            steps: await steps,
            distanceMeters: await distance,
            activeEnergyKcal: await energy,
            date: startOfDayToday
        )
    }
    
    private func sumQuantity(
        _ type: HKQuantityType,
        unit: HKUnit,
        since start: Date
    ) async -> Double {
        await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(
                withStart: start,
                end: Date()
            )

            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
            ) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            
            store.execute(query)
        }
    }
    
}
