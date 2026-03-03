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
    @State private var showResetConfirm = false
    @State private var showResetDone = false
    @State private var showSaved = false
    @State private var showCalibration = false

    init() {
        let s = WatchConnectivityManager.shared.watchSettings
        _hapticIntensity = State(initialValue: s.hapticIntensity)
        _sensitivity = State(initialValue: s.sensitivity)
        _adaptiveThreshold = State(initialValue: s.adaptiveThreshold)
        _hapticPattern = State(initialValue: s.hapticPattern)
        _repeatHaptics = State(initialValue: s.repeatHaptics)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GGTheme.bg.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        ProfileHeader()
                        
                        // Calibration Setup
                        SettingSection(title: "CALIBRATION", icon: "tuningfork") {
                            Button(action: { showCalibration = true }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Guided Calibration")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(GGTheme.accent)
                                        Text("Personalize detection to your walk")
                                            .font(.system(size: 12))
                                            .foregroundColor(GGTheme.text2)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(GGTheme.text3)
                                }
                            }
                        }
                        .sheet(isPresented: $showCalibration) {
                            CalibrationGuideSheet()
                        }
                        
                        HapticCard(
                            intensity: $hapticIntensity,
                            pattern: $hapticPattern,
                            repeatHaptics: $repeatHaptics,
                            onUpdate: save
                        )
                        DetectionCard(
                            sensitivity: $sensitivity,
                            adaptive: $adaptiveThreshold,
                            onUpdate: save
                        )
                        ConnectionCard(
                            testSuccess: $showTestSuccess,
                            testError: $showTestError,
                            onTest: testHaptic
                        )
                        DataCard(
                            showConfirm: $showResetConfirm,
                            showDone: $showResetDone,
                            onReset: resetFactory
                        )
                        AboutCard()
                    }
                    .padding(20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Profile")
        }
    }

    private func save() {
        var ns = cm.watchSettings
        ns.hapticIntensity = hapticIntensity
        ns.sensitivity = sensitivity
        ns.adaptiveThreshold = adaptiveThreshold
        ns.hapticPattern = hapticPattern
        ns.repeatHaptics = repeatHaptics
        cm.updateSettings(ns)
        withAnimation { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSaved = false }
        }
    }

    private func testHaptic() {
        cm.updateConnectionStatus()
        cm.testHaptic()
        if cm.isWatchReachable {
            withAnimation { showTestSuccess = true; showTestError = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { withAnimation { showTestSuccess = false } }
        } else {
            withAnimation { showTestError = true; showTestSuccess = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { withAnimation { showTestError = false } }
        }
    }

    private func resetFactory() {
        var fs = WatchSettings()
        fs.sensitivity = 1.3
        fs.adaptiveThreshold = false
        cm.updateSettings(fs)
        cm.resetToFactorySettings()
        hapticIntensity = fs.hapticIntensity
        sensitivity = fs.sensitivity
        adaptiveThreshold = fs.adaptiveThreshold
        hapticPattern = fs.hapticPattern
        repeatHaptics = fs.repeatHaptics
        withAnimation { showResetDone = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { showResetDone = false } }
    }
}

// MARK: - Profile Header

struct ProfileHeader: View {
    @EnvironmentObject var cm: WatchConnectivityManager

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(GGTheme.accent.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "shield.checkered")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(GGTheme.accent)
            }
            Text("GaitGuard")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(GGTheme.text1)
            Text(cm.isWatchReachable ? "Watch connected" : "Watch not connected")
                .font(.system(size: 13))
                .foregroundColor(GGTheme.text2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

// MARK: - Setting Section Card

struct SettingSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(GGTheme.accent)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(GGTheme.text2)
            }
            content
        }
        .padding(20)
        .background(GGTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: GGTheme.radius))
        .overlay(RoundedRectangle(cornerRadius: GGTheme.radius).stroke(GGTheme.cardBorder, lineWidth: 1))
    }
}

// MARK: - Haptic Card

struct HapticCard: View {
    @Binding var intensity: Double
    @Binding var pattern: String
    @Binding var repeatHaptics: Bool
    let onUpdate: () -> Void

    var body: some View {
        SettingSection(title: "HAPTIC FEEDBACK", icon: "waveform") {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Intensity")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(GGTheme.text1)
                    Spacer()
                    Text("\(Int(intensity * 100))%")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(GGTheme.accent)
                }
                Slider(value: $intensity, in: 0...1, step: 0.1)
                    .tint(GGTheme.accent)
                    .onChange(of: intensity) { _, _ in onUpdate() }
            }

            Divider().background(GGTheme.text3.opacity(0.2))

