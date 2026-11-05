import Foundation
import AVFoundation
import Observation

@MainActor
@Observable
public final class AudioRecorder {
    public private(set) var isRecording = false
    public private(set) var elapsedTime: TimeInterval = 0
    public private(set) var lastRecordingURL: URL?
    
    private var recorder: AVAudioRecorder?
    private var startDate: Date?
    
    public init() {}
    
    public func start() throws {
        try configureSession()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        
        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.record()
        
        self.recorder = recorder
        self.startDate = Date()
        self.isRecording = true
        self.elapsedTime = 0
    }
    
    public func stop() -> (url: URL, duration: TimeInterval)? {
        guard let recorder else { return nil }
        
        let duration = startDate.map { Date().timeIntervalSince($0) } ?? recorder.currentTime
        recorder.stop()
        
        let url = recorder.url
        self.recorder = nil
        self.isRecording = false
        self.lastRecordingURL = url
        self.elapsedTime = duration
        
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        
        return (url, duration)
    }
    
    public func tick() {
        guard isRecording, let startDate else { return }
        elapsedTime = Date().timeIntervalSince(startDate)
    }
    
    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.duckOthers])
        try session.setActive(true)
    }
}
