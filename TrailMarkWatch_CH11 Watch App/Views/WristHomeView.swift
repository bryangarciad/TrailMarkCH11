import SwiftUI
import TrailMarkCore_CH11

struct WristHomeView: View {
    @Environment(WatchModel.self) private var model

    // summary contains 3 props (steps, hearth and distance)
    private var summary: ActivitySummary {
        model.health.todaySummary
    }
    
    var body: some View {
        Section {
            
        }
    }
}


