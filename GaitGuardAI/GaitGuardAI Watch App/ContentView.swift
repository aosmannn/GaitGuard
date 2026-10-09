import SwiftUI

struct ContentView: View {
    @StateObject private var engine: MotionDetector
    @StateObject private var gaitTrackingManager: GaitTrackingManager

    init() {
        let detector = MotionDetector()
        _engine = StateObject(wrappedValue: detector)
        _gaitTrackingManager = StateObject(wrappedValue: GaitTrackingManager(motionDetector: detector))
    }

    private func start(_ source: String) {
        guard !engine.isMonitoring else { return }
        #if DEBUG
        print("[GaitGuard] Watch → start monitoring (\(source))")
        #endif
        gaitTrackingManager.startTracking()
        engine.startMonitoring()
        // Monitoring can refuse to start (low battery, no sensor): don't leave a workout running.
        if !engine.isMonitoring { gaitTrackingManager.stopTracking() }
    }

    private func stop(reason: String) {
        guard engine.isMonitoring else { return }
        #if DEBUG
        print("[GaitGuard] Watch → stop monitoring (\(reason))")
        #endif
        gaitTrackingManager.stopTracking()
        engine.stopMonitoring(reason: reason)
    }

    var body: some View {
        Group {
            if engine.isCalibrating {
                CalibrationView(engine: engine)
            } else {
                WatchPager(engine: engine, onStart: { start("user") }, onStop: { stop(reason: "user") })
            }
        }
        .animation(.easeInOut(duration: 0.3), value: engine.isMonitoring)
        .onAppear { WatchConnectivityManager.shared.requestSync() }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetToFactorySettings"))) { _ in
            engine.resetToFactorySettings()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RemoteStartMonitoring"))) { _ in start("remote") }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RemoteStopMonitoring"))) { _ in stop(reason: "remote") }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("MonitoringSessionExpired"))) { _ in stop(reason: "session_expired") }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PlayTestCue"))) { _ in
            engine.triggerTestHaptic()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RemoteStartCalibration"))) { _ in
            if !engine.isMonitoring && !engine.isCalibrating { engine.startCalibration() }
        }
        .onChange(of: engine.monitoringStoppedDueToBattery) { _, stopped in
            if stopped { gaitTrackingManager.stopTracking() }
        }
    }
}

// MARK: - Pager

struct WatchPager: View {
    @ObservedObject var engine: MotionDetector
    let onStart: () -> Void
    let onStop: () -> Void
    @State private var page = 0
    @ObservedObject private var conn = WatchConnectivityManager.shared

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $page) {
                ScorePage(engine: engine, onStart: onStart, onStop: onStop).tag(0)
                PacePage(engine: engine).tag(1)
                TodayPage(engine: engine).tag(2)
            }
            .tabViewStyle(.verticalPage)
            .containerBackground(GGTheme.bg.gradient, for: .navigation)

            if conn.assistBannerVisible, let type = conn.assistBannerType {
                AssistBanner(type: type)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: conn.assistBannerVisible)
    }
}

struct AssistBanner: View {
    let type: String

    var body: some View {
        HStack(spacing: 6) {
            CueGlyph(turn: type == "turn", color: GGTheme.bg)
                .frame(width: 20, height: 20)
            Text(type == "turn" ? "Turn cue" : "Start cue")
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
        .foregroundColor(GGTheme.bg)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(GGTheme.assistColor(type))
        .clipShape(Capsule())
        .padding(.top, 2)
    }
}

// MARK: - Page 1: the tick dial

struct ScorePage: View {
    @ObservedObject var engine: MotionDetector
    let onStart: () -> Void
    let onStop: () -> Void
    @ObservedObject private var conn = WatchConnectivityManager.shared

    private var gaitScore: Int { engine.isMonitoring ? engine.gaitScore : 0 }

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Circle()
                    .fill(conn.isWatchReachable ? GGTheme.good : GGTheme.text3)
                    .frame(width: 5, height: 5)
                Text(conn.isWatchReachable ? "Synced" : "Offline")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(GGTheme.text2)
                Spacer()
            }
            .padding(.horizontal, 6)

