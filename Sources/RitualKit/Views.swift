import SwiftUI
import AppKit

public struct RootView: View {
    @EnvironmentObject var store: RitualStore
    @State private var selection: Selection? = .overview
    @State private var showAdd = false

    public init() {}

    enum Selection: Hashable { case overview, help, ritual(UUID) }

    public var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("Overview", systemImage: "checklist").tag(Selection.overview)
                Section("Rituals") {
                    ForEach(store.rituals) { r in
                        HStack {
                            Text(r.emoji)
                            Text(r.name).lineLimit(1)
                            Spacer()
                            if r.streak(store.period) > 0 {
                                Text("🔥\(r.streak(store.period))").font(.caption)
                            }
                        }
                        .tag(Selection.ritual(r.id))
                    }
                }
                Label("Help", systemImage: "questionmark.circle").tag(Selection.help)
            }
            .navigationSplitViewColumnWidth(min: 210, ideal: 240)
            .toolbar {
                ToolbarItem {
                    Button { showAdd = true } label: { Label("Add ritual", systemImage: "plus") }
                }
            }
        } detail: {
            switch selection ?? .overview {
            case .overview: OverviewView()
            case .help: HelpView()
            case .ritual(let id): RitualDetailView(id: id, onDeleted: { selection = .overview }).id(id)
            }
        }
        .sheet(isPresented: $showAdd) {
            AddRitualSheet { name, emoji, benefit in
                let id = store.add(name: name, emoji: emoji, benefit: benefit)
                selection = .ritual(id)
            }
        }
    }
}

// MARK: Add sheet
struct AddRitualSheet: View {
    @EnvironmentObject var store: RitualStore
    @Environment(\.dismiss) private var dismiss
    let onAdd: (String, String, String) -> Void
    @State private var name = ""
    @State private var emoji = "✅"
    @State private var benefit = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("New \(store.period.rawValue) ritual").font(.title2.bold())

            Text("Quick ideas").font(.caption).foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(store.period.ideas) { i in
                        Button("\(i.emoji) \(i.name)") { name = i.name; emoji = i.emoji; benefit = i.benefit }
                    }
                }
            }

            HStack {
                TextField("Emoji", text: $emoji).frame(width: 60)
                TextField("Name (e.g. Eat papaya)", text: $name)
            }
            Text("Benefit: why does this matter?").font(.caption).foregroundStyle(.secondary)
            TextEditor(text: $benefit)
                .frame(height: 90)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.3)))

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Add") {
                    onAdd(name.trimmingCharacters(in: .whitespaces), emoji, benefit)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(22)
        .frame(width: 480)
    }
}

// MARK: Overview
struct OverviewView: View {
    @EnvironmentObject var store: RitualStore

    var body: some View {
        let p = store.period
        let now = Date()
        let total = store.rituals.count
        let doneCount = store.rituals.filter { $0.isDone(p, now) }.count

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(p.title).font(.largeTitle.bold())
                Text("\(p.thisLabel) · \(p.rangeText(now))").foregroundStyle(.secondary)

                if total == 0 {
                    Text("No rituals yet. Click + to add one.").foregroundStyle(.secondary)
                } else {
                    HStack {
                        ProgressView(value: Double(doneCount), total: Double(total))
                        Text("\(doneCount) of \(total) done").font(.callout)
                    }
                    ForEach(store.rituals) { r in
                        HStack(alignment: .top, spacing: 12) {
                            Toggle(isOn: Binding(
                                get: { r.isDone(p, now) },
                                set: { store.set(r.id, on: $0) })) { EmptyView() }
                                .toggleStyle(.checkbox)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(r.emoji) \(r.name)").font(.headline)
                                if !r.benefit.isEmpty {
                                    Text(r.benefit).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                }
                            }
                            Spacer()
                            Text("🔥 \(r.streak(p))").font(.callout)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
                    }
                }
            }
            .padding(26)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: Ritual detail
struct RitualDetailView: View {
    @EnvironmentObject var store: RitualStore
    let id: UUID
    let onDeleted: () -> Void

    var body: some View {
        if let b = store.binding(for: id) {
            DetailBody(ritual: b, onDelete: { store.delete(id); onDeleted() })
        } else {
            Text("This ritual was deleted.").foregroundStyle(.secondary)
        }
    }
}

struct StatCard: View {
    let title: String, value: String, sub: String
    var body: some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(size: 30, weight: .bold, design: .rounded))
            Text(sub).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.gray.opacity(0.1)))
    }
}

struct DetailBody: View {
    @EnvironmentObject var store: RitualStore
    @Binding var ritual: Ritual
    let onDelete: () -> Void
    @State private var confirmDelete = false

    var body: some View {
        let p = store.period
        let now = Date()
        let done = ritual.isDone(p, now)
        let periods = (0..<p.historyCount).map { p.add(-$0, to: p.start(of: now)) }

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    TextField("Emoji", text: $ritual.emoji).textFieldStyle(.plain).font(.largeTitle).frame(width: 56)
                    TextField("Name", text: $ritual.name).textFieldStyle(.plain).font(.largeTitle.bold())
                }