            HStack {
                Text("Pattern")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(GGTheme.text1)
                Spacer()
                Picker("", selection: $pattern) {
                    Text("Direction Up").tag("directionUp")
                    Text("Notification").tag("notification")
                    Text("Start").tag("start")
                    Text("Stop").tag("stop")
                    Text("Click").tag("click")
                }
                .pickerStyle(.menu)
                .tint(GGTheme.accent)
                .onChange(of: pattern) { _, _ in onUpdate() }
            }

            Divider().background(GGTheme.text3.opacity(0.2))

            Toggle(isOn: $repeatHaptics) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Repeat during freeze")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(GGTheme.text1)
                    Text("Continue pulsing during prolonged freezing")
                        .font(.system(size: 12))
                        .foregroundColor(GGTheme.text2)
                }
            }
            .tint(GGTheme.accent)
            .onChange(of: repeatHaptics) { _, _ in onUpdate() }
        }
    }
}

// MARK: - Detection Card

struct DetectionCard: View {
    @Binding var sensitivity: Double
    @Binding var adaptive: Bool
    let onUpdate: () -> Void
    
    @State private var presetMode: String = "custom"
    
    private func applyPreset() {
        switch presetMode {
        case "everyday":
            sensitivity = 1.3
            adaptive = true
        case "exercise":
            sensitivity = 2.0
            adaptive = true
        case "high_alert":
            sensitivity = 0.8
            adaptive = false
        default:
            break
        }
        onUpdate()
    }
    
    private func updatePresetFromSettings() {
        if sensitivity == 1.3 && adaptive == true { presetMode = "everyday" }
        else if sensitivity == 2.0 && adaptive == true { presetMode = "exercise" }
        else if sensitivity == 0.8 && adaptive == false { presetMode = "high_alert" }
        else { presetMode = "custom" }
    }

    private var sensitivityLabel: String {
        if sensitivity < 1.0 { return "High" }
        if sensitivity < 2.0 { return "Medium" }
        return "Low"
    }
    private var sensitivityColor: Color {
        if sensitivity < 1.0 { return GGTheme.danger }
        if sensitivity < 2.0 { return .orange }
        return GGTheme.accent
    }

    var body: some View {
        SettingSection(title: "DETECTION", icon: "sensor.fill") {
            VStack(alignment: .leading, spacing: 16) {
                
                // Preset Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Detection Mode")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(GGTheme.text1)
                    Picker("Mode", selection: $presetMode) {
                        Text("Everyday Walk").tag("everyday")
                        Text("Exercise").tag("exercise")
                        Text("High Alert").tag("high_alert")
                        Text("Custom").tag("custom")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: presetMode) { _, _ in applyPreset() }
                }
                
                if presetMode == "custom" {
                    Divider().background(GGTheme.text3.opacity(0.2))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Sensitivity")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(GGTheme.text1)
                            Spacer()
                            Text(sensitivityLabel)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(sensitivityColor)
                        }
                        Slider(value: $sensitivity, in: 0.5...3.0, step: 0.1)
                            .tint(GGTheme.accent)
                            .onChange(of: sensitivity) { _, _ in 
                                presetMode = "custom"
                                onUpdate() 
                            }
                        Text("Lower = more sensitive")
                            .font(.system(size: 11))
                            .foregroundColor(GGTheme.text3)
                    }

                    Divider().background(GGTheme.text3.opacity(0.2))

                    Toggle(isOn: $adaptive) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Smart Detection")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(GGTheme.text1)
                            if adaptive {
                                Text("Automatically adjusts to your gait")
                                    .font(.system(size: 12))
                                    .foregroundColor(GGTheme.text2)
                            }
                        }
                    }
                    .tint(GGTheme.accent)
                    .onChange(of: adaptive) { _, _ in 
                        presetMode = "custom"
                        onUpdate() 
                    }
                }
            }
            .onAppear { updatePresetFromSettings() }
        }
    }
}

// MARK: - Connection Card

struct ConnectionCard: View {
    @Binding var testSuccess: Bool
    @Binding var testError: Bool
    let onTest: () -> Void

