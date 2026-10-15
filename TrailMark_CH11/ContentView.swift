//
//  ContentView.swift
//  TrailMark_CH11
//
//  Created by Ramses Garcia on 10/10/26.
//

import SwiftUI
import TrailMarkCore_CH11

struct ContentView: View {
    let empty = ActivitySummary()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
