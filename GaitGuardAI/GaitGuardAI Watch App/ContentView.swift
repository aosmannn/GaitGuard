import SwiftUI

struct ContentView: View {
    @StateObject private var engine = MotionDetector()
    @StateObject private var gaitTrackingManager: GaitTrackingManager
    @State private var isActive = false

    init() {
        let detector = MotionDetector()
        _engine = StateObject(wrappedValue: detector)
        _gaitTrackingManager = StateObject(wrappedValue: GaitTrackingManager(motionDetector: detector))
    }

    var body: some View {
        Group {
            if engine.isCalibrating {
                CalibrationView(engine: engine)
            } else {
                WatchPager(
                    engine: engine,
                    gaitTrackingManager: gaitTrackingManager,
                    isActive: $isActive
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetToFactorySettings"))) { _ in
            engine.resetToFactorySettings()
        }
    }
}

// MARK: - Horizontal Pager (Digital Crown scrolls left/right)

struct WatchPager: View {
    @ObservedObject var engine: MotionDetector
    @ObservedObject var gaitTrackingManager: GaitTrackingManager
    @Binding var isActive: Bool
    @State private var page = 0

    var body: some View {
        TabView(selection: $page) {
            ScorePage(engine: engine, gaitTrackingManager: gaitTrackingManager, isActive: $isActive)
                .tag(0)
            MetricsPage(engine: engine, isActive: isActive)
                .tag(1)
            StatsPage(engine: engine, isActive: $isActive)
                .tag(2)
        }
        .tabViewStyle(.page)
        .containerBackground(
            isActive ? Color(red: 0.05, green: 0.14, blue: 0.12).gradient
                     : Color(red: 0.04, green: 0.06, blue: 0.12).gradient,
            for: .navigation
        )
    }
}

// MARK: - Page 1: Gait Score + Start/Stop

struct ScorePage: View {
    @ObservedObject var engine: MotionDetector
    @ObservedObject var gaitTrackingManager: GaitTrackingManager
    @Binding var isActive: Bool
    @ObservedObject private var conn = WatchConnectivityManager.shared

    private let accent = Color(red: 0.18, green: 0.87, blue: 0.72)

    private var gaitScore: Int {
        guard isActive else { return 0 }
        var penalty = Double(engine.todaysTotal * 12)
        let offset = Double(engine.currentSteps) / 150.0
        penalty = max(0, penalty - offset)
        return max(0, min(100, Int(100.0 - penalty)))
    }

    private var scoreLabel: String {
        guard isActive else { return "Idle" }
        if gaitScore >= 85 { return "Excellent" }
        if gaitScore >= 65 { return "Good" }
        if gaitScore >= 40 { return "Fair" }
        return "Needs Attention"
    }

    private var scoreColor: Color {
        guard isActive else { return .gray }
        if gaitScore >= 85 { return accent }
        if gaitScore >= 65 { return .green }
        if gaitScore >= 40 { return .orange }
        return .red
    }

    private var progress: Double {
        guard isActive else { return 0 }
        return Double(gaitScore) / 100.0
    }

    var body: some View {
        VStack(spacing: 8) {
            Spacer().frame(height: 2)

            HStack {
                if conn.isWatchReachable {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(accent)
                }
                Spacer()
            }
            .padding(.horizontal, 4)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 6)
                    .frame(width: 110, height: 110)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [scoreColor.opacity(0.4), scoreColor],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360 * progress)
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progress)

                VStack(spacing: 0) {
                    Text("GAIT SCORE")
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(.gray)

                    if isActive {
                        Text("\(gaitScore)")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                    } else {
                        Text("--")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(Color.gray.opacity(0.4))
                    }
                }
            }

            Text(scoreLabel)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(scoreColor)

            Spacer().frame(height: 4)

            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isActive.toggle()
                }
                if isActive {
                    gaitTrackingManager.startTracking()
                    engine.startMonitoring()
                } else {
                    gaitTrackingManager.stopTracking()
                    engine.stopMonitoring()
                }
            }) {
                Text(isActive ? "STOP" : "START")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .tracking(1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(isActive ? .red.opacity(0.8) : accent)

            PageDots(current: 0, total: 3)
                .padding(.top, 2)
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Page 2: Cadence / Stride

struct MetricsPage: View {
    @ObservedObject var engine: MotionDetector
    let isActive: Bool

    private let accent = Color(red: 0.18, green: 0.87, blue: 0.72)

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            if isActive {
                VStack(spacing: 20) {
                    MetricBlock(
                        value: engine.currentCadence.map { String(format: "%.0f", $0) } ?? "--",
                        label: "CADENCE",
                        unit: "spm",
                        color: accent
                    )
                    MetricBlock(
                        value: engine.currentDistance.map { String(format: "%.2f", $0) } ?? "--",
                        label: "STRIDE",
                        unit: "m",
                        color: .cyan
                    )
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 28))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("Start monitoring to see metrics")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()
            PageDots(current: 1, total: 3)
        }
        .padding(.horizontal, 12)
    }
}

struct MetricBlock: View {
    let value: String
    let label: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(unit)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(color)
        }
    }
}

// MARK: - Page 3: Stats + Calibrate

struct StatsPage: View {
    @ObservedObject var engine: MotionDetector
    @Binding var isActive: Bool

    private let accent = Color(red: 0.18, green: 0.87, blue: 0.72)

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("\(engine.currentSteps)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("STEPS")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)

                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 30)

                VStack(spacing: 4) {
                    Text("\(engine.todaysTotal)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("ASSISTS")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            }

            VStack(spacing: 4) {
                Text("Last Assist")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.gray)
                Text(engine.lastAssistTimeText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }

            if engine.hasCalibrationData() {
                Label("Calibrated", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(accent)
            } else if engine.isCalibrationUnstable() {
                Label("Calibration Failed", systemImage: "xmark.circle.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.red)
            }

            if engine.monitoringStoppedDueToBattery {
                Label("Low Battery", systemImage: "battery.25")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.red)
            }

            if !isActive {
                Button(action: { engine.startCalibration() }) {
                    Label("Calibrate", systemImage: "tuningfork")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .tint(accent)
            }

            Spacer()
            PageDots(current: 2, total: 3)
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - Calibration View

struct CalibrationView: View {
    @ObservedObject var engine: MotionDetector

    // A visual multiplier based on movement
    private var pulseScale: CGFloat {
        // Normal walking is ~1.2 - 2.5 magnitude
        // Let's cap at 2.5 for animation
        let capped = min(max(engine.currentMagnitude, 1.0), 3.0)
        return CGFloat(1.0 + (capped - 1.0) * 0.3)
    }

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .scaleEffect(pulseScale)
                    .animation(.spring(response: 0.2, dampingFraction: 0.5), value: engine.currentMagnitude)

                Image(systemName: "figure.walk")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
            }

            Text("\(engine.calibrationTimeRemaining)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.orange)
                .contentTransition(.numericText())

            ProgressView(value: engine.calibrationProgress)
                .tint(.orange)
                .padding(.horizontal, 24)
                .padding(.vertical, 4)

            Text("Walk at normal pace")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)

            Spacer()

            Button(role: .destructive, action: { engine.stopCalibration() }) {
                Text("Cancel")
                    .font(.system(size: 12, weight: .semibold))
            }
            .frame(height: 36)
        }
        .containerBackground(Color.orange.opacity(0.15).gradient, for: .navigation)
    }
}

// MARK: - Page Dots

struct PageDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i == current ? Color.white : Color.gray.opacity(0.3))
                    .frame(width: i == current ? 6 : 4, height: i == current ? 6 : 4)
            }
        }
    }
}
