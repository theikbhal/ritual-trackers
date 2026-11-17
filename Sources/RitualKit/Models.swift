import Foundation

enum Cal {
    /// Weeks run Sunday to Saturday.
    static let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 1
        return c
    }()
    static let keyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = cal
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    static func fmt(_ pattern: String, _ d: Date) -> String {
        let f = DateFormatter()
        f.calendar = cal
        f.dateFormat = pattern
        return f.string(from: d)
    }
}

public enum Period: String, Codable, CaseIterable {
    case weekly, monthly, yearly

    var noun: String {
        switch self {
        case .weekly: return "week"
        case .monthly: return "month"
        case .yearly: return "year"
        }
    }
    var title: String { rawValue.capitalized + " Rituals" }
    var thisLabel: String { "This \(noun)" }
    var component: Calendar.Component {
        switch self {
        case .weekly: return .weekOfYear
        case .monthly: return .month
        case .yearly: return .year
        }
    }
    var historyCount: Int {
        switch self {
        case .weekly: return 12
        case .monthly: return 12
        case .yearly: return 8
        }
    }
    func start(of d: Date) -> Date {
        Cal.cal.dateInterval(of: component, for: d)?.start ?? d
    }
    func add(_ n: Int, to d: Date) -> Date {
        Cal.cal.date(byAdding: component, value: n, to: d) ?? d
    }
    func key(_ d: Date) -> String { Cal.keyFormatter.string(from: start(of: d)) }

    func label(_ d: Date) -> String {
        switch self {
        case .weekly: return "Week of " + Cal.fmt("d MMM", d)
        case .monthly: return Cal.fmt("MMMM yyyy", d)
        case .yearly: return Cal.fmt("yyyy", d)
        }
    }
    func rangeText(_ d: Date) -> String {
        switch self {
        case .weekly:
            let s = start(of: d)
            let e = Cal.cal.date(byAdding: .day, value: 6, to: s) ?? s
            return Cal.fmt("d MMM", s) + " – " + Cal.fmt("d MMM yyyy", e)
        case .monthly: return Cal.fmt("MMMM yyyy", d)
        case .yearly: return Cal.fmt("yyyy", d)
        }
    }

    struct Idea: Identifiable {
        let id = UUID()
        let emoji: String, name: String, benefit: String
    }
    var ideas: [Idea] {
        switch self {
        case .weekly: return [
            Idea(emoji: "🥭", name: "Eat papaya", benefit: "Cheap vitamin C and fibre. Helps digestion and iron absorption. Kids love the sweetness."),
            Idea(emoji: "🍱", name: "Weekly meal plan", benefit: "Saves money and time, cuts food waste, and makes healthy eating easier."),
            Idea(emoji: "📞", name: "Call parents", benefit: "Keeps family bonds strong and brings comfort to everyone."),
            Idea(emoji: "🎲", name: "Family game night", benefit: "Screen-free time together builds memories and communication.")
        ]
        case .monthly: return [
            Idea(emoji: "💰", name: "Review family budget", benefit: "Spot overspending early and grow savings. 15 minutes a month beats a year-end surprise."),
            Idea(emoji: "🧹", name: "Deep clean the house", benefit: "Healthier air, fewer pests, calmer mind."),
            Idea(emoji: "💾", name: "Back up phone photos", benefit: "Never lose family memories to a lost or broken phone."),
            Idea(emoji: "⚖️", name: "Check weight and BP", benefit: "Tracking trends catches health issues early.")
        ]
        case .yearly: return [
            Idea(emoji: "🩺", name: "Annual health check-up", benefit: "Catches anaemia, sugar and BP problems early and gives a baseline to compare each year."),
            Idea(emoji: "🦷", name: "Dental check-up", benefit: "Prevents small cavities becoming expensive problems."),
            Idea(emoji: "🎯", name: "Review yearly goals", benefit: "Keeps your life pointed in the direction you chose."),
            Idea(emoji: "📄", name: "Renew insurance", benefit: "Avoids lapses in cover when you need it most.")
        ]
        }
    }
}

struct Ritual: Codable, Identifiable {
    var id = UUID()
    var name: String
    var emoji: String = "✅"
    var benefit: String = ""
    var notes: String = ""
    var reminderOn: Bool = true
    var reminderTime: Date = Ritual.nineAM
    var reminderWeekday: Int = 1     // weekly: 1 = Sunday
    var reminderDay: Int = 1         // monthly/yearly: day of month (1-28)
    var reminderMonth: Int = 1       // yearly: month
    var done: [String: String] = [:] // period key -> note for that period

    static var nineAM: Date {
        Cal.cal.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }

    func isDone(_ p: Period, _ d: Date) -> Bool { done[p.key(d)] != nil }

    mutating func set(_ p: Period, _ d: Date, _ on: Bool) {
        let k = p.key(d)
        if on { if done[k] == nil { done[k] = "" } } else { done[k] = nil }
    }

    /// Consecutive periods completed. The current period doesn't break
    /// the streak until it ends without being ticked.
    func streak(_ p: Period) -> Int {
        var d = p.start(of: Date())
        if !isDone(p, d) { d = p.add(-1, to: d) }
        var n = 0
        while isDone(p, d) { n += 1; d = p.add(-1, to: d) }
        return n
    }

    func best(_ p: Period) -> Int {
        let dates = done.keys.compactMap { Cal.keyFormatter.date(from: $0) }.sorted()
        var best = 0, run = 0
        var prev: Date?
        for d in dates {
            if let pr = prev, p.key(p.add(1, to: pr)) == p.key(d) { run += 1 } else { run = 1 }
            best = max(best, run)
            prev = d
        }
        return best
    }
}
