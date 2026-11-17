// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RitualTrackers",
    platforms: [.macOS(.v13)],
    targets: [
        // Shared engine used by all three apps
        .target(name: "RitualKit", path: "Sources/RitualKit"),
        .executableTarget(name: "WeeklyRituals",  dependencies: ["RitualKit"], path: "Sources/WeeklyRituals"),
        .executableTarget(name: "MonthlyRituals", dependencies: ["RitualKit"], path: "Sources/MonthlyRituals"),
        .executableTarget(name: "YearlyRituals",  dependencies: ["RitualKit"], path: "Sources/YearlyRituals")
    ]
)
