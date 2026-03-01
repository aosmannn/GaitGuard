import SwiftUI
import WatchConnectivity

struct RemoteControlsView: View {
    @EnvironmentObject var cm: WatchConnectivityManager
    @State private var hapticIntensity: Double
    @State private var sensitivity: Double
    @State private var adaptiveThreshold: Bool
    @State private var hapticPattern: String
    @State private var repeatHaptics: Bool
    @State private var showTestSuccess = false
    @State private var showTestError = false
    @State private var showResetConfirmation = false
    @State private var showResetSuccess = false

    init() {
        let settings = WatchConnectivityManager.shared.watchSettings
        _hapticIntensity = State(initialValue: settings.hapticIntensity)
        _sensitivity = State(initialValue: settings.sensitivity)
        _adaptiveThreshold = State(initialValue: settings.adaptiveThreshold)
        _hapticPattern = State(initialValue: settings.hapticPattern)
        _repeatHaptics = State(initialValue: settings.repeatHaptics)
    }

    var body: some View {
        NavigationView {
            Form {
                hapticSection
                detectionSection
                testSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Haptic Feedback

    private var hapticSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Intensity", systemImage: "speaker.wave.2")
                    Spacer()
                    Text("\(Int(hapticIntensity * 100))%")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $hapticIntensity, in: 0.0...1.0, step: 0.1)
                    .tint(.blue)
                    .onChange(of: hapticIntensity) { _, _ in syncSettings() }
            }

            Picker(selection: $hapticPattern) {
                Label("Direction Up", systemImage: "arrow.up").tag("directionUp")
                Label("Notification", systemImage: "bell").tag("notification")
                Label("Start", systemImage: "play").tag("start")
                Label("Stop", systemImage: "stop").tag("stop")
                Label("Click", systemImage: "hand.tap").tag("click")
            } label: {
                Label("Pattern", systemImage: "waveform")
            }
            .onChange(of: hapticPattern) { _, _ in syncSettings() }

            Toggle(isOn: $repeatHaptics) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Repeat Haptics", systemImage: "repeat")
                    Text("Continue pulsing during prolonged freezing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: repeatHaptics) { _, _ in syncSettings() }
        } header: {
            Label("Haptic Feedback", systemImage: "hand.raised")
        } footer: {
            Text("Controls the vibration your watch delivers when a gait event is detected.")
        }
    }

    // MARK: - Detection

    private var detectionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Sensitivity", systemImage: "dial.low")
                    Spacer()
                    Text(sensitivityLabel)
                        .font(.subheadline)
                        .foregroundStyle(sensitivityColor)
                }
                Slider(value: $sensitivity, in: 0.5...3.0, step: 0.1)
                    .tint(sensitivityColor)
                    .onChange(of: sensitivity) { _, _ in syncSettings() }
                Text("Lower values detect subtler freezing episodes. Higher values reduce false triggers.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Toggle(isOn: $adaptiveThreshold) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Smart Detection", systemImage: "brain")
                    Text(adaptiveThreshold
                         ? "Using your calibrated gait baseline"
                         : "Using fixed threshold")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: adaptiveThreshold) { _, _ in syncSettings() }
        } header: {
            Label("Detection", systemImage: "sensor")
        } footer: {
            Text("Calibrate on the watch first for best results. Smart Detection uses your personal walking pattern.")
        }
    }

    // MARK: - Test

    private var testSection: some View {
        Section {
            Button {
                triggerTest()
            } label: {
                HStack {
                    Label("Send Test Vibration", systemImage: "bolt.fill")
                    Spacer()
                    if showTestSuccess {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .transition(.scale.combined(with: .opacity))
                    }
                    if showTestError {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .disabled(!cm.isWatchReachable)

            if !cm.isWatchReachable {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text(cm.isWatchConnected
                         ? "Open GaitGuard on your watch to test"
                         : "Pair your watch to send test haptics")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label("Test", systemImage: "wand.and.stars")
        }
    }

    // MARK: - Data Management

    private var dataSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
            }
            .alert("Reset to Defaults", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { resetAll() }
            } message: {
                Text("This resets all calibration data and settings on your watch. You will need to recalibrate.")
            }

            if showResetSuccess {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("Settings reset successfully").font(.caption).foregroundStyle(.green)
                }
                .transition(.opacity)
            }
        } header: {
            Label("Data", systemImage: "externaldrive")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("GaitGuard")
                    .font(.subheadline.weight(.semibold))
                Text("GaitGuard is a wellness and gait monitoring tool. ")
                + Text("It is not a medical device. Always consult ")
                + Text("healthcare professionals for medical advice.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0").foregroundStyle(.secondary)
            }
            .font(.subheadline)
        } header: {
            Label("About", systemImage: "info.circle")
        }
    }

    // MARK: - Helpers

    private var sensitivityLabel: String {
        if sensitivity < 1.0 { return "High" }
        if sensitivity < 2.0 { return "Medium" }
        return "Low"
    }

    private var sensitivityColor: Color {
        if sensitivity < 1.0 { return .red }
        if sensitivity < 2.0 { return .orange }
        return .green
    }

    private func syncSettings() {
        var updated = cm.watchSettings
        updated.hapticIntensity = hapticIntensity
        updated.sensitivity = sensitivity
        updated.adaptiveThreshold = adaptiveThreshold
        updated.hapticPattern = hapticPattern
        updated.repeatHaptics = repeatHaptics
        cm.updateSettings(updated)
    }

    private func triggerTest() {
        cm.updateConnectionStatus()
        if cm.isWatchReachable {
            cm.testHaptic()
            withAnimation { showTestSuccess = true; showTestError = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showTestSuccess = false }
            }
        } else {
            withAnimation { showTestError = true; showTestSuccess = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showTestError = false }
            }
        }
    }

    private func resetAll() {
        var factory = WatchSettings()
        factory.sensitivity = 1.3
        factory.adaptiveThreshold = false
        cm.updateSettings(factory)
        cm.resetToFactorySettings()
        hapticIntensity = factory.hapticIntensity
        sensitivity = factory.sensitivity
        adaptiveThreshold = factory.adaptiveThreshold
        hapticPattern = factory.hapticPattern
        repeatHaptics = factory.repeatHaptics
        withAnimation { showResetSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { showResetSuccess = false }
        }
    }
}
