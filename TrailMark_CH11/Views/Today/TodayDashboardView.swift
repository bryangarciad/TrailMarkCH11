import SwiftUI
import TrailMarkCore_CH11

struct TodayDashboardView: View {
    @Environment(AppModel.self) private var model
    
    var body: some View {
        NavigationStack {
            Group {
                switch model.health.currentAuthStatus {
                case .unavailable:
                    ContentUnavailableView(
                        "Health data unavailable",
                        systemImage: "hearth.slash",
                        description: Text("This device can't provide health data.")
                    )
                case .denied:
                    ContentUnavailableView {
                        Label("Health Access Needed", systemImage: "lock.fill")
                    } description: {
                        Text("Enable TrailMark access in the health app")
                    } actions: {
                        Button("Try again") {
                            Task {
                                await model.health.requestAuthorization()
                                await model.health.refreshTodaysSummary()
                            }
                        }
                    }
                default:
                    summary
                }
            }
            .navigationTitle("Todays Data")
            .task { await model.health.refreshTodaysSummary() }
            .refreshable { await model.health.refreshTodaysSummary() }
        }
    }
    
    private var summary: some View {
        ScrollView {
            VStack(spacing: 16) {
                MetricCard(
                    title: "Steps",
                    value: model.health.todaysSummary.stepsText,
                    symbol: "figure.walk",
                    tint: .orange
                )
                MetricCard(
                    title: "Distance",
                    value: model.health.todaysSummary.distanceText,
                    symbol: "figure.walk",
                    tint: .teal
                )
                MetricCard(
                    title: "Active Energy",
                    value: model.health.todaysSummary.activeEnergyText,
                    symbol: "flame.fill",
                    tint: .red
                )
            }
            .padding()
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.title)
                .foregroundStyle(tint)
                .frame(width: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .contentTransition(.numericText())
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }
}
