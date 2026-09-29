import SwiftUI
import WatchConnectivity

enum GGTheme {
    static let bg = Color(red: 0.04, green: 0.05, blue: 0.09)
    static let card = Color(red: 0.08, green: 0.09, blue: 0.14)
    static let cardBorder = Color.white.opacity(0.06)
    /// Matches Watch brand teal
    static let accent = Color(red: 0.18, green: 0.87, blue: 0.72)
    static let accentDim = accent.opacity(0.15)
    static let text1 = Color.white
    static let text2 = Color(white: 0.55)
    static let text3 = Color(white: 0.35)
    static let danger = Color(red: 1.0, green: 0.42, blue: 0.38)
    static let warn = Color.orange
    static let good = Color.green
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
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
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
    @State private var now = Date()
    @State private var remoteActionError = false

    private var todayEvents: [AssistEvent] {
        cm.assistEvents.filter { Calendar.current.isDateInToday($0.timestamp) }
    }
    private var yesterdayEvents: [AssistEvent] {
        cm.assistEvents.filter { Calendar.current.isDateInYesterday($0.timestamp) }
    }

    /// Prefer Watch-sent score; fall back to shared formula when monitoring but no score yet.
    private var gaitScore: Int {
        if let watchScore = cm.latestGaitScore { return watchScore }
        guard cm.isWatchMonitoring else { return 0 }
        let assists = todayEvents.count
        let steps = cm.latestStepData?.stepCount ?? 0
        return GaitScoreCalculator.score(todaysAssists: assists, steps: steps)
    }

    private var scoreLabel: String {
        GaitScoreCalculator.label(for: gaitScore, isMonitoring: cm.isWatchMonitoring)
    }

    private var scoreColor: Color {
        if !cm.isWatchMonitoring { return GGTheme.accent.opacity(0.7) }
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
                    VStack(spacing: 20) {

                        if cm.isWatchMonitoring {
                            GaitScoreRing(
                                score: gaitScore,
                                label: scoreLabel,
                                color: scoreColor,
                                isLive: true
                            )
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                        } else {
                            ReadyStateHero(
                                stopReason: cm.monitoringStopReason,
                                isReachable: cm.isWatchReachable
                            )
                            .padding(.top, 8)
                        }

                        WatchStatusCard(cm: cm, now: now)

                        RemoteMonitorControls(
                            isMonitoring: cm.isWatchMonitoring,
                            isReachable: cm.isWatchReachable,
                            onStart: {
                                if !cm.requestStartMonitoring() {
                                    withAnimation { remoteActionError = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        withAnimation { remoteActionError = false }
                                    }
                                }
                            },
                            onStop: {
                                if !cm.requestStopMonitoring() {
                                    withAnimation { remoteActionError = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        withAnimation { remoteActionError = false }
                                    }
                                }
                            }
                        )

                        if remoteActionError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(GGTheme.warn)
                                Text("Watch not reachable — open GaitGuard on your Watch.")
                                    .font(.system(size: 13))
                                    .foregroundColor(GGTheme.text2)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(GGTheme.warn.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        if cm.isWatchMonitoring {
                            LiveSessionCard(cm: cm, now: now)
                        }

                        TodaySummaryCard(
                            today: todayEvents,
                            yesterday: yesterdayEvents,
                            isMonitoring: cm.isWatchMonitoring
                        )

                        if !todayEvents.isEmpty {
                            RecentFreezeCard(events: todayEvents)
                        }

                        if !cm.isWatchMonitoring && !cm.isWatchReachable {
                            SetupGuideCard()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("GaitGuard")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear { startPolling() }
            .onDisappear { timer?.invalidate(); timer = nil }
        }
    }

    private func startPolling() {
        cm.updateConnectionStatus()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            cm.updateConnectionStatus()
            _ = cm.wcSession?.isReachable
            now = Date()
        }
    }
}

// MARK: - Ready State (idle)

struct ReadyStateHero: View {
    let stopReason: String?
    let isReachable: Bool

