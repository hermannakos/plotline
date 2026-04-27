import SwiftUI

// MARK: - Plotline mark (neon path used in icon + splash)

struct PlotlineMark: View {
    var size: CGFloat = 22
    private let pts: [CGPoint] = [
        .init(x: 0.215, y: 0.742),
        .init(x: 0.371, y: 0.547),
        .init(x: 0.547, y: 0.625),
        .init(x: 0.605, y: 0.410),
        .init(x: 0.781, y: 0.293)
    ]

    var body: some View {
        Canvas { ctx, s in
            let path = Path { p in
                let mapped = pts.map { CGPoint(x: $0.x * s.width, y: $0.y * s.height) }
                p.move(to: mapped[0])
                for pt in mapped.dropFirst() { p.addLine(to: pt) }
            }
            // Outer glow
            ctx.addFilter(.blur(radius: s.width * 0.06))
            ctx.stroke(path, with: .color(Theme.neon.opacity(0.5)),
                       style: StrokeStyle(lineWidth: s.width * 0.08, lineCap: .round, lineJoin: .round))
            ctx.addFilter(.blur(radius: 0))
            // Main stroke
            ctx.stroke(path, with: .linearGradient(
                Gradient(colors: [Theme.neonDeep, Theme.neonGlow]),
                startPoint: .init(x: 0, y: s.height),
                endPoint: .init(x: s.width, y: 0)
            ), style: StrokeStyle(lineWidth: s.width * 0.055, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Universe tab pill (with progress ring)

struct UniverseTab: View {
    let universe: Universe
    let isActive: Bool
    let progress: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(isActive ? universe.swiftUIColor.opacity(0.27) : Theme.hairlineStrong, lineWidth: 2)
                        .frame(width: 18, height: 18)
                    Circle()
                        .trim(from: 0, to: max(0.001, min(progress, 1)))
                        .stroke(universe.swiftUIColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 18, height: 18)
                        .animation(.easeOut(duration: 0.4), value: progress)
                    Text(universe.emoji).font(.system(size: 11))
                }
                Text(universe.short).font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(
                Capsule().fill(
                    isActive
                    ? AnyShapeStyle(LinearGradient(
                        colors: [universe.swiftUIColor.opacity(0.22), universe.swiftUIColor.opacity(0.11)],
                        startPoint: .top, endPoint: .bottom))
                    : AnyShapeStyle(Theme.surface)
                )
            )
            .overlay(
                Capsule().stroke(
                    isActive ? universe.swiftUIColor : Theme.hairline,
                    lineWidth: 1
                )
            )
            .foregroundStyle(isActive ? Theme.text : Theme.textDim)
            .shadow(color: isActive ? universe.swiftUIColor.opacity(0.30) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Hero

struct UniverseHeader: View {
    let universe: Universe
    let done: Int

    private var total: Int { universe.entries.count }
    private var pct: Double { total == 0 ? 0 : Double(done) / Double(total) }
    private var movies: Int { universe.entries.filter { $0.type == .movie }.count }
    private var series: Int { universe.entries.filter { $0.type == .series }.count }
    private var crossovers: Int { universe.entries.filter { $0.type == .crossover }.count }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Inner card background
            RoundedRectangle(cornerRadius: Theme.cardCornerLg - 1)
                .fill(
                    RadialGradient(
                        colors: [
                            universe.swiftUIColor.opacity(0.22),
                            Theme.bgElev
                        ],
                        center: .topLeading, startRadius: 0, endRadius: 360
                    )
                )

            VStack(alignment: .leading, spacing: 0) {
                Text("\(universe.short) · WATCH ORDER")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(universe.swiftUIColor)

                Text(universe.name)
                    .font(.system(size: 26, weight: .bold))
                    .tracking(-0.6)
                    .foregroundStyle(Theme.text)
                    .padding(.top, 6)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(Int(pct * 100))%")
                        .font(.system(size: 38, weight: .bold))
                        .tracking(-1.5)
                        .foregroundStyle(Theme.text)
                    Text("\(done) of \(total) watched")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textDim)
                }
                .padding(.top, 18)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.06))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(
                                colors: [universe.swiftUIColor, universe.swiftUIColor.opacity(0.8)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * pct)
                            .shadow(color: universe.swiftUIColor.opacity(0.5), radius: 6)
                            .animation(.easeOut(duration: 0.4), value: pct)
                    }
                }
                .frame(height: 6)
                .padding(.top, 10)

                HStack(spacing: 18) {
                    if movies > 0 { HeroStat(n: movies, label: "Movies") }
                    if series > 0 { HeroStat(n: series, label: "Series") }
                    if crossovers > 0 { HeroStat(n: crossovers, label: crossovers == 1 ? "Crossover" : "Crossovers") }
                }
                .padding(.top, 14)
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerLg - 1))
        .padding(1)
        .background(
            LinearGradient(
                colors: [
                    universe.swiftUIColor.mix(with: .white, by: 0.1),
                    universe.swiftUIColor,
                    universe.swiftUIColor.opacity(0.4)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: Theme.cardCornerLg)
        )
        .shadow(color: universe.swiftUIColor.opacity(0.33), radius: 18, y: 10)
        .shadow(color: universe.swiftUIColor.opacity(0.26), radius: 60)
    }
}

