import Foundation
import Combine

public struct ActivitySummary: Sendable, Equatable, Codable {
    public var steps: Double
    public var distanceMeters: Double
    public var activeEnergyKcal: Double
    public var date: Date
    
    public init(
        steps: Double = 0,
        distanceMeteres: Double = 0,
        activeEnergyKcal: Double = 0,
        date: Date = Date()
    ) {
        self.steps = steps
        self.distanceMeters = distanceMeteres
        self.activeEnergyKcal = activeEnergyKcal
        self.date = date
    }
    
    public static let empty = ActivitySummary()
    
    // MARK: - UI Helpers To Display Data
    
    public var stepsText: String {
        Self.wholeNumber.string(from: NSNumber(value: steps)) ?? "00"
    }
    
    public var activeEnergyText: String {
        let value = Self.wholeNumber.string(from: NSNumber(value: activeEnergyKcal)) ?? "00"
        return "\(value) kcal"
    }
    
    public var distanceText: String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = 2
        let measurement = Measurement(value: distanceMeters, unit: UnitLength.meters)
        return formatter.string(from: measurement)
    }
    
    private static let wholeNumber: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()
}
