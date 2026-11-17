import SwiftUI
import RitualKit

@main
struct YearlyRitualsApp: App {
    @NSApplicationDelegateAdaptor(RitualAppDelegate.self) var delegate
    @StateObject private var store = RitualStore(period: .yearly)

    var body: some Scene {
        WindowGroup("Yearly Rituals") {
            RootView()
                .environmentObject(store)
                .frame(minWidth: 900, minHeight: 640)
        }
    }
}
