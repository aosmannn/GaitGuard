import SwiftUI

/// Calibration: a 30-second walk that teaches the Watch what steady walking looks like for you.
/// Full-screen (the floating tab bar slides away so nothing covers the buttons).
struct CalibrationView: View {
    @EnvironmentObject var cm: WatchConnectivityManager
    @Environment(\.dismiss) private var dismiss

    @State private var startedAt: Date?
    @State private var couldntReach = false
    @State private var appliedTempo = false

    private enum Phase { case idle, getReady, walking, done, failed }

    private var phase: Phase {
        if cm.isWatchCalibrating { return cm.calibrationPhase == "getReady" ? .getReady : .walking }
        if let startedAt {
            if let r = cm.lastCalibrationResults, r.timestamp >= startedAt.addingTimeInterval(-1) { return .done }
            if cm.calibrationError != nil { return .failed }
        }
        return .idle
    }

    private var title: String {
        switch phase {
        case .idle: return "Tune to your walk"
        case .getReady: return "Get ready"
        case .walking: return "Keep walking"
        case .done: return "Tuned to you"
        case .failed: return "Let's try again"
        }
    }

    private var tuneTempo: Int? {
        guard let c = cm.lastCalibrationResults?.cadence, c >= 50 else { return nil }
        return Int(min(130, max(60, (c / 5).rounded() * 5)))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                GGBackButton { dismiss() }
                Spacer()
                GGLabel("Calibration", color: GGTheme.accent)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 22)
            .padding(.top, 6)

            Text(title)
                .font(.system(size: 36, weight: .medium, design: .serif))
                .tracking(-1)
                .foregroundStyle(GGTheme.text1)
                .padding(.top, 14)
                .contentTransition(.opacity)

            TickDial(monitoring: phase == .walking || phase == .getReady,
                     score: dialScore,
                     tempo: cm.watchSettings.cueTempo,
                     color: phase == .done ? GGTheme.good : GGTheme.scoreColor(70, monitoring: true),
                     size: 270) {
                dialCenter
            }
            .padding(.top, 18)

            detail
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .frame(maxWidth: .infinity)

            Spacer(minLength: 12)

