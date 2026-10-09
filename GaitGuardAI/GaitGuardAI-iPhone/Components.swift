import SwiftUI
import Combine
import UniformTypeIdentifiers

/// Coloured status pill with a dot.
struct StatusPill: View {
    let text: String
    let color: Color
    var pulsing = false

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .symbolEffect(.pulse, isActive: pulsing)
                .opacity(pulsing ? 1 : 0.9)
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(GGTheme.cardRaised, in: Capsule())
    }
}

// MARK: - Data helpers

extension Array where Element == AssistEvent {
    func on(_ day: Date, calendar: Calendar = .current) -> [AssistEvent] {
        filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
    }

    nonisolated var csv: String {
        let iso = ISO8601DateFormatter()
        var rows = ["timestamp,type,severity,duration_seconds"]
        for e in sorted(by: { $0.timestamp < $1.timestamp }) {
            rows.append("\(iso.string(from: e.timestamp)),\(e.type),\(String(format: "%.2f", e.severity)),\(e.duration.map { String(format: "%.2f", $0) } ?? "")")
        }
        return rows.joined(separator: "\n")
    }
}

/// History export for ShareLink.
nonisolated struct CSVExport: Transferable {
    let events: [AssistEvent]

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { export in
            Data(export.events.csv.utf8)
        }
        .suggestedFileName("GaitGuard-history.csv")
    }
}

func formatDuration(_ interval: TimeInterval) -> String {
    let total = max(0, Int(interval))
    let h = total / 3600, m = (total % 3600) / 60, s = total % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
}

// MARK: - Ink & ember identity

extension View {
    /// Flat matte card used across the iPhone app.
    func ggSurface(radius: CGFloat = GGTheme.radius) -> some View {
        background(GGTheme.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

/// Flat warm-charcoal canvas with the faintest ember warmth rising from the bottom.
struct GGBackdrop: View {
    var tint: Color = GGTheme.accent

    var body: some View {
        ZStack {
            GGTheme.bg
            LinearGradient(colors: [.clear, tint.opacity(0.07)], startPoint: .center, endPoint: .bottom)
        }
        .ignoresSafeArea()
    }
}

// MARK: Custom shapes & glyphs

struct ArrowGlyph: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.move(to: CGPoint(x: r.minX + r.width * 0.2, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - r.height * 0.2))
        return p
    }
}

enum TabGlyphKind { case home, history, trends, settings }

struct TabGlyph: View {
    let kind: TabGlyphKind
    let color: Color

