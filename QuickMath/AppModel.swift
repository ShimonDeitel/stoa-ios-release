import Foundation
import SwiftData
import SwiftUI

/// App state: owns the local SwiftData store, exposes today's reflection, and derives the streak
/// and lifetime stats from saved journal notes (never stored as truth).
@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    @Published private(set) var currentStreak = 0
    @Published private(set) var longestStreak = 0
    @Published private(set) var totalReflections = 0
    @Published private(set) var reflectedToday = false
    @Published private(set) var today: Entry?

    init(container: ModelContainer) {
        self.container = container
        today = Corpus.today()
        refresh()
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([JournalNote.self])
        let local = ModelConfiguration(schema: schema)
        if let c = try? ModelContainer(for: schema, configurations: local) { return c }
        let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: mem)
    }

    func refreshTodayIfNeeded() {
        today = Corpus.today()
        refresh()
    }

    /// Save (or update) the journal note for a given day's reflection.
    func save(entry: Entry, note: String, for dateKey: String) {
        let ctx = container.mainContext
        if let existing = allNotes().first(where: { $0.dateKey == dateKey }) {
            existing.note = note
            existing.entryId = entry.id
            existing.date = .now
        } else {
            ctx.insert(JournalNote(dateKey: dateKey, entryId: entry.id, note: note))
        }
        try? ctx.save()
        refresh()
    }

    func allNotes() -> [JournalNote] {
        let d = FetchDescriptor<JournalNote>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return (try? container.mainContext.fetch(d)) ?? []
    }

    func note(forKey key: String) -> JournalNote? {
        allNotes().first { $0.dateKey == key }
    }

    func refresh() {
        let notes = allNotes()
        totalReflections = Set(notes.map(\.dateKey)).count
        reflectedToday = notes.contains { $0.dateKey == Corpus.dateKey() }
        let keys = Set(notes.map(\.dateKey))
        let s = Self.streaks(from: keys)
        currentStreak = s.current
        longestStreak = s.longest
    }

    /// Current (consecutive days ending today/yesterday) and longest run from journaled-day keys.
    static func streaks(from keys: Set<String>) -> (current: Int, longest: Int) {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"; fmt.timeZone = .current
        let cal = Calendar.current
        let days = Set(keys.compactMap { fmt.date(from: $0) }.map { cal.startOfDay(for: $0) })
        guard !days.isEmpty else { return (0, 0) }

        let sorted = days.sorted()
        var longest = 1, run = 1
        for i in 1..<sorted.count {
            let gap = cal.dateComponents([.day], from: sorted[i - 1], to: sorted[i]).day ?? 0
            if gap == 1 { run += 1 } else { run = 1 }
            longest = max(longest, run)
        }

        var current = 0
        var cursor = cal.startOfDay(for: .now)
        if !days.contains(cursor) { cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor }
        while days.contains(cursor) {
            current += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return (current, max(longest, current))
    }

    func deleteAllData() {
        let ctx = container.mainContext
        for n in allNotes() { ctx.delete(n) }
        try? ctx.save()
        refresh()
    }
}
