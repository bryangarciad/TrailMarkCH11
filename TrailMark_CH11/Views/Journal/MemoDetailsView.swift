import SwiftUI
import TrailMarkCore_CH11
import AVKit

struct MemoDetailsView: View {
    @Environment(AppModel.self) private var model
    
    let memo: MediaMemo
    
    @State private var audioPlayer = AudioPlayer()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch memo.type {
                case .video:
                    VideoPlayer(player: AVPlayer(
                        url: model.media.url(for: memo)
                    ))
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                case .audio:
                    audioControls
                }
            }
        }
    }
    
    private var audioControls: some View {
        VStack(spacing: 12) {
            waveform
                .frame(height: 88)
                .frame(maxWidth: .infinity)

            
            HStack {
                Text(timeString(audioPlayer.currentTime))
                Spacer()
                Text("-" + timeString(max(audioPlayer.duration - audioPlayer.currentTime, 0)))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
            
            Button {
                audioPlayer.isPlaying ?
                audioPlayer.pause() :
                audioPlayer.play(url: audioURL)
            } label: {
                Label(
                    audioPlayer.isPlaying ? "Pause" :  "Play",
                    systemImage: audioPlayer.isPlaying ?
                        "pause.circle.fill" :
                        "play.circle.fill"
                )
                .font(.title2)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            .background.secondary,
            in: RoundedRectangle(cornerRadius: 12)
        )
        .task(id: memo.id) {
            await audioPlayer.prepare(url: audioURL)
        }
        .task(id: audioPlayer.isPlaying) {
            while audioPlayer.isPlaying && !Task.isCancelled {
                audioPlayer.tick()
                try? await Task.sleep(for: .milliseconds(300))
            }
        }
    }
    
    @ViewBuilder
    private var waveform: some View {
        if audioPlayer.waveform.isEmpty {
            ZStack {
                Image(systemName: "waveform")
                    .font(.system(size: 44))
                    .foregroundStyle(.teal.opacity(0.4))
                    .symbolEffect(
                        .variableColor,
                        isActive: audioPlayer.isPlaying
                    )
                
                if audioPlayer.isLoadingWaveform {
                    ProgressView()
                }
            }
        }
        else {
            // TODO: Render the Actual AudioWaveFormComponent
        }
    }
    
    private var audioURL: URL {
        model.media.url(for: memo)
    }
    
    private func timeString(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        
        return String(format: "%02d:%02d", minutes, seconds) // 10:00
    }
}