    var body: some View {
        SettingSection(title: "TEST CONNECTION", icon: "antenna.radiowaves.left.and.right") {
            Button(action: onTest) {
                HStack {
                    Text("Send Test Vibration")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(GGTheme.accent)
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(GGTheme.accent)
                }
            }

            if testSuccess {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(GGTheme.accent)
                    Text("Vibration sent!").font(.system(size: 13)).foregroundColor(GGTheme.accent)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            if testError {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(GGTheme.danger)
                        Text("Not connected").font(.system(size: 13, weight: .medium)).foregroundColor(GGTheme.danger)
                    }
                    Text("Open both apps on physical devices and wait for connection.")
                        .font(.system(size: 12)).foregroundColor(GGTheme.text2)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Data Card

struct DataCard: View {
    @Binding var showConfirm: Bool
    @Binding var showDone: Bool
    let onReset: () -> Void

    var body: some View {
        SettingSection(title: "DATA", icon: "arrow.counterclockwise") {
            Button(action: { showConfirm = true }) {
                HStack {
                    Text("Reset to Defaults")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(GGTheme.danger)
                    Spacer()
                }
            }

            if showDone {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(GGTheme.accent)
                    Text("Reset complete").font(.system(size: 13)).foregroundColor(GGTheme.accent)
                }
                .transition(.opacity)
            }
        }
        .alert("Reset to Defaults", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive, action: onReset)
        } message: {
            Text("This will reset all calibration data and settings.")
        }
    }
}

// MARK: - About Card

struct AboutCard: View {
    var body: some View {
        SettingSection(title: "ABOUT", icon: "info.circle") {
            Text("GaitGuard is a wellness and activity monitoring tool. It is not intended to diagnose, treat, cure, or prevent any disease or medical condition.")
                .font(.system(size: 13))
                .foregroundColor(GGTheme.text2)

            Divider().background(GGTheme.text3.opacity(0.2))

            HStack {
                Text("Version")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(GGTheme.text1)
                Spacer()
                Text("1.2.0")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(GGTheme.text2)
            }
        }
    }
}

// MARK: - Guided Calibration

struct CalibrationGuideSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var cm: WatchConnectivityManager
    @State private var step = 1
    
    var body: some View {
        NavigationStack {
            ZStack {
                GGTheme.bg.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "tuningfork")
                            .font(.system(size: 40))
                            .foregroundColor(GGTheme.accent)
                        Text("Calibrate GaitGuard")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(GGTheme.text1)
                        Text("Personalize detection to your normal walking pattern.")
                            .font(.system(size: 14))
                            .foregroundColor(GGTheme.text2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 30)
                    
                    // Steps
                    VStack(spacing: 0) {
                        CalibStepRow(
                            number: 1,
                            title: "Wear your Apple Watch",
                            desc: "Ensure your watch is snug on your wrist.",
                            isActive: step >= 1,
                            isDone: step > 1
                        )
                        CalibStepConnector(isActive: step >= 2)
                        CalibStepRow(
                            number: 2,
                            title: "Open Watch App",
                            desc: "Open GaitGuard on your Apple Watch and tap 'Calibrate'.",
                            isActive: step >= 2,
                            isDone: step > 2
                        )
                        CalibStepConnector(isActive: step >= 3)
                        CalibStepRow(
                            number: 3,
                            title: "Walk Normally",
                            desc: "Walk continuously at your normal, comfortable pace for 30 seconds.",
                            isActive: step >= 3,
                            isDone: step > 3
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Live Feedback Box
                    if cm.isWatchCalibrating {
                        VStack(spacing: 12) {
                            Text("Calibrating...")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(GGTheme.accent)
                            
                            ProgressView(value: cm.calibrationProgress)
                                .tint(GGTheme.accent)
                            
                            Text("\(cm.calibrationTimeRemaining)s remaining")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(GGTheme.text2)
                        }
                        .padding(20)
                        .background(GGTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: GGTheme.radius))
                        .overlay(RoundedRectangle(cornerRadius: GGTheme.radius).stroke(GGTheme.accent.opacity(0.3), lineWidth: 1))
                        .padding(.horizontal, 20)
                        .onAppear { step = 3 }
                    } else if step == 3 {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.green)
                            Text("Calibration Complete")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(GGTheme.text1)
                        }
                        .padding(20)
                        .background(GGTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: GGTheme.radius))
                        .padding(.horizontal, 20)
                    }
                    
                    Button(action: {
                        if step < 3 { step += 1 }
                        else { dismiss() }
                    }) {
                        Text(step < 3 ? "Next" : "Done")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(GGTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .disabled(step == 3 && cm.isWatchCalibrating)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(GGTheme.text2)
                }
            }
        }
    }
}

struct CalibStepRow: View {
    let number: Int
    let title: String
    let desc: String
    let isActive: Bool
    let isDone: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(isDone ? .green : (isActive ? GGTheme.accent : GGTheme.card))
                    .frame(width: 32, height: 32)
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(isActive ? .white : GGTheme.text3)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isActive ? GGTheme.text1 : GGTheme.text3)
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundColor(isActive ? GGTheme.text2 : GGTheme.text3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}

struct CalibStepConnector: View {
    let isActive: Bool
    var body: some View {
        HStack {
            Rectangle()
                .fill(isActive ? GGTheme.accent : GGTheme.card)
                .frame(width: 2, height: 30)
                .padding(.leading, 15)
            Spacer()
        }
    }
}
