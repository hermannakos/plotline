import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var store = UniverseStore()
    @State private var watchedStore: WatchedStore?
    @State private var activeId: String = "mcu"
    @State private var expandedEntryId: String?
    @State private var jumpTargetId: String?

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            switch store.state {
            case .idle, .loading:
                loadingView
            case .failed(let msg):
                errorView(msg)
            case .ready:
                if let watchedStore { mainView(watchedStore: watchedStore) }
                else { loadingView }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            if watchedStore == nil { watchedStore = WatchedStore(context: modelContext) }
            await store.load()
        }
    }

    // MARK: -

    @ViewBuilder
    private func mainView(watchedStore: WatchedStore) -> some View {
        let universe = store.universe(id: activeId) ?? store.universes.first!
        let phases = groupByPhase(universe.entries)
        let upNext = watchedStore.upNext(in: universe)
        let done = watchedStore.doneCount(in: universe)

        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 18) {
                    // Header
                    VStack(spacing: 6) {
                        Text("🎬 Plotline")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundStyle(Theme.text)
                        Text("Your cinematic universe watch order tracker")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.muted)
                    }
                    .padding(.top, 8)

                    // Universe tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(store.universes) { u in
                                UniverseTab(universe: u, isActive: u.id == activeId) {
                                    withAnimation(.easeOut(duration: 0.18)) {
                                        activeId = u.id
                                        expandedEntryId = nil
                                        jumpTargetId = nil
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Progress + stats
                    UniverseHeader(universe: universe, done: done)
                        .padding(.horizontal, 16)

                    // Up Next
                    if let up = upNext {
                        UpNextCard(
                            universe: universe,
                            entry: up.entry,
                            episode: up.episode,
                            onMarkWatched: {
                                if let ep = up.episode {
                                    watchedStore.toggleEpisode(up.entry, episode: ep, in: universe)
                                } else {
                                    watchedStore.toggleEntry(up.entry, in: universe)
                                }
                            },
                            onJump: {
                                withAnimation {
                                    if up.episode != nil { expandedEntryId = up.entry.id }
                                    jumpTargetId = up.entry.id
                                    proxy.scrollTo(up.entry.id, anchor: .center)
                                }
                            }
                        )
                        .padding(.horizontal, 16)
                    }

                    // Phase groups
                    LazyVStack(spacing: 24) {
                        ForEach(phases, id: \.0) { (phase, entries) in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 10) {
                                    Text(phase)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Theme.text)
                                    Rectangle().fill(Theme.border).frame(height: 1)
                                    Text("\(entries.count)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Theme.muted)
                                        .padding(.horizontal, 8).padding(.vertical, 2)
                                        .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 999))
                                }
                                ForEach(entries) { entry in
                                    EntryRow(
                                        universe: universe,
                                        entry: entry,
                                        expanded: Binding(
                                            get: { expandedEntryId == entry.id },
                                            set: { expandedEntryId = $0 ? entry.id : nil }
                                        ),
                                        watchedStore: watchedStore,
                                        onToggleEntry: {
                                            watchedStore.toggleEntry(entry, in: universe)
                                        },
                                        onToggleEpisode: { ep in
                                            watchedStore.toggleEpisode(entry, episode: ep, in: universe)
                                        }
                                    )
                                    .id(entry.id)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Text("Built with ❤️")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.muted)
                        .padding(.vertical, 24)
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView().tint(Theme.muted)
            Text("Loading…").font(.system(size: 13)).foregroundStyle(Theme.muted)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 10) {
            Text("Failed to load").font(.headline).foregroundStyle(Theme.text)
            Text(message).font(.system(size: 13)).foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
            Button("Retry") { Task { await store.load() } }
                .buttonStyle(.borderedProminent)
                .tint(Theme.muted)
                .padding(.top, 6)
        }
    }

    /// Preserves insertion order of phases — same behavior as the web app's `groupByPhase`.
    private func groupByPhase(_ entries: [Entry]) -> [(String, [Entry])] {
        var order: [String] = []
        var byPhase: [String: [Entry]] = [:]
        for e in entries {
            if byPhase[e.phase] == nil { order.append(e.phase) }
            byPhase[e.phase, default: []].append(e)
        }
        return order.map { ($0, byPhase[$0] ?? []) }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: WatchedMarker.self, inMemory: true)
}
