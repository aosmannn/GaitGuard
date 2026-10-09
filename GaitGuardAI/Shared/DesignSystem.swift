// DesignSystem.swift
// Shared visual language for iPhone + Watch so both surfaces read as one product.
// iPhone follows the system appearance (light/dark) like Apple Health; watchOS is always dark.
import SwiftUI
#if os(iOS)
import UIKit
#endif

enum GGTheme {
    // MARK: Surfaces & text

    #if os(iOS)
    // Matte "ink & ember": warm charcoal, bone text, one hot signal colour. No gloss.
    static let bg = Color(hex: 0x12100E)
    static let card = Color(hex: 0x1C1917)
    static let cardRaised = Color(hex: 0x27231F)
    static let text1 = Color(hex: 0xF4EEE6)
    static let text2 = Color(hex: 0xA39A90)
    static let text3 = Color(hex: 0x6B635B)
    static let separator = Color(hex: 0x2E2925)
    #else
    static let bg = Color(hex: 0x12100E)
    static let card = Color(hex: 0x1C1917)
    static let cardRaised = Color(hex: 0x27231F)
    static let text1 = Color(hex: 0xF4EEE6)
    static let text2 = Color(hex: 0xA39A90)
    static let text3 = Color(hex: 0x6B635B)
    static let separator = Color(hex: 0x2E2925)
    #endif

    // MARK: Brand & categories
    // Ember is the brand. Amber marks start cues, dusk blue marks turn cues, sage means good.

    static let accent = dynamic(light: 0xE0592A, dark: 0xFF7A4D)
    static let accentSecondary = dynamic(light: 0x5C7BA8, dark: 0x9DB4D6)
    static let cue = dynamic(light: 0xD9962B, dark: 0xF2B35E)
    static let good = dynamic(light: 0x5E9A52, dark: 0xA6CC9A)
    static let danger = dynamic(light: 0xD93636, dark: 0xFF5C5C)

    static let radius: CGFloat = 26

    /// Single source of truth for score → colour, used by iPhone ring and Watch ring.
    static func scoreColor(_ score: Int, monitoring: Bool) -> Color {
        guard monitoring else { return accent }
        if score >= 85 { return good }
        if score >= 65 { return Color(hex: 0xE8C9A0) }
        if score >= 40 { return cue }
        return danger
    }

    static func assistColor(_ type: String) -> Color {
        type == "turn" ? accentSecondary : cue
    }

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        #if os(iOS)
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
        #else
        Color(hex: dark)
        #endif
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

#if os(iOS)
extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}
#endif

// MARK: - Shared hero pieces (iPhone + Watch)

/// Tracked, quiet section label ("CUES TODAY").
struct GGLabel: View {
    let text: String
    var color: Color = GGTheme.text3

    init(_ text: String, color: Color = GGTheme.text3) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(1.6)
            .foregroundStyle(color)
    }
}


struct RoundedTriangle: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height, k: CGFloat = 0.14
        var p = Path()
        p.move(to: CGPoint(x: 0, y: h * k))
        p.addQuadCurve(to: CGPoint(x: w * k * 1.4, y: h * 0.08), control: CGPoint(x: 0, y: h * 0.02))
        p.addLine(to: CGPoint(x: w * 0.96, y: h * 0.46))
        p.addQuadCurve(to: CGPoint(x: w * 0.96, y: h * 0.54), control: CGPoint(x: w, y: h * 0.5))
        p.addLine(to: CGPoint(x: w * k * 1.4, y: h * 0.92))
        p.addQuadCurve(to: CGPoint(x: 0, y: h * (1 - k)), control: CGPoint(x: 0, y: h * 0.98))
        p.closeSubpath()
        return p
    }
}


/// Start cue = three rising beats. Turn cue = a bent beat.
struct CueGlyph: View {
    let turn: Bool
    let color: Color

    var body: some View {
        Canvas { gc, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            if turn {
                var p = Path()
                p.move(to: CGPoint(x: c.x - 7, y: c.y + 7))
                p.addLine(to: CGPoint(x: c.x - 7, y: c.y - 2))
                p.addQuadCurve(to: CGPoint(x: c.x + 1, y: c.y - 8), control: CGPoint(x: c.x - 7, y: c.y - 8))
                p.addLine(to: CGPoint(x: c.x + 7, y: c.y - 8))
                gc.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
            } else {
                for (i, h) in [7.0, 12.0, 17.0].enumerated() {
                    var p = Path()
                    let x = c.x - 7 + Double(i) * 7
                    p.move(to: CGPoint(x: x, y: c.y + h / 2))
                    p.addLine(to: CGPoint(x: x, y: c.y - h / 2))
                    gc.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }
            }
        }
    }
}


// MARK: The tick dial

/// 60 ticks like a metronome bezel. Filled ticks are the gait score; one ember tick sweeps at the cue tempo.
struct TickDial<Center: View>: View {
    let monitoring: Bool
    let score: Int?
    let tempo: Double
    let color: Color
    var size: CGFloat = 280
    @ViewBuilder var center: Center
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let revsPerSec = monitoring ? max(0.1, tempo / 60.0 / 8.0) : 0.05
            let sweep = reduceMotion ? 0 : (t * revsPerSec).truncatingRemainder(dividingBy: 1) * 60
            let filled = monitoring ? Int((Double(score ?? 0) / 100.0 * 60.0).rounded()) : 0

            ZStack {
                Canvas { gc, sz in
                    let c = CGPoint(x: sz.width / 2, y: sz.height / 2)
                    let r = min(sz.width, sz.height) / 2 - 3
                    for i in 0..<60 {
                        let a = Double(i) / 60.0 * 2 * .pi - .pi / 2
                        let major = i % 5 == 0
                        var d = abs(Double(i) - sweep)
                        d = min(d, 60 - d)
                        let heat = max(0, 1 - d / 5)
                        let k = min(sz.width, sz.height) / 290
                        let len: CGFloat = ((major ? 20 : 12) + CGFloat(heat) * 12) * k
                        let isFilled = i < filled
                        func pt(_ rad: CGFloat) -> CGPoint { CGPoint(x: c.x + cos(a) * rad, y: c.y + sin(a) * rad) }
                        var p = Path()
                        p.move(to: pt(r - len)); p.addLine(to: pt(r))
                        let base: Color = isFilled ? color : GGTheme.text3.opacity(major ? 0.7 : 0.4)
                        gc.stroke(p, with: .color(base), style: StrokeStyle(lineWidth: (major ? 3.4 : 2.2) * max(k, 0.6), lineCap: .round))
                        if heat > 0.05 {
                            gc.stroke(p, with: .color(GGTheme.accent.opacity(heat)), style: StrokeStyle(lineWidth: (major ? 3.8 : 2.8) * max(k, 0.6), lineCap: .round))
                        }
                    }
                }
                center
                    .foregroundStyle(GGTheme.text1)
            }
            .frame(width: size, height: size)
        }
    }
}

