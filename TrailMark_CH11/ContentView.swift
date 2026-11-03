import SwiftUI
import TrailMarkCore_CH11

struct ContentView: View {
    @Environment(AppModel.self) private var model
    
    var body: some View {
        TabView {
            TodayDashboardView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
        }
        .task {
            await model.health.requestAuth()
            await model.health.refreshTodaysSummary()
        }
    }
}
