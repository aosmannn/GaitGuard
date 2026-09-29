import SwiftUI
import WatchConnectivity

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
    @State private var pendingCommand = false

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
        return GaitScoreCalculator.score(todaysAssists: todayEvents.count, steps: cm.latestStepData?.stepCount ?? 0)
    }

    private var scoreLabel: String {
        GaitScoreCalculator.label(for: gaitScore, isMonitoring: cm.isWatchMonitoring)
    }

    private func flashError() {
        withAnimation { remoteActionError = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { remoteActionError = false }
        }
    }

    private func toggleMonitoring() {
        let ok = cm.isWatchMonitoring ? cm.requestStopMonitoring() : cm.requestStartMonitoring()
        guard ok else { flashError(); return }
        pendingCommand = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        // Watch confirms through the shared snapshot; never leave the spinner up if it doesn't.
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { pendingCommand = false }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GGTheme.bg.ignoresSafeArea()
                RadialGradient(colors: [GGTheme.accent.opacity(cm.isWatchMonitoring ? 0.22 : 0.10), .clear],
                               center: .top, startRadius: 0, endRadius: 420)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.6), value: cm.isWatchMonitoring)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 18) {
                        HeroCard(
                            cm: cm,
                            now: now,
                            score: cm.isWatchMonitoring ? gaitScore : nil,
                            label: scoreLabel,
                            pending: pendingCommand,
                            onToggle: toggleMonitoring
                        )

                        if remoteActionError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(GGTheme.warn)
                                Text("Watch not reachable — open GaitGuard on your Watch.")
                                    .font(.system(size: 13)).foregroundColor(GGTheme.text2)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(GGTheme.warn.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                        }

                        if cm.isWatchMonitoring {
                            LiveSessionCard(cm: cm, now: now)
                        }

                        TodaySummaryCard(today: todayEvents, yesterday: yesterdayEvents, isMonitoring: cm.isWatchMonitoring)

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
            .onChange(of: cm.isWatchMonitoring) { _, _ in pendingCommand = false }
        }
    }

    private func startPolling() {
        cm.updateConnectionStatus()
        cm.requestSync()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            cm.updateConnectionStatus()
            now = Date()
        }
    }
}

// MARK: - Hero (score, connection, primary control)

struct HeroCard: View {
    @ObservedObject var cm: WatchConnectivityManager
    let now: Date
    let score: Int?
    let label: String
    let pending: Bool
    let onToggle: () -> Void

    private var stopReasonText: String? {
        switch cm.monitoringStopReason {
        case "battery": return "Stopped — low battery. Charge your Watch, then start again."
        case "session_expired": return "Session ended. Start again when you're ready."
        case "remote": return "Stopped from iPhone."
        default: return nil
        }
    }

    private var connection: (text: String, color: Color, icon: String) {
        if cm.isWatchReachable { return ("Watch connected", GGTheme.good, "applewatch.radiowaves.left.and.right") }
        if cm.isWatchConnected { return ("Open Watch app", GGTheme.warn, "applewatch") }
        return ("No Watch", GGTheme.danger, "applewatch.slash")
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Label(connection.text, systemImage: connection.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(connection.color)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(connection.color.opacity(0.12), in: Capsule())
                Spacer()
                if let hb = cm.lastHeartbeatTime, cm.isWatchMonitoring {
                    let ago = now.timeIntervalSince(hb)
                    HStack(spacing: 5) {
                        Circle().fill(ago < 12 ? GGTheme.good : GGTheme.warn).frame(width: 6, height: 6)
                        Text(ago < 12 ? "Live" : "\(Int(ago))s ago")
                            .font(.system(size: 11, weight: .medium)).foregroundColor(GGTheme.text2)
                    }
                }
            }

            GGScoreRing(
                score: score,
                label: cm.isWatchMonitoring ? label : "Cueing paused",
                color: GGTheme.scoreColor(score ?? 0, monitoring: cm.isWatchMonitoring),
                size: 200,
                lineWidth: 14
            )

            if let stopReasonText, !cm.isWatchMonitoring {
                Text(stopReasonText)
                    .font(.system(size: 12, weight: .medium)).foregroundColor(GGTheme.warn)
                    .multilineTextAlignment(.center)
            }

            Button(action: onToggle) {
                HStack(spacing: 8) {
                    if pending { ProgressView().tint(.white) }
                    else { Image(systemName: cm.isWatchMonitoring ? "stop.fill" : "play.fill") }
                    Text(pending ? "Waiting for Watch…" : cm.isWatchMonitoring ? "Stop Monitoring" : "Start Monitoring")
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(cm.isWatchMonitoring ? AnyShapeStyle(GGTheme.danger.opacity(0.85))
                                                   : AnyShapeStyle(GGTheme.brandGradient))
                )
                .opacity(cm.isWatchReachable || cm.isWatchMonitoring ? 1 : 0.45)
            }
            .disabled(pending)
            .accessibilityHint("Starts or stops gait monitoring on your Apple Watch")

            if !cm.isWatchReachable && !cm.isWatchMonitoring {
                Text("Connect your Watch to begin cueing support")
                    .font(.system(size: 12)).foregroundColor(GGTheme.text3)
            }
        }
        .padding(20)
        .background(GGTheme.card, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(LinearGradient(colors: [GGTheme.accent.opacity(0.4), .white.opacity(0.04)],
                                       startPoint: .top, endPoint: .bottom), lineWidth: 1)
        )
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
                    color: GGTheme.accentSecondary
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
                .fill(GGTheme.assistColor(event.type).opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: event.type == "start" ? "figure.walk" : "arrow.turn.up.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(GGTheme.assistColor(event.type))
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
        .frame(maxWidth: .infinity, alignment: .leading)
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
                    .fill(GGTheme.assistColor(event.type).opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: event.type == "start" ? "figure.walk" : "arrow.turn.up.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(GGTheme.assistColor(event.type))
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
