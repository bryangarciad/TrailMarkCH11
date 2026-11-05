//
//  TrailMark_CH11App.swift
//  TrailMark_CH11
//
//  Created by Ramses Garcia on 05/09/26.
//

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