    private var reasonText: String? {
        switch stopReason {
        case "battery": return "Monitoring stopped — low battery"
        case "session_expired": return "Monitoring stopped — session ended"
        case "remote": return "Monitoring stopped from iPhone"
        default: return nil
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(GGTheme.accent.opacity(0.2), lineWidth: 6)
                    .frame(width: 120, height: 120)
                Circle()
                    .fill(GGTheme.accent.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "figure.walk")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(GGTheme.accent)
            }

            Text("Ready")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(GGTheme.text1)

            Text(isReachable
                 ? "Start monitoring from here or on your Watch"
                 : "Connect your Watch to begin cueing support")
                .font(.system(size: 14))
                .foregroundColor(GGTheme.text2)
                .multilineTextAlignment(.center)

            if let reasonText {
                Text(reasonText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(GGTheme.warn)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ready. \(reasonText ?? "")")
    }
}

// MARK: - Remote Monitor Controls

struct RemoteMonitorControls: View {
    let isMonitoring: Bool
    let isReachable: Bool
    let onStart: () -> Void
    let onStop: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            if isMonitoring {
                Button(action: onStop) {
                    Label("Stop Monitoring", systemImage: "stop.fill")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(GGTheme.danger.opacity(0.85))
                .disabled(!isReachable)
            } else {
                Button(action: onStart) {
                    Label("Start Monitoring", systemImage: "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(GGTheme.accent)
                .disabled(!isReachable)
            }

            if !isReachable {
                Text("Requires a reachable Apple Watch")
                    .font(.system(size: 12))
                    .foregroundColor(GGTheme.text3)
            }
        }
    }
}

// MARK: - Gait Score Ring

struct GaitScoreRing: View {
    let score: Int?
    let label: String
    let color: Color
    var isLive: Bool = false

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
                    Text(isLive ? "GAIT SCORE" : "STATUS")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .tracking(1.5)
                        .foregroundColor(GGTheme.text2)

                    if let s = score {
                        Text("\(s)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(GGTheme.text1)
                            .contentTransition(.numericText())
                            .accessibilityLabel("Gait score \(s)")
                    } else {
                        Text("Ready")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(GGTheme.accent.opacity(0.8))
                    }
                }
            }

            Text(label)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Watch Status Card

struct WatchStatusCard: View {
    @ObservedObject var cm: WatchConnectivityManager
    let now: Date

    private var statusIcon: String {
        if cm.isWatchMonitoring { return "applewatch.radiowaves.left.and.right" }
        if cm.isWatchReachable { return "applewatch.watchface" }
        if cm.isWatchConnected { return "applewatch" }
        return "applewatch.slash"
    }

    private var statusColor: Color {
        if cm.isWatchMonitoring { return GGTheme.accent }
        if cm.isWatchReachable { return .green }
        if cm.isWatchConnected { return .orange }
        return GGTheme.danger
    }

    private var statusTitle: String {
        if cm.isWatchMonitoring { return "Cueing Active" }
        if let reason = cm.monitoringStopReason {
            switch reason {
            case "battery": return "Stopped — Low Battery"
            case "session_expired": return "Stopped — Session Ended"
            default: break
            }
        }
        if cm.isWatchReachable { return "Watch Connected" }
        if cm.isWatchConnected { return "Watch Paired" }
        return "Watch Not Connected"
    }

    private var statusSubtitle: String {
        if cm.isWatchMonitoring { return "Real-time gait support on Watch" }
        if cm.monitoringStopReason == "battery" {
            return "Charge your Watch, then start again"
        }
        if cm.monitoringStopReason == "session_expired" {
            return "Watch session ended — start again when ready"
        }
        if cm.isWatchReachable { return "Ready to start monitoring" }
        if cm.isWatchConnected { return "Open the GaitGuard Watch app" }
        return "Pair your Apple Watch to get started"
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: statusIcon)
                    .font(.system(size: 22))
                    .foregroundColor(statusColor)
                    .symbolEffect(.pulse, isActive: cm.isWatchMonitoring)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(statusTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(GGTheme.text1)
                Text(statusSubtitle)
                    .font(.system(size: 13))
                    .foregroundColor(GGTheme.text2)

                if let hb = cm.lastHeartbeatTime, cm.isWatchReachable {
                    let ago = now.timeIntervalSince(hb)
                    HStack(spacing: 5) {
                        Circle().fill(GGTheme.accent).frame(width: 5, height: 5)
                        Text(ago < 10 ? "Just now" : "\(Int(ago))s ago")
                            .font(.system(size: 11))
                            .foregroundColor(GGTheme.text3)
                    }
                    .padding(.top, 1)
                }
            }

            Spacer()
        }
        .padding(18)
        .background(GGTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: GGTheme.radius))
        .overlay(
            RoundedRectangle(cornerRadius: GGTheme.radius)
                .stroke(statusColor.opacity(0.2), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(statusTitle). \(statusSubtitle)")
    }
}

// MARK: - Live Session Card

struct LiveSessionCard: View {
    @ObservedObject var cm: WatchConnectivityManager
    let now: Date

    private var sessionMinutes: Int {
        guard let start = cm.sessionStartTime else { return 0 }
        return max(0, Int(now.timeIntervalSince(start) / 60))
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(GGTheme.accent)
                        .frame(width: 8, height: 8)
                    Text("LIVE SESSION")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(GGTheme.accent)
                }
                Spacer()
                Text("\(sessionMinutes) min")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(GGTheme.text2)
            }

            if let sd = cm.latestStepData {
                HStack(spacing: 0) {
                    LiveMetric(
                        value: "\(sd.stepCount)",
                        label: "Steps",
                        icon: "figure.walk"
                    )
                    LiveMetric(
                        value: sd.cadence.map { String(format: "%.0f", $0) } ?? "--",
                        label: "Cadence",
                        icon: "metronome.fill"
                    )
                    LiveMetric(
                        value: sd.distance.map { String(format: "%.1f", $0) } ?? "--",
                        label: "Meters",
                        icon: "ruler"
                    )
                }
            } else {
                HStack {
                    ProgressView()
                        .tint(GGTheme.accent)
                    Text("Waiting for step data...")
                        .font(.system(size: 13))
                        .foregroundColor(GGTheme.text2)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(18)
        .background(GGTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: GGTheme.radius))
        .overlay(
            RoundedRectangle(cornerRadius: GGTheme.radius)
                .stroke(GGTheme.accent.opacity(0.15), lineWidth: 1)
        )
    }
}

struct LiveMetric: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(GGTheme.accent)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(GGTheme.text1)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(GGTheme.text2)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Today Summary Card

struct TodaySummaryCard: View {
    let today: [AssistEvent]
    let yesterday: [AssistEvent]
    let isMonitoring: Bool

