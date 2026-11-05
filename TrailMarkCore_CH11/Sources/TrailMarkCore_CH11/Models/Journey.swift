import Foundation

public struct Journey: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public let title: String
    public let startedAt: Date
    public let endedAt: Date?
    
    public var track: RouteTrack
    public var memoIDs: [UUID]
    
    public var workout: WorkoutRecord?
    
    public init(
        id: UUID = UUID(),
        title: String = "Untitled Journey",
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        track: RouteTrack = RouteTrack(),
        memoIDs: [UUID] = [],
        workout: WorkoutRecord? = nil
    ) {
        self.id = id
        self.title = title
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.track = track
        self.memoIDs = memoIDs
        self.workout = workout
    }
    
    // MARK: - UI Helpers
    
    public var dateText: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        
        return df.string(from: startedAt)
    }
    
    public var distanceMeters: Double {
        workout?.distanceMeters ?? track.distanceMeters
    }
}
