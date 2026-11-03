import Foundation

public struct WorkoutRecord: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public let start: Date
    public let end: Date
    
    public var activeEnergyKcal: Double
    public var distanceMeters: Double
    public var avgHeartRate: Double?
    
    public init(
        id: UUID = UUID(),
        start: Date,
        end: Date,
        activeEnergyKcal: Double = 0,
        distanceMeters: Double = 0,
        avgHeartRate: Double? = nil
    ) {
        self.id = id
        self.start = start
        self.end = end
        self.activeEnergyKcal = activeEnergyKcal
        self.distanceMeters = distanceMeters
        self.avgHeartRate = avgHeartRate
    }
    
    // MARK: - UI Helpers
    public var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
    
    public var durationText: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(for: duration) ?? "00:00"
    }
    
}
