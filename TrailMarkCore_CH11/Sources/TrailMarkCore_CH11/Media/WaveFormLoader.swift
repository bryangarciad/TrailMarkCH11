import Foundation
import AVFoundation // AVAssetReader gives us the raw samples AVAudioPlayer won't
import Accelerate

/// Reduces an audio file down to a handful of amplitudes so the UI can draw a
/// waveform.
///
/// `AVAudioPlayer` only reports the level of whatever is playing *right now*, so
/// the overall shape of a recording has to be read off the file itself. We
/// decode the file to 16-bit PCM with `AVAssetReader`, fold the samples into RMS
/// readings, then bucket those down to one value per bar.
public enum WaveformLoader {
    /// Bars in a waveform. Enough detail to read a memo's shape at phone width.
    public static let defaultBarCount = 96

    /// Normalized (0...1) amplitudes for `url`, one per bar.
    ///
    /// Returns an empty array if the file can't be decoded — the UI treats that
    /// as "no waveform to draw" rather than an error worth putting on screen.
    public static func amplitudes(from url: URL, barCount: Int = defaultBarCount) async -> [Float] {
        #if os(watchOS)
        // AVAssetReader doesn't exist on watchOS, so there is no shape to draw
        // there. Callers get the same "no waveform" path as an undecodable file.
        return []
        #else
        // Decoding is blocking work, so keep it off whichever actor asked for it.
        return await Task.detached(priority: .userInitiated) {
            (try? await decode(url: url, barCount: barCount)) ?? []
        }.value
        #endif
    }
}

#if !os(watchOS)

extension WaveformLoader {
    /// Frames folded into a single RMS reading before bucketing. Small enough to
    /// keep short memos detailed, large enough to keep long ones cheap.
    private static var window: Int { 256 }

    // MARK: - Decoding

    private static func decode(url: URL, barCount: Int) async throws -> [Float] {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .audio).first else { return [] }

        let reader = try AVAssetReader(asset: asset)
        // Ask for plain interleaved PCM so we don't have to care what the file
        // was actually encoded as (memos are AAC, imported video may be anything).
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ])
        output.alwaysCopiesSampleData = false

        guard reader.canAdd(output) else { return [] }
        reader.add(output)
        reader.startReading()

        var readings: [Float] = []
        var pending: [Float] = []

        while reader.status == .reading, let sampleBuffer = output.copyNextSampleBuffer() {
            defer { CMSampleBufferInvalidate(sampleBuffer) }

            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }
            let byteCount = CMBlockBufferGetDataLength(blockBuffer)
            guard byteCount >= 2 else { continue }

            var pcm = [Int16](repeating: 0, count: byteCount / 2)
            let copied = pcm.withUnsafeMutableBytes { buffer in
                CMBlockBufferCopyDataBytes(blockBuffer,
                                           atOffset: 0,
                                           dataLength: byteCount,
                                           destination: buffer.baseAddress!)
            }
            guard copied == noErr else { continue }

            // The Int16 scale cancels out when we normalize by the peak at the
            // end, so there's no need to divide down to -1...1 here.
            var frames = [Float](repeating: 0, count: pcm.count)
            vDSP.convertElements(of: pcm, to: &frames)
            pending.append(contentsOf: frames)

            var offset = 0
            while offset + window <= pending.count {
                readings.append(vDSP.rootMeanSquare(pending[offset..<(offset + window)]))
                offset += window
            }
            pending.removeFirst(offset)
        }

        // A partial read would draw a waveform for only part of the memo, which
        // is worse than drawing none at all.
        guard reader.status != .failed else { return [] }

        if !pending.isEmpty {
            readings.append(vDSP.rootMeanSquare(pending))
        }

        return normalize(bucket(readings, into: barCount))
    }

    // MARK: - Shaping

    /// Collapses the RMS readings into exactly `barCount` values, taking the
    /// loudest reading in each bucket so transients survive. Also stretches
    /// short clips that produced fewer readings than we have bars.
    private static func bucket(_ readings: [Float], into barCount: Int) -> [Float] {
        guard barCount > 0 else { return [] }
        guard !readings.isEmpty else { return Array(repeating: 0, count: barCount) }

        return (0..<barCount).map { index in
            let start = index * readings.count / barCount
            let end = min(max(start + 1, (index + 1) * readings.count / barCount), readings.count)
            return readings[start..<end].max() ?? 0
        }
    }

    /// Scales the loudest bar to full height. The exponent lifts quiet passages
    /// into view — on a purely linear scale speech looks almost flat next to a
    /// single loud peak.
    private static func normalize(_ values: [Float]) -> [Float] {
        guard let peak = values.max(), peak > 0 else { return values }
        return values.map { min(pow($0 / peak, 0.7), 1) }
    }
}

#endif
