import SwiftUI
import WatchConnectivity

enum GGTheme {
    static let bg = Color(red: 0.04, green: 0.05, blue: 0.09)
    static let card = Color(red: 0.08, green: 0.09, blue: 0.14)
    static let cardBorder = Color.white.opacity(0.06)
    static let accent = Color(red: 0.18, green: 0.87, blue: 0.72)   // teal/mint
    static let accentDim = accent.opacity(0.15)
    static let text1 = Color.white
    static let text2 = Color(white: 0.55)
    static let text3 = Color(white: 0.35)
    static let danger = Color(red: 1.0, green: 0.35, blue: 0.35)
    static let warn = Color.orange
    static let good = Color(red: 0.18, green: 0.87, blue: 0.72)
    static let radius: CGFloat = 20
}

struct ContentView: View {
    @EnvironmentObject var cm: WatchConnectivityManager
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            HomeTab()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            HistoryTab()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(1)
            AnalyticsView()
                .tabItem { Label("Trends", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(2)
            RemoteControlsView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(3)
        }
        .tint(GGTheme.accent)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Home Tab

struct HomeTab: View {
    @EnvironmentObject var cm: WatchConnectivityManager
    @State private var timer: Timer?

    private var gaitScore: Int {
        guard cm.isWatchMonitoring else { return 0 }
        let events = cm.assistEvents.filter {
            Calendar.current.isDateInToday($0.timestamp)
        }.count
        return max(0, 100 - events * 8)
    }

    private var scoreLabel: String {
        if !cm.isWatchMonitoring { return "Idle" }
        if gaitScore >= 85 { return "Excellent" }
        if gaitScore >= 65 { return "Good" }
        if gaitScore >= 40 { return "Fair" }
        return "Needs Attention"
    }

    private var scoreColor: Color {
        if !cm.isWatchMonitoring { return GGTheme.text3 }
        if gaitScore >= 85 { return GGTheme.accent }
        if gaitScore >= 65 { return .green }
        if gaitScore >= 40 { return .orange }
        return GGTheme.danger
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GGTheme.bg.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        GaitScoreRing(
                            score: cm.isWatchMonitoring ? gaitScore : nil,
                            label: scoreLabel,
                            color: scoreColor
                        )
                        .padding(.top, 8)

                        if cm.isWatchMonitoring, let sd = cm.latestStepData {
                            MetricStrip(stepData: sd)
                        }

                        StabilityCard(cm: cm)

                        StatusPill(cm: cm)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("GaitGuard")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                cm.updateConnectionStatus()
                timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                    cm.updateConnectionStatus()
                    _ = cm.wcSession?.isReachable
                }
            }
            .onDisappear { timer?.invalidate(); timer = nil }
        }
    }
}

// MARK: - Gait Score Ring

struct GaitScoreRing: View {
    let score: Int?
    let label: String
    let color: Color

    private var progress: Double {
        guard let s = score else { return 0 }
        return Double(s) / 100.0
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(GGTheme.text3.opacity(0.2), lineWidth: 10)
                    .frame(width: 180, height: 180)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [color.opacity(0.5), color],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360 * progress)
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: progress)

                VStack(spacing: 2) {
                    Text("GAIT SCORE")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .tracking(1.5)
                        .foregroundColor(GGTheme.text2)

                    if let s = score {
                        Text("\(s)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(GGTheme.text1)
                            .contentTransition(.numericText())
                    } else {
                        Text("--")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(GGTheme.text3)
                    }
                }
            }

            Text(label)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
    }
}

// MARK: - Metric Strip

struct MetricStrip: View {
    let stepData: StepData

    var body: some View {
        HStack(spacing: 0) {
            MetricColumn(
                value: stepData.cadence.map { String(format: "%.0f", $0) } ?? "--",
                unit: "spm",
                label: "CADENCE"
            )
            Divider()
                .frame(height: 40)
                .background(GGTheme.text3.opacity(0.3))
            MetricColumn(
                value: stepData.distance.map { String(format: "%.2f", $0) } ?? "--",
                unit: "m",
                label: "STRIDE"
            )
        }
        .padding(.vertical, 16)
        .background(GGTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: GGTheme.radius))
        .overlay(
            RoundedRectangle(cornerRadius: GGTheme.radius)
                .stroke(GGTheme.cardBorder, lineWidth: 1)
        )
    }
}

