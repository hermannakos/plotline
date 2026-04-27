// SplashView.swift — Plotline launch animation
//
// Visual goal: trace the neon path from the icon into life with the same
// glow language as PlotlineMark — outer halo, gradient stroke, bullseye
// pulse. Wordmark uses the in-app Theme tracking so the splash feels like
// the first frame of the home screen, not a separate brand moment.

import SwiftUI

struct SplashView: View {
    @State private var drawProgress: CGFloat = 0
    @State private var glowOpacity: Double = 0
    @State private var nodeReveal: Int = 0
    @State private var bullseyePulse: CGFloat = 0
    @State private var bullseyeRing: CGFloat = 0
    @State private var wordOpacity: Double = 0
    @State private var wordOffset: CGFloat = 8
    @State private var vignettePulse: Double = 0

    // Path matches PlotlineMark exactly so the splash and the in-app mark are
    // pixel-aligned; the user reads them as one continuous identity.
    private let points: [CGPoint] = [
        .init(x: 0.215, y: 0.742),
        .init(x: 0.371, y: 0.547),
        .init(x: 0.547, y: 0.625),
        .init(x: 0.605, y: 0.410),
        .init(x: 0.781, y: 0.293)
    ]

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) * 0.58
            let stroke = side * 0.052
            let nodeSize = side * 0.085
            let bullseyeOuter = side * 0.18
            let bullseyeDot = side * 0.07

            ZStack {
                // Deep radial background, matches the home screen scrim.
                RadialGradient(
                    colors: [
                        Color(red: 0.07, green: 0.07, blue: 0.085),
                        Color(red: 0.02, green: 0.02, blue: 0.03)
                    ],
                    center: .center, startRadius: 40, endRadius: max(geo.size.width, geo.size.height)
                )
                .ignoresSafeArea()

                // Soft neon halo behind the mark — pulses with the bullseye.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.neon.opacity(0.22 + vignettePulse * 0.10),
                                .clear
                            ],
                            center: .center, startRadius: 0, endRadius: side * 0.7
                        )
                    )
                    .frame(width: side * 1.6, height: side * 1.6)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.42)
                    .blendMode(.plusLighter)

                // ── Mark ────────────────────────────────────────────
                ZStack {
                    // Outer glow stroke — same trick as PlotlineMark.
                    PolylineShape(normalizedPoints: points)
                        .trim(from: 0, to: drawProgress)
                        .stroke(
                            Theme.neon.opacity(0.55),
                            style: StrokeStyle(lineWidth: stroke * 1.7, lineCap: .round, lineJoin: .round)
                        )
                        .blur(radius: side * 0.05)
                        .opacity(glowOpacity)

                    // Main gradient stroke
                    PolylineShape(normalizedPoints: points)
                        .trim(from: 0, to: drawProgress)
                        .stroke(
                            LinearGradient(
                                colors: [Theme.neonDeep, Theme.neonGlow],
                                startPoint: .bottomLeading, endPoint: .topTrailing
                            ),
                            style: StrokeStyle(lineWidth: stroke, lineCap: .round, lineJoin: .round)
                        )

                    // Nodes
                    ForEach(Array(points.enumerated()), id: \.offset) { idx, pt in
                        let isLast = idx == points.count - 1
                        let visible = idx < nodeReveal
                        let size = isLast ? bullseyeOuter : nodeSize

                        ZStack {
                            if isLast {
                                // Bullseye target — outer ring expands on reveal
                                Circle()
                                    .stroke(Theme.neon.opacity(0.4), lineWidth: stroke * 0.45)
                                    .frame(width: size * (1 + bullseyeRing * 0.6),
                                           height: size * (1 + bullseyeRing * 0.6))
                                    .opacity(1 - Double(bullseyeRing) * 0.7)
                                Circle()
                                    .fill(Theme.bg)
                                    .frame(width: size, height: size)
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Theme.neonDeep, Theme.neonGlow],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        ),
                                        lineWidth: stroke * 0.55
                                    )
                                    .frame(width: size, height: size)
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [Theme.neonGlow, Theme.neon],
                                            center: .center, startRadius: 0, endRadius: bullseyeDot
                                        )
                                    )
                                    .frame(width: bullseyeDot, height: bullseyeDot)
                                    .scaleEffect(0.7 + bullseyePulse * 0.3)
                                    .shadow(color: Theme.neon.opacity(0.7), radius: 6 + bullseyePulse * 4)
                            } else {
                                Circle()
                                    .fill(Theme.bg)
                                    .frame(width: size, height: size)
                                Circle()
                                    .stroke(Theme.neon, lineWidth: stroke * 0.55)
                                    .frame(width: size, height: size)
                                    .shadow(color: Theme.neon.opacity(0.6), radius: 4)
                            }
                        }
                        .position(x: pt.x * side, y: pt.y * side)
                        .scaleEffect(visible ? 1 : 0.2)
                        .opacity(visible ? 1 : 0)
                    }
                }
                .frame(width: side, height: side)
                .position(x: geo.size.width / 2, y: geo.size.height * 0.42)

                // ── Wordmark ────────────────────────────────────────
                VStack(spacing: 10) {
                    Text("Plotline")
                        .font(.system(size: 44, weight: .bold))
                        .tracking(-1.2)
                        .foregroundStyle(Theme.text)
                    Text("WATCH IN ORDER")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(3)
                        .foregroundStyle(Theme.neon.opacity(0.8))
                }
                .opacity(wordOpacity)
                .offset(y: wordOffset)
                .position(x: geo.size.width / 2, y: geo.size.height * 0.74)
            }
            .task { await runAnimation() }
        }
    }

    private func runAnimation() async {
        // 1. Glow blooms in just ahead of the line.
        withAnimation(.easeOut(duration: 0.25)) { glowOpacity = 1 }

        // 2. Line traces.
        withAnimation(.easeInOut(duration: 1.0)) { drawProgress = 1 }
        try? await Task.sleep(for: .milliseconds(80))

        // 3. Nodes pop as the line passes them.
        for i in 1...points.count - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.62)) {
                nodeReveal = i
            }
            try? await Task.sleep(for: .milliseconds(180))
        }

        // 4. Bullseye lands with a ring pulse.
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
            nodeReveal = points.count
        }
        try? await Task.sleep(for: .milliseconds(80))
        withAnimation(.easeOut(duration: 0.7)) { bullseyeRing = 1 }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { bullseyePulse = 1 }

        // 5. Halo continues to breathe softly.
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            vignettePulse = 1
        }

        // 6. Wordmark.
        try? await Task.sleep(for: .milliseconds(180))
        withAnimation(.easeOut(duration: 0.55)) {
            wordOpacity = 1
            wordOffset = 0
        }
    }
}

private struct PolylineShape: Shape {
    let normalizedPoints: [CGPoint]

    func path(in rect: CGRect) -> Path {
        Path { p in
            guard let first = normalizedPoints.first else { return }
            p.move(to: CGPoint(x: first.x * rect.width, y: first.y * rect.height))
            for pt in normalizedPoints.dropFirst() {
                p.addLine(to: CGPoint(x: pt.x * rect.width, y: pt.y * rect.height))
            }
        }
    }
}