private extension Color {
    /// Linear-blend two colors in sRGB. Lightweight stand-in for `color-mix`.
    func mix(with other: Color, by t: Double) -> Color {
        let a = UIColor(self).cgColor.components ?? [0,0,0,1]
        let b = UIColor(other).cgColor.components ?? [0,0,0,1]
        func c(_ i: Int) -> Double { (a.indices.contains(i) ? Double(a[i]) : 0) * (1-t) + (b.indices.contains(i) ? Double(b[i]) : 0) * t }
        return Color(red: c(0), green: c(1), blue: c(2))
    }
}


private struct HeroStat: View {
    let n: Int
    let label: String
    var body: some View {
        HStack(spacing: 5) {
            Text("\(n)").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.text)
            Text(label).font(.system(size: 12)).foregroundStyle(Theme.textDim)
        }
    }
}

// MARK: - Up Next (signature neon glow)

struct UpNextCard: View {
    let universe: Universe
    let entry: Entry
    let episode: Int?
    let onMarkWatched: () -> Void
    let onJump: () -> Void

    private var subtitle: String {
        if let ep = episode, let total = entry.episodes {
            return "Episode \(ep) of \(total)"
        }
        return String(entry.year)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("UP NEXT")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundStyle(Theme.textDim)

            Text(entry.title)
                .font(.system(size: 20, weight: .bold))
                .tracking(-0.5)
                .foregroundStyle(Theme.text)
                .lineLimit(2)
                .padding(.top, 8)

            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textDim)
                .padding(.top, 4)

            HStack(spacing: 8) {
                Button(action: onMarkWatched) {
                    Text("Mark watched")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.bg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Theme.text, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                Button(action: onJump) {
                    Text("Jump to")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.text)
                        .padding(.horizontal, 14).padding(.vertical, 11)
                        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairlineStrong, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 14)
        }
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 14, trailing: 16))
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardCornerLg))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCornerLg).stroke(Theme.hairlineStrong, lineWidth: 1)
        )
    }
}

// MARK: - Entry row with timeline rail

