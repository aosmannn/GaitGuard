import SwiftUI

struct ContentView: View {
    @StateObject private var engine: MotionDetector
    @StateObject private var gaitTrackingManager: GaitTrackingManager
    @EnvironmentObject var sessionManager: SessionManager
    @State private var isActive = false

    init() {
        let detector = MotionDetector()
        _engine = StateObject(wrappedValue: detector)
        _gaitTrackingManager = StateObject(wrappedValue: GaitTrackingManager(motionDetector: detector))
    }

    var body: some View {
        Group {
            if engine.isCalibrating {
                calibrationView
            } else {
                monitoringView
            }
        }
        .containerBackground(
            engine.isCalibrating ? Color.orange.gradient :
            (isActive ? Color.green.gradient : Color.blue.gradient),
            for: .navigation
        )
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetToFactorySettings"))) { _ in
            engine.resetToFactorySettings()
        }
    }

    // MARK: - Calibration View

    private var calibrationView: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: "waveform.path")
                    .font(.system(size: 28))
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse)

                Text("Calibrating")
                    .font(.system(.caption, design: .rounded).bold())

                Text("\(engine.calibrationTimeRemaining)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
                    .contentTransition(.numericText())

                ProgressView(value: engine.calibrationProgress)
                    .tint(.orange)
                    .padding(.horizontal, 20)

                Text("Walk normally")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Button("Cancel") { engine.stopCalibration() }
                    .tint(.red)
                    .buttonStyle(.bordered)
                    .font(.caption)
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Monitoring View

    private var monitoringView: some View {
        ScrollView {
            VStack(spacing: 10) {
                Image(systemName: isActive ? "bolt.shield.fill" : "shield")
                    .font(.system(size: 36))
                    .foregroundStyle(isActive ? .green : .gray)
                    .symbolEffect(.pulse, isActive: isActive)

                Text(isActive ? "Monitoring" : "GaitGuard")
                    .font(.system(.caption, design: .rounded).bold())

                if isActive {
                    liveStats
                } else {
                    statusBadges
                }

                Button {
                    isActive.toggle()
                    if isActive {
                        sessionManager.startSession()
                        gaitTrackingManager.startTracking()
                        engine.startMonitoring()
                    } else {
                        gaitTrackingManager.stopTracking()
                        engine.stopMonitoring()
                    }
                } label: {
                    Text(isActive ? "STOP" : "START")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .tint(isActive ? .red : .blue)
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                if !isActive {
                    Button {
                        engine.startCalibration()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "tuningfork")
                                .font(.caption2)
                            Text("Calibrate")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .tint(.orange)
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Live Stats

    private var liveStats: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text("\(engine.currentSteps)")
                    .font(.system(.title3, design: .rounded).bold().monospacedDigit())
                Text("Steps")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if let cadence = engine.currentCadence, cadence > 0 {
                VStack(spacing: 2) {
                    Text(String(format: "%.0f", cadence * 60))
                        .font(.system(.title3, design: .rounded).bold().monospacedDigit())
                    Text("Steps/min")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Status Badges

    private var statusBadges: some View {
        VStack(spacing: 6) {
            if engine.monitoringStoppedDueToBattery {
                Label("Low Battery", systemImage: "battery.25")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            if engine.hasCalibrationData() {
                Label("Calibrated", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else if engine.isCalibrationUnstable() {
                Label("Calibration Failed", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                Text("Tap START to begin")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
