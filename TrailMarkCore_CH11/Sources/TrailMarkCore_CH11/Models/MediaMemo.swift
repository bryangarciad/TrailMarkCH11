import Foundation
import Combine
import CoreLocation

public enum MemoType: String, Codable, Sendable, CaseIterable {
    case audio
    case video
    
    // MARK: - UI Helpers
    public var symbolName: String {
        switch self {
        case .audio: "waveform"
        case .video: "video.fill"
        }
    }
    
    public var displayName: String {
        switch self {
        case .audio: "Voice Memo"
        case .video: "Video Memo"
        }
    }
}

public struct MediaMemo: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public let type: MemoType
    public let duration: TimeInterval // Date 3:20 -- 03:20
    public let fileName: String
    public let title: String
    public let createdAt: Date
    
    public var latitude: Double?
    public var longitude: Double?
    
    public init(
        id: UUID = UUID(),
        type: MemoType,
        fileName: String,
        createdAt: Date = Date(),
        duration: TimeInterval = 0,
        title: String = "",
        longitude: Double? = nil,
        latitude: Double? = nil
    ) {
        self.id = id
        self.type = type
        self.fileName = fileName
        self.createdAt = createdAt
        self.duration = duration
        self.title = title
        self.longitude = longitude
        self.latitude = latitude
    }
    
    // MARK: - Coordinate Helpers
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
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(for: duration) ?? "00:00"
    }
}
