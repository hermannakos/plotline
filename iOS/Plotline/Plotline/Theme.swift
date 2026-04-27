import SwiftUI

extension Color {
    static func fromHex(_ hex: String) -> Color? {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8)  & 0xFF) / 255
        let b = Double( v        & 0xFF) / 255
        return Color(red: r, green: g, blue: b)
    }
}

enum Theme {
    // Surfaces
    static let bg              = Color.fromHex("#08080b")!
    static let bgElev          = Color.fromHex("#0e0e12")!
    static let surface         = Color.fromHex("#15151b")!
    static let surface2        = Color.fromHex("#1c1c24")!
    static let hairline        = Color.white.opacity(0.06)
    static let hairlineStrong  = Color.white.opacity(0.10)

    // Text
    static let text     = Color.fromHex("#f1f1f5")!
    static let textDim  = Color.fromHex("#a0a0ad")!
    static let muted    = Color.fromHex("#6a6a78")!

    // Plotline neon (matches icon + splash)
    static let neon     = Color(.sRGB, red: 0.99, green: 0.72, blue: 0.20, opacity: 1)
    static let neonDeep = Color(.sRGB, red: 0.92, green: 0.58, blue: 0.12, opacity: 1)
    static let neonGlow = Color(.sRGB, red: 1.00, green: 0.80, blue: 0.30, opacity: 1)

    // Legacy alias kept so existing references stay valid.
    static let border   = hairlineStrong

    static let cardCorner: CGFloat = 12
    static let cardCornerLg: CGFloat = 18
    static let pillCorner: CGFloat = 999
}
