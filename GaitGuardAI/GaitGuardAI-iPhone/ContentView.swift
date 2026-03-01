import SwiftUI
import WatchConnectivity

// MARK: - App Theme

enum GGTheme {
    static let accent = Color.blue
    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red
    static let cardBackground = Color(.systemGray6)
    static let cardRadius: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
}

// MARK: - Root Tab View

struct ContentView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "heart.text.clipboard")
                }
                .tag(0)

            AnalyticsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.xyaxis.line")
                }
                .tag(1)

            RemoteControlsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
        .tint(GGTheme.accent)
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    @EnvironmentObject var cm: WatchConnectivityManager
    @State private var timer: Timer?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: GGTheme.sectionSpacing) {
                    connectionCard
                    if cm.isWatchMonitoring || cm.latestStepData != nil {
                        liveMetricsRow
                    }
                    eventsSection
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("GaitGuard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !cm.assistEvents.isEmpty {
                        Button("Clear") { cm.clearEvents() }
                            .font(.subheadline)
                    }
                }
            }
            .onAppear {
                cm.updateConnectionStatus()
                startPolling()
            }
            .onDisappear { stopPolling() }
        }
    }

    // MARK: - Connection Card

    private var connectionCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(connectionColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: connectionIcon)
                        .font(.title3)
                        .foregroundStyle(connectionColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(connectionTitle)
                            .font(.headline)
                        if cm.isWatchReachable {
                            Circle()
                                .fill(GGTheme.success)
                                .frame(width: 8, height: 8)
                        }
                    }
                    connectionSubtitle
                }
                Spacer()
                Button {
                    cm.updateConnectionStatus()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()

            if cm.isWatchReachable, let hb = cm.lastHeartbeatTime {
                Divider().padding(.horizontal)
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Last sync \(hb, style: .relative)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if cm.heartbeatLatency > 0 {
                        Text("\(String(format: "%.0f", cm.heartbeatLatency * 1000))ms")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
        }
        .background(GGTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: GGTheme.cardRadius))
        .padding(.top, 8)
    }

    // MARK: - Live Metrics

    private var liveMetricsRow: some View {
        HStack(spacing: 12) {
            if let steps = cm.latestStepData {
                MetricCard(
                    value: "\(steps.stepCount)",
                    label: "Steps",
                    icon: "figure.walk",
                    color: .purple
                )
                if let cadence = steps.cadence, cadence > 0 {
                    MetricCard(
                        value: String(format: "%.0f", cadence * 60),
                        label: "Steps/min",
                        icon: "metronome",
                        color: .orange
                    )
                }
                if let dist = steps.distance, dist > 0 {
                    MetricCard(
                        value: String(format: "%.0f", dist),
                        label: "Meters",
                        icon: "point.topleft.down.to.point.bottomright.curvepath",
                        color: .teal
                    )
                }
            }
            if cm.isWatchMonitoring && cm.latestStepData == nil {
                MetricCard(value: "--", label: "Steps", icon: "figure.walk", color: .purple)
                MetricCard(value: "--", label: "Steps/min", icon: "metronome", color: .orange)
            }
        }
    }

    // MARK: - Events Section

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Events")
                    .font(.title3.bold())
                Spacer()
                if !cm.assistEvents.isEmpty {
                    Text("\(cm.assistEvents.count) total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if cm.assistEvents.isEmpty {
                emptyEventsCard
            } else {
                ForEach(cm.assistEvents.suffix(10).reversed()) { event in
                    EventRow(event: event, isLatest: event.timestamp == cm.assistEvents.last?.timestamp)
                }
            }
        }
    }

    private var emptyEventsCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "waveform.path")
                .font(.system(size: 44))
                .foregroundStyle(.quaternary)
            Text("No events yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(cm.isWatchReachable
                 ? "Events appear in real-time when gait assists trigger on your watch"
                 : "Connect your Apple Watch to start monitoring")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(GGTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: GGTheme.cardRadius))
    }

    // MARK: - Helpers

    private var connectionIcon: String {
        if cm.isWatchReachable { return "applewatch.radiowaves.left.and.right" }
        if cm.isWatchConnected { return "applewatch" }
        return "applewatch.slash"
    }

    private var connectionColor: Color {
        if cm.isWatchReachable { return GGTheme.success }
        if cm.isWatchConnected { return GGTheme.warning }
        return GGTheme.danger
    }

    private var connectionTitle: String {
        if cm.isWatchReachable { return "Watch Connected" }
        if cm.isWatchConnected { return "Watch Paired" }
        if cm.activationState == .notActivated { return "Connecting..." }
        return "Watch Not Paired"
    }

    @ViewBuilder
    private var connectionSubtitle: some View {
        if cm.isWatchMonitoring {
            HStack(spacing: 4) {
                Image(systemName: "bolt.shield.fill")
                    .foregroundStyle(GGTheme.success)
                Text("Actively monitoring")
                    .foregroundStyle(GGTheme.success)
            }
            .font(.caption)
        } else if cm.isWatchCalibrating {
            HStack(spacing: 4) {
                Image(systemName: "waveform.path")
                    .foregroundStyle(GGTheme.warning)
                Text("Calibrating... \(cm.calibrationTimeRemaining)s")
                    .foregroundStyle(GGTheme.warning)
            }
            .font(.caption)
        } else if !cm.isWatchReachable && cm.isWatchConnected {
            Text("Open GaitGuard on your watch")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if cm.isWatchReachable {
            Text("Tap START on watch to begin")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Text("Pair in the Watch app on iPhone")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func startPolling() {
        let mgr = cm
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            mgr.updateConnectionStatus()
        }
    }

    private func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold().monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Event Row

struct EventRow: View {
    let event: AssistEvent
    let isLatest: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(eventColor.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: event.type == "start" ? "figure.stand" : "arrow.triangle.turn.up.right.diamond")
                    .font(.body)
                    .foregroundStyle(eventColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(event.type == "start" ? "Gait Initiation" : "Turn Assist")
                        .font(.subheadline.weight(.semibold))
                    if isLatest {
                        Text("LATEST")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(GGTheme.success)
                            .clipShape(Capsule())
                    }
                }
                HStack(spacing: 6) {
                    Text(event.timestamp, style: .time)
                    Text(event.timestamp, style: .date)
                    if let dur = event.duration {
                        Text(String(format: "%.1fs", dur))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            severityBadge
        }
        .padding(14)
        .background(GGTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var eventColor: Color {
        event.type == "start" ? .blue : .orange
    }

    private var severityBadge: some View {
        let sev = event.severity
        let color: Color = sev < 0.33 ? .green : sev < 0.66 ? .yellow : .red
        let label = sev < 0.33 ? "Low" : sev < 0.66 ? "Med" : "High"
        return Text(label)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - Make AssistEvent Identifiable

extension AssistEvent: Identifiable {
    var id: Date { timestamp }
}
