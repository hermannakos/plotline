import SwiftUI

// MARK: - Universe tab pill

struct UniverseTab: View {
    let universe: Universe
    let isActive: Bool
    let progress: Double            // 0…1, fraction of universe watched
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(universe.emoji).font(.system(size: 17))
                Text(universe.short)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                GeometryReader { geo in
                    let baseFill = isActive
                        ? universe.swiftUIColor.opacity(0.18)
                        : Theme.surface
                    let progressFill = universe.swiftUIColor.opacity(isActive ? 0.42 : 0.22)

                    ZStack(alignment: .leading) {
                        Rectangle().fill(baseFill)
                        Rectangle()
                            .fill(progressFill)
                            .frame(width: geo.size.width * CGFloat(min(max(progress, 0), 1)))
                            .animation(.easeOut(duration: 0.35), value: progress)
                    }
                    .clipShape(Capsule())
                }
            )
            .overlay(
                Capsule().stroke(isActive ? universe.swiftUIColor : Theme.border, lineWidth: 2)
            )
            .foregroundStyle(isActive ? Theme.text : Theme.muted)
            .shadow(color: isActive ? universe.swiftUIColor.opacity(0.35) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Progress + stats header

struct UniverseHeader: View {
    let universe: Universe
    let done: Int

    private var total: Int { universe.entries.count }
    private var pct: Double { total == 0 ? 0 : Double(done) / Double(total) }
    private var movies: Int { universe.entries.filter { $0.type == .movie }.count }
    private var series: Int { universe.entries.filter { $0.type == .series }.count }
    private var crossovers: Int { universe.entries.filter { $0.type == .crossover }.count }

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 6) {
                HStack {
                    Text(universe.name).font(.system(size: 13)).foregroundStyle(Theme.muted)
                    Spacer()
                    Text("\(done) / \(total) watched (\(Int(pct * 100))%)")
                        .font(.system(size: 13)).foregroundStyle(Theme.muted)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Theme.border)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(universe.swiftUIColor)
                            .frame(width: geo.size.width * pct)
                            .animation(.easeOut(duration: 0.4), value: pct)
                    }
                }
                .frame(height: 6)
            }

            HStack(spacing: 8) {
                if movies > 0 { StatPill(icon: "🎬", label: "\(movies) movies") }
                if series > 0 { StatPill(icon: "📺", label: "\(series) series") }
                if crossovers > 0 { StatPill(icon: "⚡", label: "\(crossovers) crossovers") }
                StatPill(icon: "✅", label: "\(done) watched")
            }
        }
    }
}

private struct StatPill: View {
    let icon: String
    let label: String
    var body: some View {
        HStack(spacing: 6) {
            Text(icon)
            Text(label).font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.pillCorner))
        .overlay(RoundedRectangle(cornerRadius: Theme.pillCorner).stroke(Theme.border, lineWidth: 1))
        .foregroundStyle(Theme.text)
    }
}

// MARK: - Up Next card

struct UpNextCard: View {
    let universe: Universe
    let entry: Entry
    let episode: Int?
    let onMarkWatched: () -> Void
    let onJump: () -> Void

