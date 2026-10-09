import SwiftUI

/// Home: the tick dial, live numbers, today's cues, last cue and calibration, all on one screen.
struct SummaryView: View {
    @EnvironmentObject var cm: WatchConnectivityManager
    @Binding var tab: AppTab
    @State private var pending = false
    @State private var showUnreachable = false

    private var todayEvents: [AssistEvent] { cm.assistEvents.on(Date()) }
    private var yesterdayEvents: [AssistEvent] {
        cm.assistEvents.on(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HomeHero(pending: pending, onToggle: toggleMonitoring)

                    if showUnreachable {
                        Label("Can't reach your Watch. Open GaitGuard on your Apple Watch and try again.",
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(GGTheme.text1)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(GGTheme.cue.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 22)
                            .padding(.top, 16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    CuesToday(today: todayEvents, yesterday: yesterdayEvents)
                        .padding(.horizontal, 22)
                        .padding(.top, 22)

                    HStack(spacing: 12) {
                        Button { tab = .history } label: {
                            LastCueTile(event: cm.assistEvents.max { $0.timestamp < $1.timestamp })
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            CalibrationView()
                        } label: {
                            CalibrationTile(results: cm.lastCalibrationResults, calibrating: cm.isWatchCalibrating)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 14)
                }
                .padding(.bottom, 24)
                .animation(.snappy, value: cm.isWatchMonitoring)
                .animation(.snappy, value: showUnreachable)
            }
            .scrollIndicators(.hidden)
            .background { GGBackdrop() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .refreshable { cm.requestSync() }
            .onAppear {
                cm.updateConnectionStatus()
                cm.requestSync()
            }
            .onChange(of: cm.isWatchMonitoring) { _, _ in pending = false }
        }
    }

    private func toggleMonitoring() {
        let ok = cm.isWatchMonitoring ? cm.requestStopMonitoring() : cm.requestStartMonitoring()
        guard ok else {
            showUnreachable = true
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            Task {
                try? await Task.sleep(for: .seconds(4))
                showUnreachable = false
            }
            return
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        pending = true
        // The Watch confirms through the shared state; don't leave the spinner up if it never does.
        Task {
            try? await Task.sleep(for: .seconds(6))
            pending = false
        }
    }
}

// MARK: - Hero

private struct HomeHero: View {
    @EnvironmentObject var cm: WatchConnectivityManager
    @AppStorage("gg.name") private var name = ""
    let pending: Bool
    let onToggle: () -> Void

    private var score: Int {
        if let s = cm.latestGaitScore { return s }
        let today = cm.assistEvents.on(Date()).count
        return GaitScoreCalculator.score(todaysAssists: today, steps: cm.latestStepData?.stepCount ?? 0)
    }

    private var stopReason: String? {
        switch cm.monitoringStopReason {
        case "battery": return "Stopped because the Watch battery is low."
        case "session_expired": return "The Watch ended the session."
        case "remote": return "Stopped from iPhone."
        default: return nil
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hello"
        }
    }

    private var canStart: Bool { cm.isWatchMonitoring || cm.isWatchReachable }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let stale = cm.isWatchStale(now: context.date)
            let dialColor = cm.isWatchMonitoring ? GGTheme.scoreColor(score, monitoring: true) : GGTheme.text3

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text((name.trimmingCharacters(in: .whitespaces).isEmpty ? greeting : "\(greeting), \(name.trimmingCharacters(in: .whitespaces))").uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .tracking(1.9)
                            .foregroundStyle(GGTheme.accent)
                        Spacer()
                        status(stale: stale)
                    }
                    Text(title)
                        .font(.system(size: 40, weight: .medium, design: .serif))
                        .tracking(-1)
                        .foregroundStyle(GGTheme.text1)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)

                Button(action: onToggle) {
                    TickDial(monitoring: cm.isWatchMonitoring,
                             score: cm.isWatchMonitoring ? score : nil,
                             tempo: cm.watchSettings.cueTempo,
                             color: dialColor,
                             size: 290) {
                        dialCenter
                    }
                    .opacity(canStart || pending ? 1 : 0.55)
                }
                .buttonStyle(.plain)
                .disabled(pending || !canStart)
                .padding(.top, 8)
                .accessibilityLabel(cm.isWatchMonitoring ? "Gait score \(score). Tap to stop monitoring" : "Start monitoring")
                .accessibilityHint("Starts or stops gait monitoring on your Apple Watch")
                .sensoryFeedback(.impact(weight: .medium), trigger: cm.isWatchMonitoring)

                if cm.isWatchMonitoring {
                    HStack(spacing: 16) {
                        stat("Time", cm.sessionStartTime.map { formatDuration(context.date.timeIntervalSince($0)) } ?? "–", "")
                        rule
                        stat("Steps", "\(cm.latestStepData?.stepCount ?? 0)", "")
                        rule
                        stat("Cadence", cm.latestStepData?.cadence.map { String(format: "%.0f", $0) } ?? "–", "spm")
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    if stale {
                        Text("Your Watch is out of range. It keeps cueing on your wrist, and this screen catches up when it reconnects.")
                            .font(.footnote)
                            .foregroundStyle(GGTheme.text2)
                            .padding(.horizontal, 22)
                            .padding(.top, 12)
                    }

                    Button(action: onToggle) {
                        Text(pending ? "Waiting for Watch…" : "Stop monitoring")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(GGTheme.danger)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .overlay(Capsule().strokeBorder(GGTheme.danger.opacity(0.6), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(pending)
                    .padding(.horizontal, 22)
                    .padding(.top, 16)
                } else {
                    Text(stopReason ?? (cm.isWatchReachable
                                        ? "Tap the dial to begin. You can also start from your Watch."
                                        : "Open GaitGuard on your Apple Watch to connect."))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(GGTheme.text2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                }
            }
        }
    }

    private var title: String {
        guard cm.isWatchMonitoring else { return "Ready to walk?" }
        return score >= 65 ? "Walking steady" : "Stay with the beat"
    }

    @ViewBuilder
    private var dialCenter: some View {
        if pending {
            ProgressView().controlSize(.large).tint(GGTheme.text1)
        } else if cm.isWatchMonitoring {
            VStack(spacing: 2) {
                GGLabel("Steadiness", color: GGTheme.text2)
                Text("\(score)")
                    .font(.system(size: 96, weight: .regular, design: .serif))
                    .tracking(-4)
                    .contentTransition(.numericText(value: Double(score)))
                Text(GaitScoreCalculator.label(for: score, isMonitoring: true))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GGTheme.scoreColor(score, monitoring: true))
            }
        } else {
            VStack(spacing: 12) {
                RoundedTriangle()
                    .fill(canStart ? GGTheme.accent : GGTheme.text3)
                    .frame(width: 44, height: 50)
                    .offset(x: 3)
                Text("START")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2.4)
                    .foregroundStyle(GGTheme.text1)
            }
        }
    }

    private var rule: some View {
        Rectangle().fill(GGTheme.separator).frame(width: 1, height: 38)
    }

    private func stat(_ label: String, _ value: String, _ unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            GGLabel(label)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .regular, design: .serif))
                    .tracking(-0.5)
                    .foregroundStyle(GGTheme.text1)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                if !unit.isEmpty {
                    Text(unit).font(.system(size: 12, weight: .medium)).foregroundStyle(GGTheme.text2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func status(stale: Bool) -> some View {
        if cm.isWatchMonitoring && stale {
            StatusPill(text: "Out of range", color: GGTheme.cue)
        } else if cm.isWatchMonitoring {
            StatusPill(text: "Watch live", color: GGTheme.good, pulsing: true)
        } else if cm.isWatchReachable {
            StatusPill(text: "Watch connected", color: GGTheme.good)
        } else if cm.isWatchConnected {
            StatusPill(text: "Watch app closed", color: GGTheme.cue)
        } else {
            StatusPill(text: "Not paired", color: GGTheme.danger)
        }
    }
}

// MARK: - Cues today

private struct CuesToday: View {
    let today: [AssistEvent]
    let yesterday: [AssistEvent]

    private var hourly: [Int] {
        let cal = Calendar.current
        var counts = Array(repeating: 0, count: 24)
        for e in today { counts[cal.component(.hour, from: e.timestamp)] += 1 }
        return counts
    }

    private var comparison: (text: String, color: Color) {
        guard !yesterday.isEmpty else {
            return (today.isEmpty ? "None so far today"
                    : "\(today.filter { $0.type != "turn" }.count) start · \(today.filter { $0.type == "turn" }.count) turn",
                    GGTheme.text2)
        }
        let diff = today.count - yesterday.count
        if diff < 0 { return ("\(-diff) fewer than yesterday", GGTheme.good) }
        if diff > 0 { return ("\(diff) more than yesterday", GGTheme.cue) }
        return ("Same as yesterday", GGTheme.text2)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GGRule()
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    GGLabel("Cues today")
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(today.count)")
                            .font(.system(size: 52, weight: .regular, design: .serif))
                            .tracking(-1.5)
                            .foregroundStyle(GGTheme.text1)
                            .contentTransition(.numericText())
                        Text(today.count == 1 ? "cue" : "cues")
                            .font(.system(size: 22, weight: .regular, design: .serif))
                            .italic()
                            .foregroundStyle(GGTheme.text2)
                    }
                    Text(comparison.text)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(comparison.color)
                }
                Spacer(minLength: 12)
                HStack(alignment: .bottom, spacing: 3) {
                    let mx = max(1, hourly.max() ?? 1)
                    ForEach(0..<24, id: \.self) { h in
                        Capsule()
                            .fill(hourly[h] > 0 ? GGTheme.cue : GGTheme.separator)
                            .frame(width: 5, height: hourly[h] > 0 ? max(10, CGFloat(hourly[h]) / CGFloat(mx) * 40) : 4)
                    }
                }
                .frame(height: 44, alignment: .bottom)
                .padding(.bottom, 4)
                .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Tiles

private struct LastCueTile: View {
    let event: AssistEvent?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GGLabel("Last cue")
            if let event {
                HStack(spacing: 8) {
                    Circle().fill(GGTheme.assistColor(event.type)).frame(width: 8, height: 8)
                    Text(event.timestamp, style: .time)
                        .font(.system(size: 20, design: .serif))
                        .foregroundStyle(GGTheme.text1)
                }
                Text("\(event.type == "turn" ? "Turn" : "Start") cue · \(event.severityLabel)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(GGTheme.text2)
            } else {
                HStack(spacing: 8) {
                    Circle().fill(GGTheme.text3).frame(width: 8, height: 8)
                    Text("None yet").font(.system(size: 20, design: .serif)).foregroundStyle(GGTheme.text1)
                }
                Text("Cues show up here").font(.system(size: 12, weight: .medium)).foregroundStyle(GGTheme.text2)
            }
        }
        .tileStyle()
    }
}

private struct CalibrationTile: View {
    let results: CalibrationResults?
    let calibrating: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GGLabel("Calibration")
            HStack(spacing: 8) {
                Circle().fill(results != nil || calibrating ? GGTheme.good : GGTheme.accent).frame(width: 8, height: 8)
                Text(calibrating ? "Walking…" : results != nil ? "Tuned" : "Not yet")
                    .font(.system(size: 20, design: .serif))
                    .foregroundStyle(GGTheme.text1)
            }
            Text(calibrating ? "Keep your normal pace"
                 : results.map { "Walked \($0.timestamp.formatted(.relative(presentation: .named)))" } ?? "A 30-second walk")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(GGTheme.text2)
                .lineLimit(1)
        }
        .tileStyle()
    }
}

private extension View {
    func tileStyle() -> some View {
        padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .ggSurface(radius: 22)
            .accessibilityElement(children: .combine)
    }
}
