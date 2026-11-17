import SwiftUI
import RitualKit

@main
struct MonthlyRitualsApp: App {
    @NSApplicationDelegateAdaptor(RitualAppDelegate.self) var delegate
    @StateObject private var store = RitualStore(period: .monthly)

    var body: some Scene {
        WindowGroup("Monthly Rituals") {
            RootView()
                .environmentObject(store)
                .frame(minWidth: 900, minHeight: 640)
        }
    }
}