    var body: some View {
        Canvas { gc, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let st = StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
            switch kind {
            case .home:
                gc.stroke(Path(ellipseIn: CGRect(x: c.x - 9, y: c.y - 9, width: 18, height: 18)), with: .color(color), style: st)
                gc.fill(Path(ellipseIn: CGRect(x: c.x - 2.5, y: c.y - 2.5, width: 5, height: 5)), with: .color(color))
                var n = Path(); n.move(to: CGPoint(x: c.x, y: c.y - 9)); n.addLine(to: CGPoint(x: c.x, y: c.y - 5.5))
                gc.stroke(n, with: .color(color), style: st)
            case .history:
                for (i, w) in [16.0, 10.0, 13.0].enumerated() {
                    let y = c.y - 7 + Double(i) * 7
                    var p = Path(); p.move(to: CGPoint(x: c.x - 9, y: y)); p.addLine(to: CGPoint(x: c.x - 9 + w, y: y))
                    gc.stroke(p, with: .color(color), style: st)
                }
                gc.fill(Path(ellipseIn: CGRect(x: c.x + 5, y: c.y - 9, width: 4, height: 4)), with: .color(color))
            case .trends:
                var p = Path()
                p.move(to: CGPoint(x: c.x - 10, y: c.y + 2))
                p.addCurve(to: CGPoint(x: c.x, y: c.y), control1: CGPoint(x: c.x - 6, y: c.y - 10), control2: CGPoint(x: c.x - 4, y: c.y - 10))
                p.addCurve(to: CGPoint(x: c.x + 10, y: c.y - 2), control1: CGPoint(x: c.x + 4, y: c.y + 10), control2: CGPoint(x: c.x + 6, y: c.y + 10))
                gc.stroke(p, with: .color(color), style: st)
            case .settings:
                for (i, k) in [-0.35, 0.4].enumerated() {
                    let y = c.y - 5 + Double(i) * 10
                    var p = Path(); p.move(to: CGPoint(x: c.x - 10, y: y)); p.addLine(to: CGPoint(x: c.x + 10, y: y))
                    gc.stroke(p, with: .color(color), style: st)
                    gc.fill(Path(ellipseIn: CGRect(x: c.x + 10 * k - 3.2, y: y - 3.2, width: 6.4, height: 6.4)), with: .color(color))
                }
            }
        }
        .frame(width: 24, height: 24)
    }
}

// MARK: Navigation

extension AppTab {
    var title: String {
        switch self {
        case .summary: "Home"
        case .history: "History"
        case .trends: "Trends"
        case .settings: "Tune"
        }
    }
    var glyph: TabGlyphKind {
        switch self {
        case .summary: .home
        case .history: .history
        case .trends: .trends
        case .settings: .settings
        }
    }
}

/// Floating liquid-glass bar. The active tab opens into an ember pill that carries its name.
struct GGTabBar: View {
    @Binding var tab: AppTab
    @Namespace private var pill

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 2) {
                ForEach(AppTab.allCases, id: \.self) { t in
                    let selected = tab == t
                    Button {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { tab = t }
                    } label: {
                        HStack(spacing: 8) {
                            TabGlyph(kind: t.glyph, color: selected ? GGTheme.bg : GGTheme.text1.opacity(0.8))
                            if selected {
                                Text(t.title)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(GGTheme.bg)
                                    .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))
                            }
                        }
                        .padding(.horizontal, selected ? 18 : 15)
                        .frame(height: 50)
                        .background {
                            if selected {
                                Capsule().fill(GGTheme.accent)
                                    .matchedGeometryEffect(id: "pill", in: pill)
                                    .shadow(color: GGTheme.accent.opacity(0.45), radius: 14, y: 4)
                            }
                        }
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(t.title)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(6)
            .glassEffect(.regular.interactive(), in: Capsule())
        }
        .sensoryFeedback(.selection, trigger: tab)
        .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
    }
}

// MARK: Headers

struct ScreenHeader<Trailing: View>: View {
    let eyebrow: String
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.8)
                    .foregroundStyle(GGTheme.accent)
                Spacer()
                trailing
            }
            .frame(minHeight: 36)
            Text(title)
                .font(.system(size: 40, weight: .medium, design: .serif))
                .tracking(-1)
                .foregroundStyle(GGTheme.text1)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 22)
        .padding(.top, 6)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GGTheme.bg)
    }
}

/// Mild / Moderate / Strong marker for a cue.
struct SeverityChip: View {
    let severity: Double

    private var info: (String, Color) {
        severity >= 0.66 ? ("Strong", GGTheme.danger)
        : severity >= 0.33 ? ("Moderate", GGTheme.cue)
        : ("Mild", GGTheme.good)
    }

    var body: some View {
        Text(info.0)
            .font(.caption2.weight(.bold))
            .foregroundStyle(info.1)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(info.1.opacity(0.16), in: Capsule())
    }
}

// MARK: - Controls

struct GGRule: View {
    var body: some View {
        Rectangle().fill(GGTheme.separator).frame(height: 1)
    }
}