    private var subtitle: String {
        if let ep = episode { return "Episode \(ep) · \(entry.title)" }
        switch entry.type {
        case .movie: return "Movie · \(entry.year)"
        case .series: return "Series · \(entry.year)"
        case .crossover: return "Crossover · \(entry.year)"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("UP NEXT")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(universe.swiftUIColor)

            Text(episode != nil ? "Episode \(episode!) of \(entry.title)" : entry.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.text)

            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(Theme.muted)

            HStack(spacing: 10) {
                Button(action: onMarkWatched) {
                    Label("Mark watched", systemImage: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(universe.swiftUIColor, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                Button(action: onJump) {
                    Label("Jump to", systemImage: "arrow.down")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Theme.surface2, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
                        .foregroundStyle(Theme.text)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardCorner))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCorner)
                .stroke(universe.swiftUIColor.opacity(0.6), lineWidth: 1.5)
        )
        .shadow(color: universe.swiftUIColor.opacity(0.25), radius: 14, y: 4)
    }
}

// MARK: - Entry row

struct EntryRow: View {
    let universe: Universe
    let entry: Entry
    @Binding var expanded: Bool
    let watchedStore: WatchedStore
    let onToggleEntry: () -> Void
    let onToggleEpisode: (Int) -> Void

    private var color: Color { universe.showColor(for: entry) }
    private var hasEpisodes: Bool { entry.type == .series && (entry.episodes ?? 0) > 0 }
    private var isCrossover: Bool { entry.type == .crossover }
    private var isComplete: Bool { watchedStore.isEntryComplete(entry) }
    private var watchedEpisodes: Int { watchedStore.watchedEpisodeCount(entry) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isComplete ? color : Color.clear)
                        .frame(width: 22, height: 22)
                    Circle()
                        .stroke(isComplete ? color : Theme.border, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.top, 1)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 6) {
                        Text(entry.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.text)
                            .lineLimit(3)
                            .strikethrough(isComplete && !hasEpisodes, color: Theme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if hasEpisodes {
                            Button { withAnimation { expanded.toggle() } } label: {
                                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Theme.muted)
                                    .padding(.horizontal, 6).padding(.vertical, 3)
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    BadgeRow(universe: universe, entry: entry)

                    if hasEpisodes, let n = entry.episodes {
                        EpisodeProgress(watched: watchedEpisodes, total: n, color: color)
                    }

                    if let note = entry.note {
                        Text(note)
                            .font(.system(size: 12))
                            .italic()
                            .foregroundStyle(Theme.muted)
                            .lineLimit(2)
                    }
                }
            }
            .padding(14)
            .contentShape(Rectangle())
            .onTapGesture { onToggleEntry() }

            if hasEpisodes && expanded, let n = entry.episodes {
                Divider().background(Theme.border)
                LazyVGrid(columns: episodeGridColumns, spacing: 6) {
                    ForEach(1...n, id: \.self) { ep in
                        let key = WatchedMarker.episodeKey(entryId: entry.id, episode: ep)
                        let watched = watchedStore.isWatched(key)
                        Button { onToggleEpisode(ep) } label: {
                            Text("\(ep)")
                                .font(.system(size: 12, weight: .medium))
                                .frame(maxWidth: .infinity, minHeight: 30)
                                .background(watched ? color.opacity(0.25) : Theme.surface2,
                                            in: RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6)
                                    .stroke(watched ? color : Theme.border, lineWidth: 1))
                                .foregroundStyle(watched ? Theme.text : Theme.muted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
            }
        }
        .background(cardBackground, in: RoundedRectangle(cornerRadius: Theme.cardCorner))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCorner)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .opacity(isComplete && !isCrossover ? 0.78 : 1)
    }

    private var cardBackground: Color {
        if isCrossover { return Theme.surface2 }
        return Theme.surface
    }

    private var borderColor: Color {
        if isCrossover { return universe.accentColor.opacity(0.55) }
        if isComplete { return color.opacity(0.5) }
        return Theme.border
    }

    private var borderWidth: CGFloat { isCrossover ? 1.5 : 1 }

    private var episodeGridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 6), count: 6)
    }
}

// MARK: - Badges row + helpers

private struct BadgeRow: View {
    let universe: Universe
    let entry: Entry

    var body: some View {
        // Use a wrapping HStack via an HFlow-style fallback: small content fits on one line in practice.
        HStack(spacing: 6) {
            Badge(text: String(entry.year), foreground: Theme.muted, background: Theme.surface2)

            switch entry.type {
            case .movie:
                Badge(text: "Movie", foreground: Color.fromHex("#7aabff") ?? .blue,
                      background: (Color.fromHex("#7aabff") ?? .blue).opacity(0.18))
            case .series:
                Badge(text: "Series", foreground: Color.fromHex("#7affd4") ?? .green,
                      background: (Color.fromHex("#7affd4") ?? .green).opacity(0.18))
            case .crossover:
                Badge(text: "Crossover", foreground: universe.accentColor,
                      background: universe.accentColor.opacity(0.22))
            }

            if let show = universe.showBadge(for: entry) {
                let c = universe.showColor(for: entry)
                Badge(text: show, foreground: c, background: c.opacity(0.20))
            }

            Spacer(minLength: 0)
        }
    }
}

private struct Badge: View {
    let text: String
    let foreground: Color
    let background: Color

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.6)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(background, in: RoundedRectangle(cornerRadius: 4))
            .foregroundStyle(foreground)
            .lineLimit(1)
    }
}

private struct EpisodeProgress: View {
    let watched: Int
    let total: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(watched) / \(total) episodes")
                .font(.system(size: 11))
                .foregroundStyle(Theme.muted)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Theme.border)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * (total == 0 ? 0 : Double(watched) / Double(total)))
                        .animation(.easeOut(duration: 0.3), value: watched)
                }
            }
            .frame(height: 3)
        }
    }
}
