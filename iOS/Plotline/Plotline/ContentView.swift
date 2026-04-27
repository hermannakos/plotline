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

    @ViewBuilder
    private func mainView(watchedStore: WatchedStore) -> some View {
        let universe = store.universe(id: activeId) ?? store.universes.first!
        let phases = groupByPhase(universe.entries)
        let upNext = watchedStore.upNext(in: universe)
        let done = watchedStore.doneCount(in: universe)

        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 14) {
                    // Top bar — mark + wordmark, no emoji clutter
                    HStack {
                        HStack(spacing: 10) {
                            PlotlineMark(size: 22)
                            Text("Plotline")
                                .font(.system(size: 19, weight: .bold))
                                .tracking(-0.4)
                                .foregroundStyle(Theme.text)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                    // Universe tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(store.universes) { u in
                                let total = u.entries.count
                                let pct = total == 0 ? 0.0 : Double(watchedStore.doneCount(in: u)) / Double(total)
                                UniverseTab(universe: u, isActive: u.id == activeId, progress: pct) {
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

                    // Hero
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
                                let entryId = up.entry.id
                                let willExpand = up.episode != nil && expandedEntryId != entryId
                                if willExpand {
                                    withAnimation(.easeOut(duration: 0.25)) { expandedEntryId = entryId }
                                }
                                jumpTargetId = entryId
                                // Let the expansion-induced layout change settle before scrolling
                                // so SwiftUI doesn't race the height change against the scroll target.
                                Task { @MainActor in
                                    if willExpand { try? await Task.sleep(for: .milliseconds(80)) }
                                    withAnimation(.easeInOut(duration: 0.4)) {
                                        proxy.scrollTo(entryId, anchor: .center)
                                    }
                                }
                            }
                        )
                        .padding(.horizontal, 16)
                    }

                    // Phase groups with timeline rail.
                    // Non-lazy VStack so every EntryRow's .id() is registered
                    // up-front; ScrollViewReader.scrollTo silently no-ops on
                    // un-instantiated rows, which used to break MCU's deep
                    // Up Next targets.
                    VStack(spacing: 0) {
                        ForEach(phases, id: \.0) { (phase, entries) in
                            VStack(alignment: .leading, spacing: 0) {
                                PhaseHeader(phase: phase, count: entries.count, accent: universe.swiftUIColor)
                                    .padding(.top, 10)
                                    .padding(.bottom, 6)

                                ForEach(Array(entries.enumerated()), id: \.element.id) { (i, entry) in
                                    EntryRow(
                                        universe: universe,
                                        entry: entry,
                                        isFirst: i == 0,
                                        isLast: i == entries.count - 1,
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

                    Text("Built with care")
                        .font(.system(size: 11))
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