                // Big checkbox for the current period
                Button { ritual.set(p, now, !done) } label: {
                    HStack(spacing: 16) {
                        Image(systemName: done ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 50))
                            .foregroundStyle(done ? .green : .secondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(done ? "Done \(p.thisLabel.lowercased())!" : "Done \(p.thisLabel.lowercased())?").font(.title2.bold())
                            Text(p.rangeText(now)).foregroundStyle(.secondary)
                            Text("Click to \(done ? "uncheck" : "check")").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 16).fill(done ? Color.green.opacity(0.15) : Color.orange.opacity(0.12)))
                }
                .buttonStyle(.plain)

                // Streaks
                HStack(spacing: 14) {
                    StatCard(title: "Streak 🔥", value: "\(ritual.streak(p))", sub: p.noun + "s")
                    StatCard(title: "Best", value: "\(ritual.best(p))", sub: p.noun + "s")
                    StatCard(title: "Total done", value: "\(ritual.done.count)", sub: "times")
                }

                // Benefit
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        TextEditor(text: $ritual.benefit).frame(minHeight: 70)
                        Button("Ask AI about the benefits") {
                            let q = "Explain in simple terms the benefits of making '\(ritual.name)' a \(p.rawValue) habit for a family. Include practical tips to stay consistent, ideas to make it fun for kids, and any cautions."
                            var c = URLComponents(string: "https://claude.ai/new")!
                            c.queryItems = [URLQueryItem(name: "q", value: q)]
                            if let url = c.url { NSWorkspace.shared.open(url) }
                        }
                    }.padding(6)
                } label: { Label("Why / Benefit", systemImage: "heart.text.square") }

                // Notes
                GroupBox {
                    TextEditor(text: $ritual.notes).frame(minHeight: 80).padding(6)
                } label: { Label("Notes", systemImage: "note.text") }

                // History with per-period notes
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(periods, id: \.self) { d in
                            HStack {
                                Toggle(isOn: Binding(
                                    get: { ritual.isDone(p, d) },
                                    set: { ritual.set(p, d, $0) })) {
                                    Text(p.label(d)).frame(width: 150, alignment: .leading)
                                }
                                .toggleStyle(.checkbox)
                                if ritual.isDone(p, d) {
                                    TextField("Note for this \(p.noun)…", text: Binding(
                                        get: { ritual.done[p.key(d)] ?? "" },
                                        set: { if ritual.done[p.key(d)] != nil { ritual.done[p.key(d)] = $0 } }))
                                }
                            }
                        }
                    }.padding(6)
                } label: { Label("History (check, uncheck, add notes)", systemImage: "calendar") }

                // Reminder
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Remind me", isOn: $ritual.reminderOn)
                        if ritual.reminderOn {
                            DatePicker("Time", selection: $ritual.reminderTime, displayedComponents: .hourAndMinute)
                            switch p {
                            case .weekly:
                                Picker("Day", selection: $ritual.reminderWeekday) {
                                    ForEach(1...7, id: \.self) { Text(Calendar.current.weekdaySymbols[$0 - 1]).tag($0) }
                                }
                            case .monthly:
                                Stepper("Day of month: \(ritual.reminderDay)", value: $ritual.reminderDay, in: 1...28)
                            case .yearly:
                                Picker("Month", selection: $ritual.reminderMonth) {
                                    ForEach(1...12, id: \.self) { Text(Calendar.current.monthSymbols[$0 - 1]).tag($0) }
                                }
                                Stepper("Day: \(ritual.reminderDay)", value: $ritual.reminderDay, in: 1...28)
                            }
                        }
                    }.padding(6)
                } label: { Label("Reminder", systemImage: "bell") }

                Button("Delete ritual", role: .destructive) { confirmDelete = true }
                    .confirmationDialog("Delete this ritual and its history?", isPresented: $confirmDelete) {
                        Button("Delete", role: .destructive, action: onDelete)
                    }
            }
            .padding(26)
        }
    }
}

// MARK: Help
struct HelpView: View {
    @EnvironmentObject var store: RitualStore
    var body: some View {
        let p = store.period
        let reminderText = p == .weekly ? "pick a weekday and time." : (p == .monthly ? "pick a day of the month and time." : "pick a month, day and time.")
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Help").font(.largeTitle.bold())
                section("Quick start", "1. Use + to add a ritual (a repeatable habit). Pick a quick idea or write your own.\n2. Write its benefit: why it matters to you.\n3. Tick the checkbox when you do it this \(p.noun). Tick again to uncheck.")
                section("Streaks", "A streak counts consecutive \(p.noun)s with the ritual ticked. The current \(p.noun) does not break your streak until it ends, so you can still catch up. Best streak is your longest run.")
                section("Missed one?", "Open the ritual and use the History list to check or uncheck any recent \(p.noun). Add a note to any ticked \(p.noun).")
                section("Notes", "Each ritual has general notes, plus a note for every ticked \(p.noun) (for example price paid, who joined, or how it went).")
                section("Reminders", "Each ritual has its own reminder: \(reminderText) Reminders repeat automatically. If you see none, allow them in System Settings > Notifications.")
                section("Your data", "Saved on your Mac only. Nothing is sent anywhere.")
                Button("Send test notification") { Notifier.sendTest() }
            }
            .padding(26)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    func section(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(text).fixedSize(horizontal: false, vertical: true)
        }
    }
}
