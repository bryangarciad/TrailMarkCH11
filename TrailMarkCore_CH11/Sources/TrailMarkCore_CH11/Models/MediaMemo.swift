import Foundation
import Combine
import CoreLocation


public enum MemoKind: String, Codable, Sendable, CaseIterable {
    case audio
    case video
    
    public var symbolName: String {
        switch self {
        case .audio: return "waveform"
        case .video: return "video.fill"
        }
    }
    
    public var displayName: String {
        switch self {
        case .audio: return "Voice Memo"
        case .video: return "Video Memo"
        }
    }
}


public struct MediaMemo: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public let kind: MemoKind
    public let fileName: String
    public let createdAt: Date
    public let duration: TimeInterval
    public let title: String
    
    public var latitude: Double?
    public var longitude: Double?
    
    public init(
        id: UUID = UUID(),
        kind: MemoKind,
        fileName: String,
        createdAt: Date = Date(),
        duration: TimeInterval = 0,
        title: String = "",
        longitude: Double? = nil,
        latitude: Double? = nil
    ) {
        self.id = id
        self.kind = kind
        self.fileName = fileName
        self.createdAt = createdAt
        self.duration = duration
        self.title = title
        self.longitude = longitude
        self.latitude = latitude
    }
    
    public var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public mutating func setCoordinate(_ coordinate: CLLocationCoordinate2D?) {
        latitude = coordinate?.latitude
        longitude = coordinate?.longitude
    }
    
    // MARK: - UI Display Helpers
    
    public var durationText: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second] // 00:00
        formatter.zeroFormattingBehavior = .pad // 01:30
        return formatter.string(from: duration) ?? "00:00"
    }
    
    private static func defaultTitle(for kind: MemoKind, at date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return "\(kind.displayName) - \(df.string(from: date))" // Voice Memo - 09/10
    }
}

