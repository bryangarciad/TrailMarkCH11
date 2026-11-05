import Foundation

/// Last night's sleep, distilled to a single duration.
public struct SleepSummary: Sendable, Equatable, Codable {
    /// Total time asleep last night, in seconds.
    public var asleepSeconds: TimeInterval
    /// The night these figures describe (the morning's date).
    public var date: Date

    public init(asleepSeconds: TimeInterval = 0, date: Date = Date()) {
        self.asleepSeconds = asleepSeconds
        self.date = date
    }

    public static let empty = SleepSummary()

    // MARK: - UI Display Helpers

    public var hours: Double { asleepSeconds / 3600 }

    public var durationText: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short // 7 hr 12 min
        return formatter.string(from: asleepSeconds) ?? "—"
    }
}

/// One day's active-energy total, for the 7-day trend chart.
public struct EnergyTrendPoint: Sendable, Equatable, Codable, Identifiable {
    public var id: Date { day }
    /// Start of the day.
    public var day: Date
    /// Active energy burned that day, in kilocalories.
    public var activeEnergyKcal: Double

    public init(day: Date, activeEnergyKcal: Double) {
        self.day = day
        self.activeEnergyKcal = activeEnergyKcal
    }
}

/// Live, frequently-updating vitals. The model lands here in Session 1.3; the
/// anchored queries that feed it come later, with the watch app.
public struct LiveVitals: Sendable, Equatable, Codable {
    /// Most recent heart rate, in beats per minute.
    public var heartRateBPM: Double
    /// Steps so far today.
    public var steps: Double
    /// Active energy burned so far today, in kilocalories.
    public var activeEnergyKcal: Double

    public init(heartRateBPM: Double = 0, steps: Double = 0, activeEnergyKcal: Double = 0) {
        self.heartRateBPM = heartRateBPM
        self.steps = steps
        self.activeEnergyKcal = activeEnergyKcal
    }

    public static let empty = LiveVitals()

    // MARK: - UI Display Helpers

    public var heartRateText: String {
        heartRateBPM > 0 ? "\(Int(heartRateBPM.rounded()))" : "—"
    }
}
