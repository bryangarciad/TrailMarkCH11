import SwiftUI

struct AudioWaveformView: View {
    let samples: [Float] // Normalized 0..1
    let progress: Double
    let level: Float
    let isPlaying: Bool
    let onSeek: (Double) -> Void
    
    @State private var width: CGFloat = 0
    
    private let minimunBarheight: CGFloat = 2
    private let liveSpread = 4.0
    
    var body: some View {
        Canvas { context, size in
            let bars = barRects(in: size) // this will return 96 bars of X width Y height with padding and boost
            
            for rect in bars {
                context.fill(Path(roundedRect: rect, cornerRadius: rect.width / 2), with: .color(.secondary.opacity(0.35)))
            }
            
            var played = context
            played.clip(to: Path(
                CGRect(x: 0, y: 0, width: size.width * progress, height: size.height)
            ))
            
            for rect in bars {
                played.fill(Path(roundedRect: rect, cornerRadius: rect.width / 2), with: .color(.teal))
            }
        }
        // TODO: Remove this line and see what happens
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .contentShape(.rect)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in seek(toX: value.location.x) }
        )
    }
    
    private func barRects(in size: CGSize) -> [CGRect] {
        guard !samples.isEmpty, size.width > 0 else { return [] }
        
        let slot = size.width / CGFloat(samples.count)
        let barWidth = max(1, slot * 0.6)
        let playhead = progress * Double(samples.count)
        
        return samples.enumerated().map { index, sample in
            let amplitude = min(Double(sample) * boost(at: index, playhead: playhead), 1) // amp 0..1
            let height = max(minimunBarheight, amplitude * size.height)
            
            return CGRect(
                x: CGFloat(index) * slot + (slot - barWidth) / 2,
                y: (size.height - height) / 2,
                width: barWidth,
                height: height
            )
        }
    }
    
    private func boost(at index: Int, playhead: Double) -> Double {
        guard isPlaying else { return 1 }
        
        let distance = abs(Double(index) - playhead)
        
        guard distance < liveSpread else { return 1 }
        
        return 1 + Double(level) * 0.8 * (1 - distance / liveSpread)
    }
    
    private func seek(toX x: CGFloat) {
        guard width > 0 else { return }
        onSeek(min(max(Double(x / width), 0), 1))
    }
}

#Preview {
    AudioWaveformView(
        sample: (0..<96).map { abs(sin(Float($0) / 7)) * (0.35 + Float($0) / 140) },
        progress: 0.45,
        level: 0.7,
        isPlaying: true,
        onSeek: { _ in }
    )
    .frame(height: 88)
    .padding()
}
