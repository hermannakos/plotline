import Foundation
import SwiftData
import SwiftUI

// MARK: - Remote data (decoded from universes.json)

struct Universe: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let short: String
    let color: String
    let accent: String?
    let emoji: String
    let description: String
    let entries: [Entry]
    let showColors: [String: String]?
}

struct Entry: Codable, Identifiable, Hashable {
    enum Kind: String, Codable {
        case movie = "Movie"
        case series = "Series"
        case crossover = "Crossover"
    }

    let id: String
    let title: String
    let year: Int
    let type: Kind
    let phase: String
    let episodes: Int?
    let show: String?
    let note: String?
}

extension Universe {
    var swiftUIColor: Color { Color.fromHex(color) ?? .accentColor }
    var accentColor: Color { accent.flatMap { Color.fromHex($0) } ?? swiftUIColor }
    func showColor(for entry: Entry) -> Color {
        if let key = entry.show, let hex = showColors?[key], let c = Color.fromHex(hex) { return c }
        return swiftUIColor
    }
    /// The show name to render as a badge — `nil` means no show pill should appear
    /// (movies, generic-universe series, and the synthetic "CROSSOVER" sentinel).
    func showBadge(for entry: Entry) -> String? {
        guard let s = entry.show, s != "CROSSOVER" else { return nil }
        return s
    }
}

// MARK: - Watched-state markers (SwiftData)
//
// Marker key matches the web app's localStorage scheme:
//   movies / crossovers: "<entryId>"
//   series episode:      "<entryId>_ep_<n>"  (1-indexed)
// A whole-series toggle expands into all episode markers — there is no
// separate "series watched" key.

@Model
final class WatchedMarker {
    @Attribute(.unique) var key: String
    var universeId: String
    var watchedAt: Date

    init(key: String, universeId: String, watchedAt: Date = .now) {
        self.key = key
        self.universeId = universeId
        self.watchedAt = watchedAt
    }

    static func episodeKey(entryId: String, episode: Int) -> String { "\(entryId)_ep_\(episode)" }
}

