import TrailMarkCore_CH11
import SwiftUI

struct ContentView: View {
    @Environment(WatchModel.self) private var model
    
    var body: some View {
        NavigationStack {
            List {
                // Main Screen
            }
        }
        .navigationTitle("TrailMark WatchOS")
        .task {
            await model.health.requestAuth()
            await model.health.refreshTodaysSummary()
        }
    }
}

#Preview {
    ContentView()
}
