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
    static let bg       = Color.fromHex("#0d0d0f")!
    static let surface  = Color.fromHex("#18181c")!
    static let surface2 = Color.fromHex("#222228")!
    static let border   = Color.fromHex("#2e2e38")!
    static let text     = Color.fromHex("#e8e8f0")!
    static let muted    = Color.fromHex("#888899")!

    static let cardCorner: CGFloat = 14
    static let pillCorner: CGFloat = 999
}
