import Foundation
import SwiftData

/// One daily Stoic reflection: an original, plain-language meditation in the Stoic tradition,
/// plus a prompt to journal on. `inspiredBy` credits the Stoic whose teaching inspired it
/// (an attribution of inspiration, not a quotation).
struct Entry: Codable, Identifiable, Equatable {
    let id: Int
    let theme: String
    let title: String
    let reflection: String
    let prompt: String
    let inspiredBy: String
}

/// The bundled corpus. The reflection for a given day is chosen deterministically from the date,
/// so everyone gets the same one; Pro unlocks the archive of past days.
enum Corpus {
    static let all: [Entry] = load()

    private static func load() -> [Entry] {
        guard let url = Bundle.main.url(forResource: "stoa_corpus", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([Entry].self, from: data) else { return [] }
        return entries
    }

    private static func epochDay(_ date: Date) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        return Int((start.timeIntervalSince1970 / 86_400).rounded(.down))
    }

    static func index(for date: Date, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let d = epochDay(date)
        return ((d % count) + count) % count
    }

    static func today(for date: Date = .now) -> Entry? {
        guard !all.isEmpty else { return nil }
        return all[index(for: date, count: all.count)]
    }

    /// The reflection for a day N days back (Pro archive).
    static func daily(daysAgo: Int, from date: Date = .now) -> Entry? {
        guard !all.isEmpty else { return nil }
        let day = Calendar.current.date(byAdding: .day, value: -daysAgo, to: date) ?? date
        return all[index(for: day, count: all.count)]
    }

    static func dateKey(for date: Date = .now) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 2026, c.month ?? 1, c.day ?? 1)
    }
}

/// A saved journal note for a given day's reflection. Local-only; defaults + no unique
/// constraints keep it CloudKit-compatible if sync is ever added.
@Model
final class JournalNote {
    var id: UUID = UUID()
    var dateKey: String = ""
    var entryId: Int = 0
    var note: String = ""
    var date: Date = Date.now

    init(id: UUID = UUID(), dateKey: String = "", entryId: Int = 0, note: String = "", date: Date = .now) {
        self.id = id; self.dateKey = dateKey; self.entryId = entryId; self.note = note; self.date = date
    }
}