struct EntryRow: View {
    let universe: Universe
    let entry: Entry
    let isFirst: Bool
    let isLast: Bool
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
        HStack(alignment: .top, spacing: 14) {
            // Rail — both line and node share the same 22pt column,
            // .center alignment guarantees they share a vertical axis.
            ZStack(alignment: .top) {
                // Vertical rail line behind the node
                Rectangle()
                    .fill(LinearGradient(
                        colors: [color.opacity(0.33), Theme.hairline],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(width: 2)
                    .opacity(0.6)
                    .padding(.top, isFirst ? 22 : 0)
                    .frame(maxHeight: isLast ? 26 : .infinity, alignment: .top)

                // Node
                ZStack {
                    Circle()
                        .fill(isComplete ? color : Theme.bg)
                        .frame(width: 16, height: 16)
                    Circle()
                        .stroke(isComplete ? color : color.opacity(0.4), lineWidth: 2)
                        .frame(width: 16, height: 16)
                    if isComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(Theme.bg)
                    }
                }
                .shadow(color: isComplete ? color.opacity(0.5) : .clear, radius: 5)
                .padding(.top, 18)
            }
            .frame(width: 22, alignment: .center)

            // Card
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 6) {
                    Text(entry.title)
                        .font(.system(size: 14.5, weight: .semibold))
                        .tracking(-0.2)
                        .foregroundStyle(isComplete ? Theme.muted : Theme.text)
                        .strikethrough(isComplete && !hasEpisodes, color: Color.white.opacity(0.2))
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if hasEpisodes {
                        Button { withAnimation { expanded.toggle() } } label: {
                            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Theme.muted)
                                .padding(.horizontal, 7).padding(.vertical, 4)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.hairline, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }

                BadgeRow(universe: universe, entry: entry,
                         hasEpisodes: hasEpisodes,
                         watchedEpisodes: watchedEpisodes)
                    .padding(.top, 4)

                if hasEpisodes, let n = entry.episodes {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 999).fill(Color.white.opacity(0.05))
                            RoundedRectangle(cornerRadius: 999)
                                .fill(color)
                                .frame(width: geo.size.width * (n == 0 ? 0 : Double(watchedEpisodes) / Double(n)))
                                .shadow(color: color.opacity(0.5), radius: 4)
                        }
                    }
                    .frame(height: 2)
                    .padding(.top, 8)
                }

                if let note = entry.note {
                    Text(note)
                        .font(.system(size: 12))
                        .italic()
                        .foregroundStyle(Theme.muted)
                        .lineLimit(2)
                        .padding(.top, 6)
                }

                if hasEpisodes && expanded, let n = entry.episodes {
                    LazyVGrid(columns: episodeGridColumns, spacing: 4) {
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
                                        .stroke(watched ? color : Theme.hairline, lineWidth: 1))
                                    .foregroundStyle(watched ? Theme.text : Theme.muted)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 10)
                }
            }
            .padding(EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14))
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCorner)
                    .fill(cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCorner).stroke(borderColor, lineWidth: borderWidth)
            )
            .contentShape(Rectangle())
            .onTapGesture { onToggleEntry() }
        }
        .padding(.bottom, 8)
    }

    private var cardBackground: Color {
        if isCrossover { return Theme.surface2 }
        if isComplete  { return Color.white.opacity(0.02) }
        return Theme.surface
    }
    private var borderColor: Color {
        if isCrossover { return universe.accentColor.opacity(0.4) }
        if isComplete  { return Theme.hairline }
        return Theme.hairlineStrong
    }
    private var borderWidth: CGFloat { isCrossover ? 1.5 : 1 }
    private var episodeGridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 4), count: 6)
    }
}

// MARK: - Badge row

private struct BadgeRow: View {
    let universe: Universe
    let entry: Entry
    let hasEpisodes: Bool
    let watchedEpisodes: Int

    var body: some View {
        HStack(spacing: 8) {
            Text(String(entry.year))
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.muted)

            Circle().fill(Theme.muted).frame(width: 3, height: 3)

            switch entry.type {
            case .movie:
                Badge(text: "Movie",
                      foreground: Color.fromHex("#9bbcff") ?? .blue,
                      background: Color(red: 0.48, green: 0.67, blue: 1.0).opacity(0.10))
            case .series:
                Badge(text: "Series",
                      foreground: Color.fromHex("#7affd4") ?? .green,
                      background: Color(red: 0.48, green: 1.0, blue: 0.83).opacity(0.10))
            case .crossover:
                Badge(text: "Crossover",
                      foreground: universe.accentColor,
                      background: universe.accentColor.opacity(0.22))
            }

            if let show = universe.showBadge(for: entry) {
                let c = universe.showColor(for: entry)
                Badge(text: show, foreground: c, background: c.opacity(0.20), tracking: 0.4)
            }

            if hasEpisodes, let n = entry.episodes {
                Circle().fill(Theme.muted).frame(width: 3, height: 3)
                Text("\(watchedEpisodes)/\(n) eps")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.textDim)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct Badge: View {
    let text: String
    let foreground: Color
    let background: Color
    var tracking: CGFloat = 0.5

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10.5, weight: .bold))
            .tracking(tracking)
            .padding(.horizontal, 7).padding(.vertical, 2)
            .background(background, in: RoundedRectangle(cornerRadius: 4))
            .foregroundStyle(foreground)
            .lineLimit(1)
    }
}

// MARK: - Phase header

struct PhaseHeader: View {
    let phase: String
    let count: Int
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            Text(phase.uppercased())
                .font(.system(size: 11, weight: .heavy))
                .tracking(2)
                .foregroundStyle(accent)
            LinearGradient(
                colors: [accent.opacity(0.33), .clear],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 1)
            Text("\(count)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.muted)
                .padding(.horizontal, 8).padding(.vertical, 2)
                .background(Theme.surface, in: Capsule())
                .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
        }
        .padding(.vertical, 4)
    }
}
