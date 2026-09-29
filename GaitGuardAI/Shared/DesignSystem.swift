// DesignSystem.swift
// Shared visual language for iPhone + Watch so both surfaces read as one product.
import SwiftUI

enum GGTheme {
    // Surfaces
    static let bg = Color(red: 0.039, green: 0.043, blue: 0.078)        // ink
    static let card = Color(red: 0.075, green: 0.082, blue: 0.133)
    static let cardRaised = Color(red: 0.105, green: 0.114, blue: 0.180)
    static let cardBorder = Color.white.opacity(0.07)

    // Brand: indigo → violet. Amber is reserved for haptic cues/assists.
    static let accent = Color(red: 0.486, green: 0.549, blue: 1.0)      // #7C8CFF
    static let accentSecondary = Color(red: 0.71, green: 0.55, blue: 1.0) // #B58CFF
    static let accentDim = accent.opacity(0.15)
    static let cue = Color(red: 1.0, green: 0.71, blue: 0.28)           // #FFB547

    // Text
    static let text1 = Color.white
    static let text2 = Color(white: 0.62)
    static let text3 = Color(white: 0.38)

    // Status
    static let good = Color(red: 0.29, green: 0.87, blue: 0.60)         // #4ADE9A
    static let warn = cue
    static let danger = Color(red: 1.0, green: 0.42, blue: 0.48)        // #FF6B7A

    static let radius: CGFloat = 24

    static var brandGradient: LinearGradient {
        LinearGradient(colors: [accent, accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Single source of truth for score → colour, used by iPhone ring and Watch ring.
    static func scoreColor(_ score: Int, monitoring: Bool) -> Color {
        guard monitoring else { return accent }
        if score >= 85 { return good }
        if score >= 65 { return accent }
        if score >= 40 { return cue }
        return danger
    }

    static func assistColor(_ type: String) -> Color {
        type == "turn" ? accentSecondary : cue
    }
}

/// Circular gauge used for the gait score on both platforms.
struct GGScoreRing: View {
    let score: Int?
    let label: String
    let color: Color
    var size: CGFloat = 180
    var lineWidth: CGFloat = 12
    var caption: String = "GAIT SCORE"

    private var progress: Double { Double(score ?? 0) / 100.0 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: [color.opacity(0.35), color],
                                    center: .center, startAngle: .degrees(0), endAngle: .degrees(360 * max(progress, 0.01))),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.35), radius: 10)
                .animation(.spring(response: 0.8, dampingFraction: 0.85), value: progress)

            VStack(spacing: size < 120 ? 0 : 2) {
                Text(caption)
                    .font(.system(size: size < 120 ? 8 : 11, weight: .semibold, design: .rounded))
                    .tracking(1.4)
                    .foregroundColor(GGTheme.text2)
                if let score {
                    Text("\(score)")
                        .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                        .foregroundColor(GGTheme.text1)
                        .contentTransition(.numericText())
                } else {
                    Text("Ready")
                        .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                        .foregroundColor(GGTheme.accent)
                }
                Text(label)
                    .font(.system(size: size < 120 ? 10 : 14, weight: .semibold, design: .rounded))
                    .foregroundColor(color)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(score.map { "Gait score \($0), \(label)" } ?? "Ready")
    }
}

/// Card container shared by iPhone screens.
struct GGCard<Content: View>: View {
    var tint: Color? = nil
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(GGTheme.card, in: RoundedRectangle(cornerRadius: GGTheme.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: GGTheme.radius, style: .continuous)
                    .stroke((tint ?? .white).opacity(tint == nil ? 0.07 : 0.22), lineWidth: 1)
            )
    }
}