    private var trend: String {
        if today.count == 0 && yesterday.count == 0 { return "No assists yet" }
        if yesterday.count == 0 { return "\(today.count) assist\(today.count == 1 ? "" : "s") today" }
        let diff = today.count - yesterday.count
        if diff < 0 { return "\(abs(diff)) fewer than yesterday" }
        if diff > 0 { return "\(diff) more than yesterday" }
        return "Same as yesterday"
    }

    private var trendColor: Color {
        if yesterday.count == 0 { return GGTheme.text2 }
        if today.count < yesterday.count { return GGTheme.accent }
        if today.count > yesterday.count { return GGTheme.warn }
        return GGTheme.text2
    }

    private var lastAssistText: String {
        guard let last = today.last else { return "None today" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: last.timestamp)
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Today's Support")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(GGTheme.text1)
                Spacer()
                if isMonitoring {
                    Text("LIVE")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(1)
                        .foregroundColor(GGTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(GGTheme.accent.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 0) {
                SummaryMetric(
                    value: "\(today.count)",
                    label: "Assists",
                    color: today.count == 0 ? GGTheme.accent : GGTheme.warn
                )

                RoundedRectangle(cornerRadius: 1)
                    .fill(GGTheme.text3.opacity(0.2))
                    .frame(width: 1, height: 40)

                SummaryMetric(
                    value: "\(today.filter { $0.type == "start" }.count)",
                    label: "Start",
                    color: GGTheme.accent
                )

                RoundedRectangle(cornerRadius: 1)
                    .fill(GGTheme.text3.opacity(0.2))
                    .frame(width: 1, height: 40)

                SummaryMetric(
                    value: "\(today.filter { $0.type == "turn" }.count)",
                    label: "Turn",
                    color: .orange
                )

                RoundedRectangle(cornerRadius: 1)
                    .fill(GGTheme.text3.opacity(0.2))
                    .frame(width: 1, height: 40)

                SummaryMetric(
                    value: lastAssistText,
                    label: "Last Assist",
                    color: GGTheme.text1
                )
            }

            HStack(spacing: 6) {
                Image(systemName: today.count <= yesterday.count
                      ? "arrow.down.right" : "arrow.up.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(trendColor)
                Text(trend)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(trendColor)
                Spacer()
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

struct SummaryMetric: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(GGTheme.text2)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Recent Assist Card

struct RecentFreezeCard: View {
    let events: [AssistEvent]
    @State private var expanded = false

    private var displayEvents: [AssistEvent] {
        let sorted = events.sorted { $0.timestamp > $1.timestamp }
        return expanded ? sorted : Array(sorted.prefix(3))
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Recent Assists")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(GGTheme.text1)
                Spacer()
                if events.count > 3 {
                    Button(action: { withAnimation(.spring(response: 0.35)) { expanded.toggle() } }) {
                        Text(expanded ? "Show Less" : "Show All (\(events.count))")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(GGTheme.accent)
                    }
                }
            }

            ForEach(displayEvents) { event in
                MiniEventRow(event: event)
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

struct MiniEventRow: View {
    let event: AssistEvent

    private var severityColor: Color {
        if event.severity < 0.33 { return GGTheme.accent }
        if event.severity < 0.66 { return .orange }
        return GGTheme.danger
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(event.type == "start" ? GGTheme.accent.opacity(0.15) : Color.orange.opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: event.type == "start" ? "figure.walk" : "arrow.turn.up.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(event.type == "start" ? GGTheme.accent : .orange)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("\(event.type.capitalized) Assist")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(GGTheme.text1)
                Text(event.timestamp, style: .time)
                    .font(.system(size: 11))
                    .foregroundColor(GGTheme.text2)
            }

            Spacer()

            Text(event.severityLabel)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(severityColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(severityColor.opacity(0.12))
                .clipShape(Capsule())
                .accessibilityLabel("Severity \(event.severityLabel)")
        }
    }
}

// MARK: - Setup Guide Card (when not connected)

struct SetupGuideCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(GGTheme.accent)
                Text("Getting Started")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(GGTheme.text1)
            }

            StepRow(number: 1, text: "Pair your Apple Watch with this iPhone")
            StepRow(number: 2, text: "Open GaitGuard on your Watch")
            StepRow(number: 3, text: "Tap Calibrate and walk for 30 seconds")
            StepRow(number: 4, text: "Start monitoring from Home or your Watch")
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

struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(GGTheme.accent)
                .frame(width: 24, height: 24)
                .background(GGTheme.accent.opacity(0.12))
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(GGTheme.text2)
        }
    }
}

// MARK: - History Tab

struct HistoryTab: View {
    @EnvironmentObject var cm: WatchConnectivityManager
    @State private var dailyNoteText: String = ""
    @State private var showClearConfirm = false
    @FocusState private var isNoteFocused: Bool

    private var todayKey: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GGTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        // Daily Note Section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundColor(GGTheme.accent)
                                Text("Today's Note")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(GGTheme.text1)
                                Spacer()
                            }

                            TextField("How are you feeling today?", text: $dailyNoteText, axis: .vertical)
                                .lineLimit(2...5)
                                .focused($isNoteFocused)
                                .padding(12)
                                .background(GGTheme.card)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(isNoteFocused ? GGTheme.accent : GGTheme.cardBorder, lineWidth: 1))
                                .foregroundColor(GGTheme.text1)
                                .onChange(of: dailyNoteText) { _, newText in
                                    cm.saveNote(for: Date(), text: newText)
                                }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                        if cm.assistEvents.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 48))
                                    .foregroundColor(GGTheme.text3)
                                Text("No Assists Yet")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(GGTheme.text1)
                                Text("When cueing assists are delivered they will appear here.")
                                    .font(.system(size: 14))
                                    .foregroundColor(GGTheme.text2)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .padding(.top, 40)
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(cm.assistEvents.reversed()) { event in
                                    HistoryRow(event: event)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .onAppear {
                    dailyNoteText = cm.dailyNotes[todayKey] ?? ""
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isNoteFocused = false }
                }

                if !cm.assistEvents.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") {
                            showClearConfirm = true
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(GGTheme.text2)
                    }
                }
            }
            .alert("Clear History?", isPresented: $showClearConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    withAnimation { cm.clearEvents() }
                }
            } message: {
                Text("This permanently removes all assist events from this iPhone.")
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

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(event.type == "start" ? GGTheme.accent.opacity(0.12) : Color.orange.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: event.type == "start" ? "figure.walk" : "arrow.turn.up.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(event.type == "start" ? GGTheme.accent : .orange)
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

            Text(event.severityLabel)
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