            if engine.isMonitoring {
                dial
                if engine.pendingFeedback != nil {
                    FeedbackPrompt(onYes: { engine.recordFeedback(helpful: true) },
                                   onNo: { engine.recordFeedback(helpful: false) })
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                } else {
                    Button(action: onStop) {
                        Text(engine.batteryLow ? "Stop · battery low" : "Stop")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(GGTheme.danger)
                            .frame(maxWidth: .infinity)
                            .frame(height: 28)
                            .overlay(Capsule().strokeBorder(GGTheme.danger.opacity(0.65), lineWidth: 1.2))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 10)
                }
            } else {
                Button(action: onStart) { dial }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Start monitoring")
            }
        }
    }

    private var dial: some View {
        TickDial(monitoring: engine.isMonitoring,
                 score: engine.isMonitoring ? gaitScore : nil,
                 tempo: WatchConnectivityManager.shared.watchSettings.cueTempo,
                 color: GGTheme.scoreColor(gaitScore, monitoring: engine.isMonitoring),
                 size: engine.isMonitoring ? 138 : 158) {
            if engine.isMonitoring {
                VStack(spacing: 0) {
                    Text("\(gaitScore)")
                        .font(.system(size: 46, weight: .regular, design: .serif))
                        .tracking(-1.5)
                        .contentTransition(.numericText(value: Double(gaitScore)))
                    Text(GaitScoreCalculator.label(for: gaitScore, isMonitoring: true))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(GGTheme.scoreColor(gaitScore, monitoring: true))
                }
            } else {
                VStack(spacing: 6) {
                    RoundedTriangle()
                        .fill(GGTheme.accent)
                        .frame(width: 24, height: 28)
                        .offset(x: 2)
                    Text("START")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.8)
                        .foregroundColor(GGTheme.text1)
                }
            }
        }
    }
}

// MARK: - Page 2: pace

struct PacePage: View {
    @ObservedObject var engine: MotionDetector

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GGLabel("Pace", color: GGTheme.accent)

            if engine.isMonitoring {
                metric("Cadence", engine.currentCadence.map { String(format: "%.0f", $0) } ?? "--", "spm")
                Rectangle().fill(GGTheme.separator).frame(height: 1)
                metric("Distance", engine.currentDistance.map { String(format: "%.0f", $0) } ?? "--", "m")
            } else {
                Spacer()
                Text("Start walking to see your pace.")
                    .font(.system(size: 14, design: .serif))
                    .italic()
                    .foregroundColor(GGTheme.text2)
                Spacer()
            }

            #if targetEnvironment(simulator)
            if engine.isMonitoring {
                Button("Simulate freeze") { engine.simulateFreeze() }
                    .font(.system(size: 12, weight: .semibold))
                    .tint(GGTheme.cue)
            }
            #endif
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metric(_ label: String, _ value: String, _ unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            GGLabel(label)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 44, weight: .regular, design: .serif))
                    .tracking(-1.5)
                    .foregroundColor(GGTheme.text1)
                Text(unit)
                    .font(.system(size: 14, design: .serif))
                    .italic()
                    .foregroundColor(GGTheme.text2)
            }
        }
    }
}

// MARK: - Page 3: today