            actions
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
        }
        .background { GGBackdrop() }
        .navigationBarBackButtonHidden(true)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .hidesTabBar()
        .animation(.snappy, value: phase)
        .sensoryFeedback(.success, trigger: phase == .done)
        .sensoryFeedback(.warning, trigger: phase == .failed)
    }

    // MARK: Dial

    private var dialScore: Int? {
        switch phase {
        case .idle, .failed: return nil
        case .getReady: return 0
        case .walking: return Int((cm.calibrationProgress * 100).rounded())
        case .done: return 100
        }
    }

    @ViewBuilder
    private var dialCenter: some View {
        switch phase {
        case .idle:
            VStack(spacing: 4) {
                Text("30")
                    .font(.system(size: 84, weight: .regular, design: .serif))
                    .tracking(-3)
                GGLabel("Seconds", color: GGTheme.text2)
            }
        case .getReady:
            VStack(spacing: 6) {
                Text("Stand tall")
                    .font(.system(size: 26, weight: .regular, design: .serif))
                    .italic()
                GGLabel("Walking starts soon", color: GGTheme.text2)
            }
        case .walking:
            VStack(spacing: 4) {
                Text("\(cm.calibrationTimeRemaining)")
                    .font(.system(size: 88, weight: .regular, design: .serif))
                    .tracking(-3)
                    .contentTransition(.numericText(value: Double(cm.calibrationTimeRemaining)))
                GGLabel("\(cm.calibrationSteps) steps", color: GGTheme.text2)
            }
        case .done:
            VStack(spacing: 4) {
                Text(cm.lastCalibrationResults?.cadence.map { String(format: "%.0f", $0) } ?? "✓")
                    .font(.system(size: 76, weight: .regular, design: .serif))
                    .tracking(-2)
                GGLabel("Steps per minute", color: GGTheme.text2)
            }
        case .failed:
            VStack(spacing: 8) {
                Canvas { gc, size in
                    let c = CGPoint(x: size.width / 2, y: size.height / 2)
                    var p = Path()
                    p.move(to: CGPoint(x: c.x, y: c.y - 22)); p.addLine(to: CGPoint(x: c.x, y: c.y + 6))
                    gc.stroke(p, with: .color(GGTheme.accent), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    gc.fill(Path(ellipseIn: CGRect(x: c.x - 4, y: c.y + 18, width: 8, height: 8)), with: .color(GGTheme.accent))
                }
                .frame(width: 60, height: 60)
                GGLabel("Not this time", color: GGTheme.text2)
            }
        }
    }

    // MARK: Detail

    @ViewBuilder
    private var detail: some View {
        switch phase {
        case .idle:
            VStack(alignment: .leading, spacing: 14) {
                step(1, "Wear your Watch snugly", "Just above the wrist bone, like for a workout.")
                step(2, "Find a clear path", "Somewhere you can walk for 30 seconds without stopping.")
                step(3, "Walk at your normal pace", "Let your arms swing. Your Watch taps when it's done.")
            }
        case .getReady:
            Text("Your Watch will tap when it's time to start walking.")
                .detailText()
        case .walking:
            VStack(spacing: 14) {
                HStack(spacing: 16) {
                    stat("Steps", "\(cm.calibrationSteps)", "")
                    Rectangle().fill(GGTheme.separator).frame(width: 1, height: 38)
                    stat("Pace", cm.calibrationCadence.map { String(format: "%.0f", $0) } ?? "–", "spm")
                }
                Text("Keep a natural, steady pace.")
                    .detailText()
            }
        case .done:
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    stat("Steps", "\(cm.lastCalibrationResults?.steps ?? 0)", "")
                    Rectangle().fill(GGTheme.separator).frame(width: 1, height: 38)
                    stat("Quality", cm.lastCalibrationResults?.qualityLabel ?? "–", "")
                }
                Text("Detection now follows your own walking rhythm.")
                    .detailText()
            }
        case .failed:
            Text(cm.calibrationError ?? "Something went wrong. Try again.")
                .detailText()
        }
    }

    // MARK: Actions

    @ViewBuilder
    private var actions: some View {
        VStack(spacing: 10) {
            switch phase {
            case .idle, .failed:
                if couldntReach {
                    Text("Couldn't reach your Watch. Open GaitGuard on it and try again.")
                        .font(.footnote)
                        .foregroundStyle(GGTheme.danger)
                        .multilineTextAlignment(.center)
                } else if cm.isWatchMonitoring {
                    Text("Stop monitoring first, then calibrate.")
                        .font(.footnote)
                        .foregroundStyle(GGTheme.text2)
                } else if !cm.isWatchReachable {
                    Text("Open GaitGuard on your Apple Watch to begin.")
                        .font(.footnote)
                        .foregroundStyle(GGTheme.text2)
                }
                GGPrimaryButton(title: phase == .failed ? "Try again" : (cm.lastCalibrationResults == nil ? "Start on Apple Watch" : "Calibrate again"),
                                enabled: cm.isWatchReachable && !cm.isWatchMonitoring) { start() }
            case .getReady, .walking:
                GGSecondaryButton(title: "Cancel", tint: GGTheme.text2) {
                    cm.requestCancelCalibration()
                    startedAt = nil
                }
            case .done:
                if let tempo = tuneTempo, !appliedTempo, Int(cm.watchSettings.cueTempo) != tempo {
                    GGSecondaryButton(title: "Match cue tempo to \(tempo) bpm") { applyTempo(tempo) }
                } else if appliedTempo {
                    Text("Cue tempo set to your walking pace.")
                        .font(.footnote)
                        .foregroundStyle(GGTheme.good)
                }
                GGPrimaryButton(title: "Done") { dismiss() }
            }
        }
    }

    // MARK: Pieces

    private func step(_ n: Int, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(n)")
                .font(.system(size: 22, design: .serif))
                .italic()
                .foregroundStyle(GGTheme.accent)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .semibold)).foregroundStyle(GGTheme.text1)
                Text(detail).font(.system(size: 14, weight: .medium)).foregroundStyle(GGTheme.text2)
            }
            Spacer(minLength: 0)
        }
    }

    private func stat(_ label: String, _ value: String, _ unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            GGLabel(label)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, design: .serif))
                    .tracking(-0.5)
                    .foregroundStyle(GGTheme.text1)
                    .contentTransition(.numericText())
                if !unit.isEmpty {
                    Text(unit).font(.system(size: 12, weight: .medium)).foregroundStyle(GGTheme.text2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Actions

    private func start() {
        couldntReach = false
        appliedTempo = false
        startedAt = Date()
        cm.calibrationError = nil
        cm.requestStartCalibration { ok in
            if !ok { startedAt = nil; couldntReach = true }
        }
    }

    private func applyTempo(_ tempo: Int) {
        var s = cm.watchSettings
        s.cueTempo = Double(tempo)
        cm.updateSettings(s)
        appliedTempo = true
    }
}

private extension Text {
    func detailText() -> some View {
        font(.system(size: 15, weight: .medium))
            .foregroundStyle(GGTheme.text2)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}
