import SwiftUI

/// The hub: today's reflection, a button to read and journal it, the daily streak, lifetime
/// stats, and Pro entry points (the archive of past reflections and your journal).
struct HomeView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    var forceScreen: String? = nil

    @State private var active: ReadSpec?
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showArchive = false
    @State private var showJournal = false

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        header
                        todayCard
                        statsRow
                        proRow
                    }
                    .padding()
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Stoa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showSettings = true } label: {
                        Image(systemName: "gearshape").foregroundStyle(Color.qmAccent)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .tint(Color.qmAccent)
            .fullScreenCover(item: $active) { spec in
                ReflectionView(entry: spec.entry, dateKey: spec.dateKey)
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showArchive) { ArchiveView() }
            .sheet(isPresented: $showJournal) { JournalView() }
            .onAppear { appModel.refreshTodayIfNeeded() }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(dateHeadline).font(.subheadline).foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Image(systemName: "flame.fill").foregroundStyle(Color.qmAccent)
                Text("\(appModel.currentStreak) day streak").font(.headline)
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var todayCard: some View {
        VStack(spacing: 16) {
            Text("TODAY'S REFLECTION")
                .font(.caption.weight(.semibold)).foregroundStyle(.secondary).tracking(1.5)
            if let e = appModel.today {
                Text(e.theme.uppercased())
                    .font(.caption2.weight(.semibold)).foregroundStyle(Color.qmAccent).tracking(1.2)
                Text(e.title)
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                if appModel.reflectedToday {
                    Label("Reflected today", systemImage: "checkmark.seal.fill")
                        .font(.subheadline).foregroundStyle(Color.qmCorrect)
                    Button { read(e) } label: {
                        Text("Read again").frame(maxWidth: .infinity).padding(.vertical, 4)
                    }
                    .softButton()
                } else {
                    Button { read(e) } label: {
                        Text("Read & reflect").frame(maxWidth: .infinity).padding(.vertical, 4)
                    }
                    .prominentButton()
                }
            } else {
                Text("Reflections unavailable.").font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .qmCard()
    }

    private var statsRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Lifetime").font(.headline)
            HStack(spacing: 12) {
                MetricTile(value: "\(appModel.longestStreak)", label: "Best streak")
                MetricTile(value: "\(appModel.totalReflections)", label: "Reflections")
                MetricTile(value: "\(appModel.currentStreak)", label: "Current")
            }
        }
    }

    @ViewBuilder
    private var proRow: some View {
        VStack(spacing: 12) {
            Button {
                Haptics.tap()
                if store.isPro { showArchive = true } else { showPaywall = true }
            } label: {
                proTile(icon: "calendar", title: "Past reflections",
                        subtitle: store.isPro ? "Read any previous day" : "Pro", locked: !store.isPro)
            }
            .buttonStyle(.plain)

            Button {
                Haptics.tap()
                if store.isPro { showJournal = true } else { showPaywall = true }
            } label: {
                proTile(icon: "book.closed", title: "Your journal",
                        subtitle: store.isPro ? "Everything you've written" : "Pro", locked: !store.isPro)
            }
            .buttonStyle(.plain)
        }
    }

    private func proTile(icon: String, title: String, subtitle: String, locked: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold)).foregroundStyle(Color.qmAccent).frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: locked ? "lock.fill" : "chevron.right")
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
        }
        .qmCard()
    }

    private func read(_ e: Entry) {
        Haptics.tap()
        active = ReadSpec(entry: e, dateKey: Corpus.dateKey())
    }

    private var dateHeadline: String {
        let f = DateFormatter(); f.dateStyle = .full; f.timeStyle = .none
        return f.string(from: .now)
    }
}

/// Identifies the reflection being read in the full-screen cover.
struct ReadSpec: Identifiable {
    let entry: Entry
    let dateKey: String
    var id: String { dateKey }
}