struct MetricColumn: View {
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(GGTheme.text1)
                Text(unit)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(GGTheme.text2)
            }
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundColor(GGTheme.text2)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stability Card

struct StabilityCard: View {
    @ObservedObject var cm: WatchConnectivityManager

    private var isStable: Bool {
        let recent = cm.assistEvents.filter {
            Date().timeIntervalSince($0.timestamp) < 300
        }
        return recent.isEmpty
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Stability Analysis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(GGTheme.text1)
                Text(cm.isWatchMonitoring
                     ? (isStable ? "Optimal gait pattern" : "Freeze events detected")
                     : "Start monitoring to analyze")
                    .font(.system(size: 13))
                    .foregroundColor(GGTheme.text2)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(cm.isWatchMonitoring
                          ? (isStable ? GGTheme.accent.opacity(0.15) : GGTheme.warn.opacity(0.15))
                          : GGTheme.text3.opacity(0.1))
                    .frame(width: 38, height: 38)
                Image(systemName: cm.isWatchMonitoring
                      ? (isStable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                      : "moon.zzz.fill")
                    .font(.system(size: 18))
                    .foregroundColor(cm.isWatchMonitoring
                                     ? (isStable ? GGTheme.accent : GGTheme.warn)
                                     : GGTheme.text3)
            }
        }
        .padding(18)
        .background(GGTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: GGTheme.radius))
        .overlay(
            RoundedRectangle(cornerRadius: GGTheme.radius)
                .stroke(GGTheme.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Status Pill

struct StatusPill: View {
    @ObservedObject var cm: WatchConnectivityManager

    private var color: Color {
        if cm.isWatchMonitoring { return GGTheme.accent }
        if cm.isWatchReachable { return .green }
        if cm.isWatchConnected { return .orange }
        return GGTheme.text3
    }

    private var label: String {
        if cm.isWatchMonitoring { return "MONITORING" }
        if cm.isWatchReachable { return "CONNECTED" }
        if cm.isWatchConnected { return "PAIRED" }
        return "NOT CONNECTED"
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(1)
                .foregroundColor(color)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - History Tab

struct HistoryTab: View {
    @EnvironmentObject var cm: WatchConnectivityManager

    var body: some View {
        NavigationStack {
            ZStack {
                GGTheme.bg.ignoresSafeArea()

                if cm.assistEvents.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(GGTheme.text3)
                        Text("No Events Yet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(GGTheme.text1)
                        Text("When freeze events are detected they will appear here.")
                            .font(.system(size: 14))
                            .foregroundColor(GGTheme.text2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(cm.assistEvents.reversed()) { event in
                                HistoryRow(event: event)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !cm.assistEvents.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") {
                            withAnimation { cm.clearEvents() }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(GGTheme.text2)
                    }
                }
            }
        }
    }
}

struct HistoryRow: View {
    let event: AssistEvent

    private var severityColor: Color {
        if event.severity < 0.33 { return GGTheme.accent }
        if event.severity < 0.66 { return .orange }
        return GGTheme.danger
    }

    private var severityLabel: String {
        if event.severity < 0.33 { return "Low" }
        if event.severity < 0.66 { return "Med" }
        return "High"
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(event.type == "start" ? Color.blue.opacity(0.12) : Color.orange.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: event.type == "start" ? "figure.walk" : "arrow.turn.up.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(event.type == "start" ? .blue : .orange)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("\(event.type.capitalized) Assist")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(GGTheme.text1)
                HStack(spacing: 6) {
                    Text(event.timestamp, style: .time)
                    if let d = event.duration {
                        Text("· \(String(format: "%.1fs", d))")
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(GGTheme.text2)
            }

            Spacer()

            Text(severityLabel)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(severityColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(severityColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(14)
        .background(GGTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(GGTheme.cardBorder, lineWidth: 1)
        )
    }
}