struct TodayPage: View {
    @ObservedObject var engine: MotionDetector

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GGLabel("Cues today", color: GGTheme.accent)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(engine.todaysTotal)")
                    .font(.system(size: 52, weight: .regular, design: .serif))
                    .tracking(-2)
                    .foregroundColor(GGTheme.text1)
                    .contentTransition(.numericText())
                Text(engine.todaysTotal == 1 ? "cue" : "cues")
                    .font(.system(size: 16, design: .serif))
                    .italic()
                    .foregroundColor(GGTheme.text2)
            }

            Rectangle().fill(GGTheme.separator).frame(height: 1)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    GGLabel("Steps")
                    Text("\(engine.currentSteps)")
                        .font(.system(size: 18, design: .serif))
                        .foregroundColor(GGTheme.text1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    GGLabel("Last cue")
                    Text(engine.lastAssistTimeText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(GGTheme.text1)
                }
            }

            if engine.monitoringStoppedDueToBattery {
                note("Low battery", GGTheme.danger)
            } else if engine.isCalibrationUnstable() {
                note("Calibration failed", GGTheme.danger)
            } else if engine.hasCalibrationData() {
                note("Calibrated", GGTheme.good)
            }

            if !engine.isMonitoring {
                Button(action: { engine.startCalibration() }) {
                    Text(engine.hasCalibrationData() ? "Calibrate again" : "Calibrate")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(GGTheme.accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .overlay(Capsule().strokeBorder(GGTheme.accent, lineWidth: 1.2))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func note(_ text: String, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text).font(.system(size: 11, weight: .medium)).foregroundColor(GGTheme.text2)
        }
    }
}

// MARK: - Cue feedback

/// "Did that help?" — two big, glanceable buttons. Teaches the detector what you need.
struct FeedbackPrompt: View {
    let onYes: () -> Void
    let onNo: () -> Void

    var body: some View {
        VStack(spacing: 3) {
            GGLabel("Did it help?", color: GGTheme.text2)
            HStack(spacing: 8) {
                button(good: true, action: onYes)
                button(good: false, action: onNo)
            }
            .padding(.horizontal, 10)
        }
    }

    private func button(good: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Canvas { gc, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                var p = Path()
                if good {
                    p.move(to: CGPoint(x: c.x - 7, y: c.y + 1)); p.addLine(to: CGPoint(x: c.x - 2, y: c.y + 6)); p.addLine(to: CGPoint(x: c.x + 8, y: c.y - 6))
                } else {
                    p.move(to: CGPoint(x: c.x - 6, y: c.y - 6)); p.addLine(to: CGPoint(x: c.x + 6, y: c.y + 6))
                    p.move(to: CGPoint(x: c.x + 6, y: c.y - 6)); p.addLine(to: CGPoint(x: c.x - 6, y: c.y + 6))
                }
                gc.stroke(p, with: .color(good ? GGTheme.good : GGTheme.text2),
                          style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background(GGTheme.cardRaised, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(good ? "That helped" : "I didn't need that")
    }
}

// MARK: - Calibration

struct CalibrationView: View {
    @ObservedObject var engine: MotionDetector

    var body: some View {
        VStack(spacing: 6) {
            TickDial(monitoring: engine.calibrationPhase == "walking",
                     score: Int((engine.calibrationProgress * 100).rounded()),
                     tempo: 100,
                     color: GGTheme.cue,
                     size: 148) {
                if engine.calibrationPhase == "getReady" {
                    VStack(spacing: 2) {
                        Text("Get ready")
                            .font(.system(size: 20, weight: .regular, design: .serif))
                            .italic()
                        GGLabel("Walking starts soon", color: GGTheme.text2)
                    }
                } else {
                    VStack(spacing: 0) {
                        Text("\(engine.calibrationTimeRemaining)")
                            .font(.system(size: 50, weight: .regular, design: .serif))
                            .tracking(-1.5)
                            .contentTransition(.numericText())
                        GGLabel("\(engine.calibrationSteps) steps", color: GGTheme.text2)
                    }
                }
            }
            Text(engine.calibrationPhase == "getReady" ? "Stand tall, arms relaxed" : "Walk at your normal pace")
                .font(.system(size: 12, design: .serif))
                .italic()
                .foregroundColor(GGTheme.text2)

            Button(action: { engine.stopCalibration() }) {
                Text("Cancel")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(GGTheme.text2)
            }
            .buttonStyle(.plain)
            .frame(height: 24)
        }
        .containerBackground(GGTheme.bg.gradient, for: .navigation)
    }
}
