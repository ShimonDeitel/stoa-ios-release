import SwiftUI

/// Pro: everything you've written, newest first. Tap an entry to reread and edit it.
struct JournalView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var read: ReadSpec?

    private var notes: [JournalNote] {
        appModel.allNotes().filter { !$0.note.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                if notes.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 36)).foregroundStyle(.secondary)
                        Text("Nothing written yet")
                            .font(.headline)
                        Text("Your saved reflections will gather here.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(notes) { n in row(n) }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Your Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.tint(Color.qmAccent) }
            }
            .fullScreenCover(item: $read) { spec in
                ReflectionView(entry: spec.entry, dateKey: spec.dateKey)
            }
        }
    }

    private func row(_ n: JournalNote) -> some View {
        let entry = Corpus.all.first { $0.id == n.entryId }
        return Button {
            guard let entry else { return }
            Haptics.tap(); read = ReadSpec(entry: entry, dateKey: n.dateKey)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(dateLabel(n.date)).font(.caption).foregroundStyle(.secondary)
                if let entry { Text(entry.title).font(.headline).lineLimit(1) }
                Text(n.note).font(.subheadline).foregroundStyle(.primary)
                    .lineLimit(3).multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .qmCard()
        }
        .buttonStyle(.plain)
    }

    private func dateLabel(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none
        return f.string(from: d)
    }
}
