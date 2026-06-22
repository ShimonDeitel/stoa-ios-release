import SwiftUI

/// Pro: read (and journal) any previous day's reflection.
struct ArchiveView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var read: ReadSpec?

    private let days = 1...90

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(Array(days), id: \.self) { daysAgo in
                            if let e = Corpus.daily(daysAgo: daysAgo) {
                                row(daysAgo: daysAgo, entry: e)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Past Reflections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.tint(Color.qmAccent) }
            }
            .fullScreenCover(item: $read) { spec in
                ReflectionView(entry: spec.entry, dateKey: spec.dateKey)
            }
        }
    }

    private func row(daysAgo: Int, entry: Entry) -> some View {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        let key = Corpus.dateKey(for: date)
        let journaled = appModel.note(forKey: key) != nil
        return Button {
            Haptics.tap(); read = ReadSpec(entry: entry, dateKey: key)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: journaled ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(journaled ? Color.qmCorrect : Color.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title).font(.headline).foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("\(dateLabel(date)) · \(entry.theme)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
            }
            .qmCard()
        }
        .buttonStyle(.plain)
    }

    private func dateLabel(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none
        return f.string(from: d)
    }
}
