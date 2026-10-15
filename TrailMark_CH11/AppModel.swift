import Foundation
import Observation
import TrailMarkCore_CH11

// Owns the long-lived managers and wires up cross-device sync. Injected into the
// SwiftUI environment so every screen shares one instance of each manager.
@MainActor
@Observable
final class AppModel {
    let health = HealthKitManager()


    init() {}
}

