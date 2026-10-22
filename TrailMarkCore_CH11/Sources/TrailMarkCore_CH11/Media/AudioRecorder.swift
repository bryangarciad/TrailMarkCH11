import Foundation
import AVFoundation
import Observation

// Delegator
@MainActor
@Observable
public final class AudioRecorder {
    public private(set) var isRecording = false
    public private(set) var elapsed: TimeInterval = 0
    
    public private(set) var lastRecordingURL: URL?
    
    private var recorder: AVAudioRecorder?
    private var startDate: Date?
    
    public init() {}
    
    private func configureRecordingSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.duckOthers]
        )
        try session.setActive(true)
    }
    
    public func start() throws {
        try configureRecordingSession()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100.0,// 44Mhz
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.record()
        
        self.startDate = Date()
        self.isRecording = true
        self.elapsed = 0
    }
    
    @discardableResult
    public func stop() -> (url: URL, duration: TimeInterval)? {
        guard let recorder else { return nil }
        let duration = startDate.map { Date().timeIntervalSince($0) }
        ?? recorder.currentTime
        recorder.stop()
        
        let url = recorder.url
        
        self.recorder = nil
        self.isRecording = false
        self.lastRecordingURL = url
        self.elapsed = duration
        
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: [.notifyOthersOnDeactivation]
        )
        
        return (url, duration)
    }
    
    //MARK: - UI Helpers
    public func tick() {
        guard isRecording, let startDate else { return }
        elapsed = Date().timeIntervalSince(startDate)
    }
}

