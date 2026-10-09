import SwiftUI

enum DetectionMode: String, CaseIterable, Identifiable {
    case everyday = "Everyday Walking"
    case exercise = "Exercise"
    case highAlert = "High Alert"
    case custom = "Custom"

    var id: String { rawValue }

    var preset: (sensitivity: Double, adaptive: Bool)? {
        switch self {
        case .everyday: return (1.3, true)
        case .exercise: return (2.0, true)
        case .highAlert: return (0.8, false)
        case .custom: return nil
        }
    }

    var detail: String {
        switch self {
        case .everyday: return "Balanced for day-to-day walking at home and out."
        case .exercise: return "Less sensitive, for brisk walks and therapy exercises."
        case .highAlert: return "Most sensitive. Cues sooner, but may cue when you don't need it."
        case .custom: return "Set sensitivity yourself."
        }
    }

    init(_ s: WatchSettings) {
        self = Self.allCases.first {
            guard let p = $0.preset else { return false }
            return abs(p.sensitivity - s.sensitivity) < 0.01 && p.adaptive == s.adaptiveThreshold
        } ?? .custom
    }
}

struct SettingsView: View {
    @EnvironmentObject var cm: WatchConnectivityManager
    @State private var settings = WatchConnectivityManager.shared.watchSettings
    @State private var mode = DetectionMode(WatchConnectivityManager.shared.watchSettings)
    @State private var saveTask: Task<Void, Never>?
    @State private var testState: TestState = .idle
    @State private var showReset = false

    enum TestState { case idle, sending, sent, failed }

