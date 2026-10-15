import Foundation
import Combine

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
    
    public init(
        id: UUID = UUID(),
        type: MemoType,
        fileName: String,
        createdAt: Date = Date(),
        duration: TimeInterval = 0,
        title: String = ""
    ) {
        self.id = id
        self.type = type
        self.fileName = fileName
        self.createdAt = createdAt
        self.duration = duration
        self.title = title
    }
    
    // MARK: - UI Display Helpers

    public var durationText: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(for: duration) ?? "00:00"
    }
}
