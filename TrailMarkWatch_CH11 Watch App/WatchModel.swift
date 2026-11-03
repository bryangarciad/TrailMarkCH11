import Foundation
import Observation
import TrailMarkCore_CH11

@MainActor
@Observable
final class WatchModel {
    let health = HealthKitManager()
    
    init() {}
}
