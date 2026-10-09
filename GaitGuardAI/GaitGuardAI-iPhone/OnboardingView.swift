import SwiftUI

/// First-launch walkthrough. Interactive: feel the beat, choose a pace, watch your Watch connect,
/// run the calibration walk, then acknowledge what GaitGuard is and isn't.
struct OnboardingView: View {
    let onFinish: () -> Void

    @EnvironmentObject var cm: WatchConnectivityManager
    @AppStorage("gg.name") private var name = ""
    @FocusState private var nameFocused: Bool

    private enum Page: Int, CaseIterable { case welcome, about, watch, calibrate, ready }
    private enum Pace: Double, CaseIterable {
        case slow = 80, steady = 100, brisk = 115
        var title: String {
            switch self { case .slow: "Slow"; case .steady: "Steady"; case .brisk: "Brisk" }
        }
    }

    @State private var page: Page = .welcome
    @State private var forward = true
    @State private var pace: Pace = .steady
    @State private var beating = false
    @State private var beatCount = 0
    @State private var calibrationStarted: Date?
    @State private var couldntReach = false
    @State private var agreed = false

    var body: some View {
        ZStack {
            GGBackdrop()
            VStack(spacing: 0) {
                topBar
                ZStack {
                    content
                        .id(page)
                        .transition(.asymmetric(
                            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                bottomBar
            }
        }
        .onChange(of: cm.isWatchReachable) { _, reachable in
            if reachable { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        }
    }

    // MARK: Chrome

    private var topBar: some View {
        HStack(spacing: 12) {
            if page != .welcome {
                GGBackButton { go(to: Page(rawValue: page.rawValue - 1) ?? .welcome, forward: false) }
                    .transition(.opacity)
            } else {
                Color.clear.frame(width: 40, height: 40)
            }
            Spacer()
            HStack(spacing: 6) {
                ForEach(Page.allCases, id: \.rawValue) { p in
                    Capsule()
                        .fill(p.rawValue <= page.rawValue ? GGTheme.accent : GGTheme.cardRaised)
                        .frame(width: p == page ? 26 : 8, height: 6)
                }
            }
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .animation(.snappy, value: page)
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            switch page {
            case .welcome:
                GGPrimaryButton(title: "Get started") { next() }
            case .about:
                GGPrimaryButton(title: "Continue") { nameFocused = false; next() }
            case .watch:
                GGPrimaryButton(title: cm.isWatchReachable ? "Continue" : "Continue without Watch") { next() }
            case .calibrate:
                calibrateActions
            case .ready:
                GGPrimaryButton(title: "Start using GaitGuard", enabled: agreed) { onFinish() }
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 18)
        .padding(.top, 8)
        .id(page)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.25), value: page)
    }

    @ViewBuilder
    private var content: some View {
        switch page {
        case .welcome: welcome
        case .about: about
        case .watch: watch
        case .calibrate: calibrate
        case .ready: ready
        }
    }

    // MARK: Pages

    private var welcome: some View {
        VStack(spacing: 26) {
            Spacer(minLength: 0)
            Button { feel(tempo: Pace.steady.rawValue) } label: {
                TickDial(monitoring: beating, score: beating ? 70 : 28, tempo: Pace.steady.rawValue,
                         color: GGTheme.scoreColor(70, monitoring: true), size: 270) {
                    VStack(spacing: 6) {
                        Text("G")
                            .font(.system(size: 96, weight: .regular, design: .serif))
                            .foregroundStyle(GGTheme.accent)
                        GGLabel(beating ? "Feel that?" : "Tap to feel the beat", color: GGTheme.text2)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Feel the cue rhythm")
            VStack(spacing: 12) {
                Text("A steady beat\nfor every step")
                    .font(.system(size: 34, weight: .medium, design: .serif))
                    .tracking(-0.8)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(GGTheme.text1)
                Text("When your steps start to freeze, your Apple Watch taps a gentle rhythm on your wrist to help you keep moving.")
                    .font(.system(size: 16))
                    .foregroundStyle(GGTheme.text2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            Spacer(minLength: 0)
        }
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: 22) {
            heading("Make it yours", "Pick the rhythm that feels natural when you walk.")
            VStack(alignment: .leading, spacing: 8) {
                GGLabel("Name (optional)")
                TextField("", text: $name, prompt: Text("Who is this for?").foregroundStyle(GGTheme.text3))
                    .font(.system(size: 22, design: .serif))
                    .foregroundStyle(GGTheme.text1)
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .padding(.vertical, 10)
                    .overlay(alignment: .bottom) { GGRule() }
            }
            VStack(alignment: .leading, spacing: 12) {
                GGLabel("Walking pace")
                HStack(spacing: 8) {
                    ForEach(Pace.allCases, id: \.rawValue) { p in
                        GGChip(title: p.title, on: pace == p) {
                            pace = p
                            setTempo(p.rawValue)
                            feel(tempo: p.rawValue)
                        }
                    }
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(Int(pace.rawValue))")
                        .font(.system(size: 60, design: .serif))
                        .tracking(-2)
                        .foregroundStyle(GGTheme.text1)
                        .contentTransition(.numericText(value: pace.rawValue))
                    Text("beats per minute")
                        .font(.system(size: 18, design: .serif))
                        .italic()
                        .foregroundStyle(GGTheme.text2)
                }
                Button { feel(tempo: pace.rawValue) } label: {
                    HStack(spacing: 10) {
                        HStack(spacing: 5) {
                            ForEach(0..<4, id: \.self) { i in
                                Circle()
                                    .fill(beating && i < beatCount ? GGTheme.accent : GGTheme.cardRaised)
                                    .frame(width: 10, height: 10)
                            }
                        }
                        Text("Feel it on your phone")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(GGTheme.text1)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(GGTheme.card, in: Capsule())
                }
                .buttonStyle(.plain)
                Text("You can fine-tune this later, and calibration can match it to your real walking pace.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(GGTheme.text3)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
    }

    private var watch: some View {
        VStack(alignment: .leading, spacing: 22) {
            heading("Meet your Watch", "GaitGuard senses movement on your wrist and taps the rhythm there.")
            VStack(spacing: 0) {
                statusRow("iPhone", "Ready", GGTheme.good, true)
                GGRule()
                statusRow("Apple Watch", watchStatusText, watchStatusColor, cm.isWatchReachable)
            }
            .padding(.horizontal, 18)
            .ggSurface(radius: 22)

            VStack(alignment: .leading, spacing: 14) {
                numbered(1, "Open GaitGuard on your Apple Watch")
                numbered(2, "Keep your iPhone close for a moment")
                numbered(3, "This screen updates by itself")
            }
            Text("No Watch yet? You can continue and connect later.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(GGTheme.text3)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .onAppear { cm.updateConnectionStatus() }
    }

    private var calibrate: some View {
        let done = calibrationStarted.map { s in (cm.lastCalibrationResults?.timestamp ?? .distantPast) >= s.addingTimeInterval(-1) } ?? false
        let running = cm.isWatchCalibrating
        return VStack(spacing: 22) {
            Spacer(minLength: 0)
            TickDial(monitoring: running, score: done ? 100 : (running ? Int(cm.calibrationProgress * 100) : 0),
                     tempo: cm.watchSettings.cueTempo,
                     color: done ? GGTheme.good : GGTheme.scoreColor(70, monitoring: true), size: 230) {
                if done {
                    VStack(spacing: 4) {
                        Text(cm.lastCalibrationResults?.cadence.map { String(format: "%.0f", $0) } ?? "✓")
                            .font(.system(size: 64, design: .serif))
                            .tracking(-2)
                        GGLabel("Steps per minute", color: GGTheme.text2)
                    }
                } else if running {
                    VStack(spacing: 4) {
                        Text(cm.calibrationPhase == "getReady" ? "Ready" : "\(cm.calibrationTimeRemaining)")
                            .font(.system(size: 70, design: .serif))
                            .tracking(-2)
                            .contentTransition(.numericText())
                        GGLabel(cm.calibrationPhase == "getReady" ? "Stand tall" : "\(cm.calibrationSteps) steps", color: GGTheme.text2)
                    }
                } else {
                    VStack(spacing: 4) {
                        Text("30").font(.system(size: 70, design: .serif)).tracking(-2)
                        GGLabel("Seconds", color: GGTheme.text2)
                    }
                }
            }
            VStack(spacing: 10) {
                Text(done ? "Tuned to your walk" : "Learn your walk")
                    .font(.system(size: 30, weight: .medium, design: .serif))
                    .tracking(-0.6)
                    .foregroundStyle(GGTheme.text1)
                Text(done ? "Detection now follows your own rhythm. You can redo this any time."
                     : "One 30-second walk teaches your Watch what steady walking looks like for you, so cues arrive when you need them.")
                    .font(.system(size: 16))
                    .foregroundStyle(GGTheme.text2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                if let err = cm.calibrationError, !running, calibrationStarted != nil, !done {
                    Text(err).font(.footnote).foregroundStyle(GGTheme.accent).multilineTextAlignment(.center).padding(.horizontal, 30)
                }
                if couldntReach {
                    Text("Couldn't reach your Watch. Open GaitGuard on it and try again.")
                        .font(.footnote).foregroundStyle(GGTheme.danger).multilineTextAlignment(.center)
                }
            }
            Spacer(minLength: 0)
        }
        .animation(.snappy, value: done)
    }

    @ViewBuilder
    private var calibrateActions: some View {
        let done = calibrationStarted.map { s in (cm.lastCalibrationResults?.timestamp ?? .distantPast) >= s.addingTimeInterval(-1) } ?? false
        if done {
            GGPrimaryButton(title: "Continue") { next() }
        } else if cm.isWatchCalibrating {
            GGSecondaryButton(title: "Cancel", tint: GGTheme.text2) {
                cm.requestCancelCalibration(); calibrationStarted = nil
            }
        } else {
            GGPrimaryButton(title: "Calibrate now", enabled: cm.isWatchReachable) {
                couldntReach = false
                calibrationStarted = Date()
                cm.calibrationError = nil
                cm.requestStartCalibration { ok in
                    if !ok { calibrationStarted = nil; couldntReach = true }
                }
            }
            Button("I'll do this later") { next() }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(GGTheme.text2)
                .buttonStyle(.plain)
                .padding(.top, 2)
            if !cm.isWatchReachable {
                Text("Connect your Watch to calibrate.")
                    .font(.footnote).foregroundStyle(GGTheme.text3)
            }
        }
    }

    private var ready: some View {
        VStack(alignment: .leading, spacing: 22) {
            heading("One important thing", "Please read this before you start.")
            VStack(alignment: .leading, spacing: 16) {
                bullet("GaitGuard is a cueing aid. It helps you keep a rhythm; it doesn't treat or diagnose anything.")
                bullet("It doesn't detect falls or contact anyone. Keep Apple Watch Fall Detection and Emergency SOS turned on if you rely on them.")
                bullet("It can miss a freeze or cue when you didn't need one. Tap ✓ or ✕ on your Watch after a cue and it learns.")
                bullet("Talk with your care team about how to use it.")
            }
            Spacer(minLength: 0)
            HStack(alignment: .center, spacing: 14) {
                GGToggle(isOn: $agreed)
                Text("I understand GaitGuard is a cueing aid, not a medical device.")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(GGTheme.text1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .ggSurface(radius: 22)
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
    }

    // MARK: Pieces

    private func heading(_ title: String, _ sub: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 36, weight: .medium, design: .serif))
                .tracking(-1)
                .foregroundStyle(GGTheme.text1)
            Text(sub)
                .font(.system(size: 16))
                .foregroundStyle(GGTheme.text2)
        }
    }

    private func statusRow(_ title: String, _ status: String, _ color: Color, _ on: Bool) -> some View {
        HStack {
            Text(title).font(.system(size: 17, weight: .semibold)).foregroundStyle(GGTheme.text1)
            Spacer()
            HStack(spacing: 8) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(status).font(.system(size: 14, weight: .semibold)).foregroundStyle(color)
            }
        }
        .padding(.vertical, 18)
    }

    private func numbered(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text("\(n)").font(.system(size: 22, design: .serif)).italic().foregroundStyle(GGTheme.accent).frame(width: 22)
            Text(text).font(.system(size: 16, weight: .medium)).foregroundStyle(GGTheme.text1)
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle().fill(GGTheme.accent).frame(width: 6, height: 6).padding(.top, 8)
            Text(text).font(.system(size: 16)).foregroundStyle(GGTheme.text1).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var watchStatusText: String {
        if cm.isWatchReachable { return "Connected" }
        if cm.isWatchConnected { return "Open GaitGuard on your Watch" }
        return "Not found yet"
    }

    private var watchStatusColor: Color {
        cm.isWatchReachable ? GGTheme.good : (cm.isWatchConnected ? GGTheme.cue : GGTheme.text3)
    }

    // MARK: Actions

    private func go(to p: Page, forward f: Bool) {
        forward = f
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) { page = p }
    }

    private func next() {
        guard let n = Page(rawValue: page.rawValue + 1) else { return }
        go(to: n, forward: true)
    }

    private func setTempo(_ bpm: Double) {
        var s = cm.watchSettings
        s.cueTempo = bpm
        cm.updateSettings(s)
    }

    /// Play four taps on the phone and light the dial while they play.
    private func feel(tempo: Double) {
        guard !beating else { return }
        beating = true
        beatCount = 0
        Task {
            await HapticBeat.play(tempo: tempo, beats: 4) { i in beatCount = i + 1 }
            try? await Task.sleep(for: .milliseconds(400))
            beating = false
            beatCount = 0
        }
    }
}