struct GGChip: View {
    let title: String
    let on: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(on ? GGTheme.bg : GGTheme.text2)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(on ? GGTheme.text1 : GGTheme.card, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

/// Segmented control drawn as one pill track.
struct GGSegmented<T: Hashable>: View {
    let options: [(value: T, title: String)]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { opt in
                let on = opt.value == selection
                Button {
                    withAnimation(.snappy(duration: 0.25)) { selection = opt.value }
                } label: {
                    Text(opt.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(on ? GGTheme.bg : GGTheme.text2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(on ? GGTheme.text1 : .clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(3)
        .background(GGTheme.card, in: Capsule())
        .sensoryFeedback(.selection, trigger: selection)
    }
}

struct GGSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    private let knob: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let frac = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            ZStack(alignment: .leading) {
                Capsule().fill(GGTheme.cardRaised).frame(height: 6)
                Capsule().fill(GGTheme.accent)
                    .frame(width: max(knob / 2, frac * (w - knob) + knob / 2), height: 6)
                Circle().fill(GGTheme.text1)
                    .frame(width: knob, height: knob)
                    .shadow(color: .black.opacity(0.5), radius: 5, y: 2)
                    .offset(x: frac * (w - knob))
            }
            .frame(height: knob)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { g in
                    let f = min(max((g.location.x - knob / 2) / (w - knob), 0), 1)
                    let raw = range.lowerBound + f * (range.upperBound - range.lowerBound)
                    let stepped = (raw / step).rounded() * step
                    value = min(max(stepped, range.lowerBound), range.upperBound)
                }
            )
        }
        .frame(height: knob)
        .sensoryFeedback(.selection, trigger: value)
        .accessibilityRepresentation {
            Slider(value: $value, in: range, step: step)
        }
    }
}

struct GGToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.snappy(duration: 0.25)) { isOn.toggle() }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule().fill(isOn ? GGTheme.accent : GGTheme.cardRaised).frame(width: 54, height: 32)
                Circle().fill(isOn ? GGTheme.text1 : GGTheme.text2).frame(width: 26, height: 26).padding(3)
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isOn)
        .accessibilityLabel("Toggle")
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

struct RoundGlyphButton: View {
    enum Kind { case minus, plus }
    let kind: Kind
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Canvas { gc, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                var p = Path()
                p.move(to: CGPoint(x: c.x - 6, y: c.y)); p.addLine(to: CGPoint(x: c.x + 6, y: c.y))
                if kind == .plus { p.move(to: CGPoint(x: c.x, y: c.y - 6)); p.addLine(to: CGPoint(x: c.x, y: c.y + 6)) }
                gc.stroke(p, with: .color(GGTheme.text1), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            }
            .frame(width: 46, height: 46)
            .background(GGTheme.cardRaised, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(kind == .plus ? "Increase" : "Decrease")
    }
}

// MARK: - App chrome

/// Lets a full-screen flow (like calibration) slide the floating tab bar out of the way.
final class GGChrome: ObservableObject {
    static let shared = GGChrome()
    @Published var hidesTabBar = false
}

private struct HidesTabBar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear { withAnimation(.snappy) { GGChrome.shared.hidesTabBar = true } }
            .onDisappear { withAnimation(.snappy) { GGChrome.shared.hidesTabBar = false } }
    }
}

extension View {
    /// Hide the floating tab bar while this screen is showing.
    func hidesTabBar() -> some View { modifier(HidesTabBar()) }
}

/// Plays a short run of evenly spaced taps on the iPhone so you can feel a tempo.
enum HapticBeat {
    @MainActor
    static func play(tempo: Double, beats: Int = 4, onBeat: ((Int) -> Void)? = nil) async {
        let gen = UIImpactFeedbackGenerator(style: .rigid)
        gen.prepare()
        let interval = 60.0 / max(60, min(140, tempo))
        for i in 0..<beats {
            gen.impactOccurred(intensity: 0.9)
            onBeat?(i)
            try? await Task.sleep(for: .seconds(interval))
        }
    }
}

/// Primary call-to-action: a solid ember capsule.
struct GGPrimaryButton: View {
    let title: String
    var enabled = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(GGTheme.bg)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(enabled ? GGTheme.accent : GGTheme.cardRaised, in: Capsule())
                .shadow(color: enabled ? GGTheme.accent.opacity(0.35) : .clear, radius: 14, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .animation(.snappy, value: enabled)
    }
}

/// Quiet secondary action: ember outline.
struct GGSecondaryButton: View {
    let title: String
    var tint: Color = GGTheme.accent
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .overlay(Capsule().strokeBorder(tint.opacity(0.8), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

/// Round back button with a drawn chevron.
struct GGBackButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Canvas { gc, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                var p = Path()
                p.move(to: CGPoint(x: c.x + 3, y: c.y - 7)); p.addLine(to: CGPoint(x: c.x - 4, y: c.y)); p.addLine(to: CGPoint(x: c.x + 3, y: c.y + 7))
                gc.stroke(p, with: .color(GGTheme.text1), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
            }
            .frame(width: 40, height: 40)
            .background(GGTheme.card, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
}
