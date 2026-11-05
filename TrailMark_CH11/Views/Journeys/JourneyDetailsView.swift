import SwiftUI
import MapKit
import TrailMarkCore_CH11

struct JourneyDetailsView: View {
    @Environment(AppModel.self) private var model

    let journey: Journey
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                map
                stats
                if let workout = journey.workout { workoutSection(workout) }
                memoSection
            }
            .padding()
        }
        .navigationTitle(journey.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var memos: [MediaMemo] {
        model.media.memos.filter { journey.memoIDs.contains($0.id) }
    }
    
    private var map: some View {
        Map(initialPosition: cameraPosition) {
            if !journey.track.isEmpty {
                MapPolyline(coordinates:  journey.track.coordinates)
                    .stroke(.orange, lineWidth: 4)
            }
            
            ForEach(memos) { memo in
                if let coordinate = memo.coordinate {
                    Marker(
                        memo.kind.displayName,
                        systemImage: memo.kind.symbolName,
                        coordinate: coordinate
                    )
                }
            }
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var cameraPosition: MapCameraPosition {
        if let firstCoordinate = journey.track.points.first {
            return MapCameraPosition.region(
                MKCoordinateRegion(
                    center: firstCoordinate.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            )
        }
        
        return MapCameraPosition.automatic
    }
    
    private var stats: some View {
        HStack {
            stat(
                "Distance",
                Measurement(value: journey.distanceMeters, unit: UnitLength.meters)
                    .formatted(.measurement(width: .abbreviated, usage: .road))
            )
            Divider()
            stat(
                "Memos",
                "\(journey.memoIDs.count)"
            )
            Divider()
            stat(
                "Date",
                journey.startedAt.formatted(date: .abbreviated, time: .omitted)
            )
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func workoutSection(_ workout: WorkoutRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Activity", systemImage: "figure.walk").font(.headline)
            LabeledContent("Duration", value: workout.durationText)
            LabeledContent("Active Energy", value: "\(Int(workout.activeEnergyKcal)) kcal")
            if let hr = workout.averageHeartRate {
                LabeledContent("Avg. Hearth Rate", value: "\(Int(hr)) bpm").font(.headline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private var memoSection: some View {
        if !memos.isEmpty {
            VStack(alignment: .leading) {
                Text("Captured algong the way").font(.headline)
                ForEach(memos) { memo in
                    NavigationLink(value: memo) { MemoRow(memo: memo) }
                }
            }
        }
    }
}
