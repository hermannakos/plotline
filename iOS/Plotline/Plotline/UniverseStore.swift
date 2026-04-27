import Foundation
import Observation

/// Loads `universes.json` from GitHub Pages so the app's content can be
/// updated without shipping a new build. The last successful payload is
/// cached on disk so the app still opens offline.
@Observable
@MainActor
final class UniverseStore {
    static let remoteURL = URL(string: "https://hermannakos.github.io/plotline/universes.json")!

    enum LoadState: Equatable {
        case idle
        case loading
        case ready
        case failed(String)
    }

    private(set) var universes: [Universe] = []   // ordered as in JSON
    private(set) var state: LoadState = .idle

    private var byId: [String: Universe] = [:]
    func universe(id: String) -> Universe? { byId[id] }

    func load() async {
        if case .loading = state { return }
        state = .loading

        // Try network first. Fall back to disk cache on failure.
        do {
            var req = URLRequest(url: Self.remoteURL)
            req.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            try apply(data: data)
            try? data.write(to: Self.cacheURL, options: .atomic)
        } catch {
            if let cached = try? Data(contentsOf: Self.cacheURL),
               (try? apply(data: cached)) != nil {
                // served from cache; surface no error
            } else {
                state = .failed(error.localizedDescription)
            }
        }
    }

    private func apply(data: Data) throws {
        let decoder = JSONDecoder()
        let dict = try decoder.decode([String: Universe].self, from: data)
        // Preserve the canonical order used by the web app.
        let order = ["mcu", "dceu", "monsterverse", "starwars", "arrowverse"]
        let ordered = order.compactMap { dict[$0] } + dict.values.filter { !order.contains($0.id) }
        self.universes = ordered
        self.byId = Dictionary(uniqueKeysWithValues: ordered.map { ($0.id, $0) })
        self.state = .ready
    }

    private static var cacheURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("universes.json")
    }
}
