import SwiftUI

/// The daily reading: today's Stoic reflection, who inspired it, a prompt, and a private journal
/// note the reader can write and save. Used for today's entry and (via the Pro archive) past days.
struct ReflectionView: View {
    let entry: Entry
    let dateKey: String

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var note = ""
    @State private var saved = false
    @FocusState private var editing: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        reflectionCard
                        promptCard
                        journalCard
                        saveButton
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(dateLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }.tint(Color.qmAccent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if editing { Button("Done") { editing = false }.tint(Color.qmAccent) }
                }
            }
            .onAppear { note = appModel.note(forKey: dateKey)?.note ?? "" }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.theme.uppercased())
                .font(.caption.weight(.semibold)).foregroundStyle(Color.qmAccent).tracking(1.5)
            Text(entry.title)
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
    }

    private var reflectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(entry.reflection)
                .font(.system(.body, design: .serif))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
            Text("Inspired by \(entry.inspiredBy)")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .qmCard()
    }

    private var promptCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.qmAccent)
            Text(entry.prompt)
                .font(.callout.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .qmCard()
    }

    private var journalCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("YOUR REFLECTION")
                .font(.caption.weight(.semibold)).foregroundStyle(.secondary).tracking(1.5)
            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text("Write a few words…")
                        .font(.body).foregroundStyle(.tertiary)
                        .padding(.top, 8).padding(.leading, 5)
                }
                TextEditor(text: $note)
                    .focused($editing)
                    .font(.body)
                    .frame(minHeight: 140)
                    .scrollContentBackground(.hidden)
                    .onChange(of: note) { _, _ in saved = false }
            }
        }
        .qmCard()
    }

    @ViewBuilder
    private var saveButton: some View {
        Button {
            editing = false
            appModel.save(entry: entry, note: note.trimmingCharacters(in: .whitespacesAndNewlines), for: dateKey)
            Haptics.success(); saved = true
        } label: {
            Label(saved ? "Saved" : "Save reflection", systemImage: saved ? "checkmark" : "tray.and.arrow.down")
                .frame(maxWidth: .infinity).padding(.vertical, 4)
        }
        .prominentButton()
        .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private var dateLabel: String {
        if dateKey == Corpus.dateKey() { return "Today" }
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        guard let d = fmt.date(from: dateKey) else { return "Reflection" }
        let out = DateFormatter(); out.dateStyle = .medium; out.timeStyle = .none
        return out.string(from: d)
    }
}