    private let patterns: [(id: String, name: String)] = [
        ("directionUp", "Rising"),
        ("notification", "Alert"),
        ("start", "Start"),
        ("stop", "Stop"),
        ("click", "Soft click"),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScreenHeader(eyebrow: "Tune", title: "Your cue rhythm") { statusPill }

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        tempoBlock
                        rhythmBlock
                        detectionBlock
                        watchBlock
                        Text("GaitGuard is a cueing aid, not a medical device. It doesn't diagnose, treat or prevent any condition, detect falls, or contact emergency services. Use with supervision and talk with your care team.\nVersion \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–")")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(GGTheme.text3)
                            .padding(.horizontal, 22)
                            .padding(.top, 16)
                    }
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
            .background { GGBackdrop() }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .onChange(of: settings) { _, _ in scheduleSave() }
            .onChange(of: mode) { _, newMode in
                guard let p = newMode.preset else { return }
                settings.sensitivity = p.sensitivity
                settings.adaptiveThreshold = p.adaptive
            }
            .onReceive(cm.$watchSettings) { incoming in
                guard incoming != settings else { return }
                settings = incoming
                mode = DetectionMode(incoming)
            }
            .alert("Reset settings and calibration?", isPresented: $showReset) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive, action: reset)
            } message: {
                Text("Cue and detection settings return to defaults, and your Watch forgets its calibration. Cue history is kept.")
            }
        }
    }

    // MARK: Blocks

    @ViewBuilder
    private var statusPill: some View {
        if cm.isWatchMonitoring { StatusPill(text: "Watch live", color: GGTheme.good, pulsing: true) }
        else if cm.isWatchReachable { StatusPill(text: "Connected", color: GGTheme.good) }
        else if cm.isWatchConnected { StatusPill(text: "Watch app closed", color: GGTheme.cue) }
        else { StatusPill(text: "Not paired", color: GGTheme.danger) }
    }

    private var tempoBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            GGLabel("Tempo")
            HStack(alignment: .center) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(Int(settings.cueTempo))")
                        .font(.system(size: 84, weight: .regular, design: .serif))
                        .tracking(-3)
                        .foregroundStyle(GGTheme.text1)
                        .contentTransition(.numericText(value: settings.cueTempo))
                    Text("bpm")
                        .font(.system(size: 24, design: .serif))
                        .italic()
                        .foregroundStyle(GGTheme.text2)
                }
                Spacer()
                HStack(spacing: 10) {
                    RoundGlyphButton(kind: .minus) { settings.cueTempo = max(60, settings.cueTempo - 5) }
                    RoundGlyphButton(kind: .plus) { settings.cueTempo = min(130, settings.cueTempo + 5) }
                }
            }
            tempoTicks
            Text("Each cue taps this rhythm on your wrist. A tempo close to your natural walking cadence usually feels best.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(GGTheme.text2)
        }
        .padding(.horizontal, 22)
        .padding(.top, 26)
        .animation(.snappy, value: settings.cueTempo)
    }

    private var tempoTicks: some View {
        let center = Int(((settings.cueTempo - 60) / 70 * 35).rounded())
        return HStack(spacing: 0) {
            ForEach(0..<36, id: \.self) { i in
                Capsule()
                    .fill(abs(i - center) <= 2 ? GGTheme.accent : GGTheme.cardRaised)
                    .frame(width: 3, height: i % 4 == 0 ? 20 : 12)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 24)
        .accessibilityHidden(true)
    }

    private var rhythmBlock: some View {
        VStack(alignment: .leading, spacing: 20) {
            GGRule()

            HStack {
                Text("Beats per cue").rowTitle()
                Spacer()
                HStack(spacing: 6) {
                    ForEach(1...8, id: \.self) { n in
                        Button { settings.cueBeats = max(2, n) } label: {
                            Circle()
                                .fill(n <= settings.cueBeats ? GGTheme.accent : GGTheme.cardRaised)
                                .frame(width: 10, height: 10)
                                .padding(4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Beats per cue")
                .accessibilityValue("\(settings.cueBeats)")
                .accessibilityAdjustableAction { dir in
                    settings.cueBeats = min(8, max(2, settings.cueBeats + (dir == .increment ? 1 : -1)))
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Strength").rowTitle()
                    Spacer()
                    Text(settings.hapticIntensity <= 0.4 ? "Gentle" : settings.hapticIntensity < 0.8 ? "Medium" : "Strong")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(GGTheme.accent)
                }
                GGSlider(value: $settings.hapticIntensity, range: 0.2...1, step: 0.1)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Haptic").rowTitle()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(patterns, id: \.id) { p in
                            GGChip(title: p.name, on: settings.hapticPattern == p.id) { settings.hapticPattern = p.id }
                        }
                    }
                }
            }

            HStack {
                Text("Repeat while frozen").rowTitle()
                Spacer()
                GGToggle(isOn: $settings.repeatHaptics)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Beat while walking").rowTitle()
                    Spacer()
                    GGToggle(isOn: $settings.walkBeat)
                }
                Text("A soft tap at your tempo while you walk, so the rhythm is already there. Uses more battery.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(GGTheme.text3)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 26)
    }

    private var detectionBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            GGRule()
            GGLabel("Detection")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DetectionMode.allCases) { m in
                        GGChip(title: m.rawValue, on: mode == m) { withAnimation(.snappy) { mode = m } }
                    }
                }
            }
            Text(mode.detail)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(GGTheme.text2)
            if mode == .custom {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Sensitivity").rowTitle()
                        Spacer()
                        Text("More ← → Less").font(.caption).foregroundStyle(GGTheme.text3)
                    }
                    GGSlider(value: $settings.sensitivity, range: 0.5...3.0, step: 0.1)
                    HStack {
                        Text("Adapt to my walk").rowTitle()
                        Spacer()
                        GGToggle(isOn: $settings.adaptiveThreshold)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 26)
    }

    private var watchBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            GGRule().padding(.bottom, 14)
            GGLabel("Your Watch")
            HStack(spacing: 10) {
                Circle().fill(cm.isWatchReachable ? GGTheme.good : GGTheme.text3).frame(width: 8, height: 8)
                Text("Apple Watch · \(connectionText)").rowTitle()
            }
            .padding(.top, 14)

            Button(action: sendTestCue) {
                HStack(spacing: 8) {
                    switch testState {
                    case .sending: ProgressView().tint(GGTheme.accent)
                    case .sent: Text("Sent").font(.system(size: 15, weight: .bold, design: .rounded))
                    case .failed: Text("Couldn't reach Watch").font(.system(size: 15, weight: .bold, design: .rounded))
                    case .idle: Text("Send a test cue").font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                }
                .foregroundStyle(testState == .failed ? GGTheme.danger : GGTheme.accent)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .overlay(Capsule().strokeBorder(testState == .failed ? GGTheme.danger : GGTheme.accent, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .disabled(!cm.isWatchReachable || testState == .sending)
            .opacity(cm.isWatchReachable ? 1 : 0.45)
            .padding(.top, 14)

            Text(syncFooter)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(GGTheme.text3)
                .padding(.top, 8)

            NavigationLink { CalibrationView() } label: {
                linkRow("Calibration", cm.lastCalibrationResults.map { "Tuned · walked \($0.timestamp.formatted(.relative(presentation: .named)))" } ?? "Not calibrated yet")
            }
            .buttonStyle(.plain)

            ShareLink(item: CSVExport(events: cm.assistEvents), preview: SharePreview("GaitGuard history")) {
                linkRow("Export history", "Share every cue as a CSV file")
            }
            .buttonStyle(.plain)
            .disabled(cm.assistEvents.isEmpty)
            .opacity(cm.assistEvents.isEmpty ? 0.45 : 1)

            Button { showReset = true } label: {
                linkRow("Reset settings & calibration", "Cue history is kept", color: GGTheme.danger, arrow: false)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.top, 26)
    }

    private func linkRow(_ title: String, _ subtitle: String, color: Color = GGTheme.text1, arrow: Bool = true) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 16, weight: .semibold)).foregroundStyle(color)
                    Text(subtitle).font(.system(size: 12, weight: .medium)).foregroundStyle(GGTheme.text2)
                }
                Spacer()
                if arrow {
                    ArrowGlyph()
                        .stroke(GGTheme.text2, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                        .frame(width: 11, height: 11)
                }
            }
            .padding(.vertical, 14)
            GGRule()
        }
        .contentShape(Rectangle())
    }

    // MARK: Helpers

    private var connectionText: String {
        if cm.isWatchMonitoring { return "Monitoring" }
        if cm.isWatchReachable { return "Connected" }
        if cm.isWatchConnected { return "Open GaitGuard on your Watch" }
        return "Not paired"
    }

    private var syncFooter: String {
        if cm.settingsQueuedOffline || !cm.isWatchReachable {
            return "Changes are saved and will reach your Watch the next time it connects."
        }
        return "Changes apply on your Watch instantly."
    }

    private func scheduleSave() {
        saveTask?.cancel()
        let snapshot = settings
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, snapshot != cm.watchSettings else { return }
            cm.updateSettings(snapshot)
        }
    }

    private func sendTestCue() {
        testState = .sending
        cm.testHaptic { ok in
            testState = ok ? .sent : .failed
            UINotificationFeedbackGenerator().notificationOccurred(ok ? .success : .error)
            Task {
                try? await Task.sleep(for: .seconds(3))
                testState = .idle
            }
        }
    }

    private func reset() {
        let defaults = WatchSettings()
        settings = defaults
        mode = DetectionMode(defaults)
        cm.updateSettings(defaults)
        cm.resetToFactorySettings()
    }
}

private extension Text {
    func rowTitle() -> some View {
        font(.system(size: 16, weight: .semibold)).foregroundStyle(GGTheme.text1)
    }
}

