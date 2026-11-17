import SwiftUI
import RitualKit

@main
struct WeeklyRitualsApp: App {
    @NSApplicationDelegateAdaptor(RitualAppDelegate.self) var delegate
    @StateObject private var store = RitualStore(period: .weekly)

    var body: some Scene {
        WindowGroup("Weekly Rituals") {
            RootView()
                .environmentObject(store)
                .frame(minWidth: 900, minHeight: 640)
        }
    }
}
