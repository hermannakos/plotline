// SplashView.swift — Plotline launch animation
//
// Visual goal: trace the app icon — five circle nodes connected by an
// orange polyline that climbs from lower-left to upper-right, with the
// final node rendered as a bullseye, then the wordmark fades in below.

import SwiftUI

struct SplashView: View {
    @State private var drawProgress: CGFloat = 0
    @State private var nodeReveal: Int = 0          // number of nodes shown
    @State private var bullseyeScale: CGFloat = 0
    @State private var wordOpacity: Double = 0

    // Normalized inside a square chart area, matching the icon layout.
    private let points: [CGPoint] = [
        .init(x: 0.18, y: 0.74),
        .init(x: 0.36, y: 0.55),
        .init(x: 0.52, y: 0.65),
        .init(x: 0.68, y: 0.40),
        .init(x: 0.84, y: 0.26)
    ]

    private let lineColor = Color(red: 0xCC/255.0, green: 0x50/255.0, blue: 0x00/255.0)   // #CC5000 — sampled from icon
    private let nodeFill  = Color(red: 0xF0/255.0, green: 0xE8/255.0, blue: 0xD8/255.0)   // #F0E8D8 — sampled from icon

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) * 0.62
            let stroke = side * 0.045
            let nodeSize = side * 0.10
            let bullseyeRing = side * 0.16
            let bullseyeDot = side * 0.06

            ZStack {
                RadialGradient(
                    colors: [Color(white: 0.10), Color(white: 0.03)],
                    center: .top, startRadius: 0, endRadius: geo.size.height
                )
                .ignoresSafeArea()

                // ── Icon trace ──────────────────────────────────────────
                ZStack {
                    PolylineShape(normalizedPoints: points)
                        .trim(from: 0, to: drawProgress)
                        .stroke(
                            lineColor,
                            style: StrokeStyle(lineWidth: stroke, lineCap: .round, lineJoin: .round)
                        )

                    ForEach(Array(points.enumerated()), id: \.offset) { idx, pt in
                        let isLast = idx == points.count - 1
                        let visible = idx < nodeReveal
                        let size = isLast ? bullseyeRing : nodeSize

                        ZStack {
                            Circle().fill(nodeFill)
                            Circle().stroke(lineColor, lineWidth: stroke * 0.65)
                            if isLast {
                                Circle()
                                    .fill(lineColor)
                                    .frame(width: bullseyeDot, height: bullseyeDot)
                                    .scaleEffect(bullseyeScale)
                            }
                        }
                        .frame(width: size, height: size)
                        .position(x: pt.x * side, y: pt.y * side)
                        .scaleEffect(visible ? 1 : 0)
                        .opacity(visible ? 1 : 0)
                    }
                }
                .frame(width: side, height: side)
                .position(x: geo.size.width / 2, y: geo.size.height * 0.42)

                // ── Wordmark ────────────────────────────────────────────
                VStack(spacing: 8) {
                    Text("Plotline")
                        .font(.system(size: 42, weight: .bold))
                        .tracking(-1)
                    Text("WATCH IN ORDER")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(.secondary)
                }
                .opacity(wordOpacity)
                .position(x: geo.size.width / 2, y: geo.size.height * 0.72)
            }
            .task { await runAnimation() }
        }
    }

    private func runAnimation() async {
        // Line traces in over 1.0s; nodes pop in roughly as the line reaches each one.
        withAnimation(.easeOut(duration: 1.0)) { drawProgress = 1 }
        try? await Task.sleep(for: .milliseconds(60))
        for i in 1...points.count {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) {
                nodeReveal = i
            }
            try? await Task.sleep(for: .milliseconds(190))
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { bullseyeScale = 1 }
        try? await Task.sleep(for: .milliseconds(150))
        withAnimation(.easeOut(duration: 0.5)) { wordOpacity = 1 }
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
