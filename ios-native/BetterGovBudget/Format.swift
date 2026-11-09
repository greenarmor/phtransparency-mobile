import SwiftUI

enum Peso {
    /// "₱1.23 B" style; nil renders a dash (no such line, never zero).
    static func short(_ v: Double?) -> String {
        guard let v else { return "–" }
        let a = abs(v), s = v < 0 ? "-" : ""
        switch a {
        case 1e12...: return "\(s)₱\(String(format: "%.2f", a / 1e12)) T"
        case 1e9...: return "\(s)₱\(String(format: "%.2f", a / 1e9)) B"
        case 1e6...: return "\(s)₱\(String(format: "%.1f", a / 1e6)) M"
        default: return "\(s)₱\(Int(a).formatted())"
        }
    }
    static func delta(_ v: Double?) -> String {
        guard let v else { return "–" }
        return (v > 0 ? "+" : "") + short(v)
    }
}

enum Palette {
    static let ink = Color(red: 0.07, green: 0.09, blue: 0.16)
    static let red = Color(red: 0.80, green: 0.10, blue: 0.16)
    static let navy = Color(red: 0.05, green: 0.20, blue: 0.45)
    static let green = Color(red: 0.10, green: 0.50, blue: 0.28)
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.91)
    /// Any changed group reads red; only "same amount in both" is green.
    static func group(_ g: String?) -> Color {
        switch g {
        case "unchanged": return green
        case "scope_review": return .gray
        case nil: return .secondary
        default: return red
        }
    }
}

func openExternal(_ s: String?) {
    guard let s, let u = URL(string: s), ["http", "https"].contains(u.scheme?.lowercased()) else { return }
    UIApplication.shared.open(u)
}
