import Foundation
import SwiftData
import Observation

/// Wraps SwiftData watched-marker reads/writes and exposes a fast O(1)
/// in-memory lookup. Mirrors the web app's helpers (`isSeriesWatched`,
/// `countWatchedEpisodes`, `getUpNext`).
@Observable
@MainActor
final class WatchedStore {
    private let context: ModelContext
    private(set) var keys: Set<String> = []

    init(context: ModelContext) {
        self.context = context
        reload()
    }

    func reload() {
        let descriptor = FetchDescriptor<WatchedMarker>()
        let all = (try? context.fetch(descriptor)) ?? []
        keys = Set(all.map(\.key))
    }

    func isWatched(_ key: String) -> Bool { keys.contains(key) }

    func setWatched(_ key: String, universeId: String, watched: Bool) {
        if watched {
            guard !keys.contains(key) else { return }
            context.insert(WatchedMarker(key: key, universeId: universeId))
            keys.insert(key)
        } else {
            keys.remove(key)
            let descriptor = FetchDescriptor<WatchedMarker>(predicate: #Predicate { $0.key == key })
            if let existing = try? context.fetch(descriptor) {
                for m in existing { context.delete(m) }
            }
        }
        try? context.save()
    }

    // MARK: - Entry-level helpers

    func isSeriesWatched(_ entry: Entry) -> Bool {
        guard entry.type == .series, let n = entry.episodes, n > 0 else { return false }
        for i in 1...n where !keys.contains(WatchedMarker.episodeKey(entryId: entry.id, episode: i)) {
            return false
        }
        return true
    }

    func watchedEpisodeCount(_ entry: Entry) -> Int {
        guard entry.type == .series, let n = entry.episodes, n > 0 else { return 0 }
        var count = 0
        for i in 1...n where keys.contains(WatchedMarker.episodeKey(entryId: entry.id, episode: i)) {
            count += 1
        }
        return count
    }

    func isEntryComplete(_ entry: Entry) -> Bool {
        if entry.type == .series, let n = entry.episodes, n > 0 { return isSeriesWatched(entry) }
        return keys.contains(entry.id)
    }

    func toggleEntry(_ entry: Entry, in universe: Universe) {
        switch entry.type {
        case .series where (entry.episodes ?? 0) > 0:
            let n = entry.episodes!
            let allWatched = isSeriesWatched(entry)
            for i in 1...n {
                setWatched(WatchedMarker.episodeKey(entryId: entry.id, episode: i),
                           universeId: universe.id, watched: !allWatched)
            }
        default:
            setWatched(entry.id, universeId: universe.id, watched: !isWatched(entry.id))
        }
    }

    func toggleEpisode(_ entry: Entry, episode: Int, in universe: Universe) {
        let key = WatchedMarker.episodeKey(entryId: entry.id, episode: episode)
        setWatched(key, universeId: universe.id, watched: !isWatched(key))
    }

    /// First incomplete entry in array order (or first unwatched episode of an in-progress series).
    func upNext(in universe: Universe) -> (entry: Entry, episode: Int?)? {
        for entry in universe.entries {
            if entry.type == .series, let n = entry.episodes, n > 0 {
                for i in 1...n where !keys.contains(WatchedMarker.episodeKey(entryId: entry.id, episode: i)) {
                    return (entry, i)
                }
            } else if !keys.contains(entry.id) {
                return (entry, nil)
            }
        }
        return nil
    }

    func doneCount(in universe: Universe) -> Int {
        universe.entries.reduce(0) { $0 + (isEntryComplete($1) ? 1 : 0) }
    }
}
