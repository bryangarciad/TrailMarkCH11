
import SwiftUI

@main
struct TrailMark_CH11App: App {
    @State private var model = AppModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
        }
    }
}
