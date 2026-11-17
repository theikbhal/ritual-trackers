import Foundation
import SwiftUI

public final class RitualStore: ObservableObject {
    public let period: Period
    @Published var rituals: [Ritual] {
        didSet { save(); scheduleSoon() }
    }
    private var pending: DispatchWorkItem?

    public init(period: Period) {
        self.period = period
        let key = "rituals-\(period.rawValue)"
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([Ritual].self, from: data) {
            rituals = saved
        } else {
            rituals = RitualStore.starter(for: period)
        }
        save()
        scheduleSoon()
    }

    /// One starter ritual so the app is useful on first launch.
    static func starter(for p: Period) -> [Ritual] {
        switch p {
        case .weekly:
            return [Ritual(name: "Eat papaya", emoji: "🥭",
                           benefit: "Cheap (about ₹40-50/kg) vitamin C and fibre. Helps digestion and iron absorption (good with iron-rich meals for low iron). Naturally sweet for kids.",
                           notes: "1 kg for the family. Buy on Sunday.")]
        case .monthly:
            return [Ritual(name: "Review family budget", emoji: "💰",
                           benefit: "Spot overspending early and grow savings. 15 minutes a month beats a year-end surprise.")]
        case .yearly:
            return [Ritual(name: "Annual health check-up", emoji: "🩺",
                           benefit: "Catches problems like anaemia, sugar and BP early, and gives numbers to compare year over year.")]
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(rituals) {
            UserDefaults.standard.set(data, forKey: "rituals-\(period.rawValue)")
        }
    }

    private func scheduleSoon() {
        pending?.cancel()
        let w = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            Notifier.reschedule(self.rituals, period: self.period)
        }
        pending = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: w)
    }

    @discardableResult
    func add(name: String, emoji: String, benefit: String) -> UUID {
        let r = Ritual(name: name, emoji: emoji.isEmpty ? "✅" : emoji, benefit: benefit)
        rituals.append(r)
        return r.id
    }

    func delete(_ id: UUID) { rituals.removeAll { $0.id == id } }

    func set(_ id: UUID, on: Bool, date: Date = Date()) {
        guard let i = rituals.firstIndex(where: { $0.id == id }) else { return }
        rituals[i].set(period, date, on)
    }

    func binding(for id: UUID) -> Binding<Ritual>? {
        guard let first = rituals.first(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { self.rituals.first(where: { $0.id == id }) ?? first },
            set: { new in
                if let i = self.rituals.firstIndex(where: { $0.id == id }) { self.rituals[i] = new }
            })
    }
}
