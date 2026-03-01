import SwiftUI
import WatchConnectivity

struct RemoteControlsView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @State private var hapticIntensity: Double
    @State private var sensitivity: Double
    @State private var adaptiveThreshold: Bool
    @State private var hapticPattern: String
    @State private var repeatHaptics: Bool
    @State private var showTestSuccess = false
    @State private var showTestError = false
    @State private var showResetConfirmation = false
    @State private var showResetSuccess = false
    @State private var showSettingsSaved = false
    
    init() {
        let settings = WatchConnectivityManager.shared.watchSettings
        _hapticIntensity = State(initialValue: settings.hapticIntensity)
        _sensitivity = State(initialValue: settings.sensitivity)
        _adaptiveThreshold = State(initialValue: settings.adaptiveThreshold)
        _hapticPattern = State(initialValue: settings.hapticPattern)
        _repeatHaptics = State(initialValue: settings.repeatHaptics)
    }
    
    var body: some View {
        NavigationStack {
            List {
                HapticSection(
                    hapticIntensity: $hapticIntensity,
                    hapticPattern: $hapticPattern,
                    repeatHaptics: $repeatHaptics,
                    showSettingsSaved: showSettingsSaved,
                    updateSettings: updateSettings
                )
                
                DetectionSection(
                    sensitivity: $sensitivity,
                    adaptiveThreshold: $adaptiveThreshold,
                    updateSettings: updateSettings
                )
                
                TestSection(
                    showTestSuccess: $showTestSuccess,
                    showTestError: $showTestError,
                    connectivityManager: connectivityManager,
                    testHaptic: testHaptic
                )
                
                DataSection(
                    showResetConfirmation: $showResetConfirmation,
                    showResetSuccess: $showResetSuccess,
                    resetToFactory: resetToFactory
                )
                
                AboutSection()
            }
            .navigationTitle("Settings")
            .background(GGTheme.background)
            .scrollContentBackground(.hidden)
        }
    }
    
    private func updateSettings() {
        var newSettings = connectivityManager.watchSettings
        newSettings.hapticIntensity = hapticIntensity
        newSettings.sensitivity = sensitivity
        newSettings.adaptiveThreshold = adaptiveThreshold
        newSettings.hapticPattern = hapticPattern
        newSettings.repeatHaptics = repeatHaptics
        connectivityManager.updateSettings(newSettings)
        withAnimation { showSettingsSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { showSettingsSaved = false }
        }
    }
    
    private func testHaptic() {
        connectivityManager.updateConnectionStatus()
        connectivityManager.testHaptic()
        
        if connectivityManager.isWatchReachable {
            withAnimation {
                showTestSuccess = true
                showTestError = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation { showTestSuccess = false }
            }
        } else {
            withAnimation {
                showTestError = true
                showTestSuccess = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                withAnimation { showTestError = false }
            }
        }
    }
    
    private func resetToFactory() {
        var factorySettings = WatchSettings()
        factorySettings.sensitivity = 1.3
        factorySettings.adaptiveThreshold = false
        connectivityManager.updateSettings(factorySettings)
        connectivityManager.resetToFactorySettings()
        withAnimation { showResetSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { showResetSuccess = false }
        }
    }
}

struct HapticSection: View {
    @Binding var hapticIntensity: Double
    @Binding var hapticPattern: String
    @Binding var repeatHaptics: Bool
    let showSettingsSaved: Bool
    let updateSettings: () -> Void
    
    var body: some View {
        Section {
            if showSettingsSaved {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Settings saved")
                        .foregroundColor(.green)
                }
                .listRowBackground(GGTheme.cardBackground)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Intensity", systemImage: "waveform")
                    Spacer()
                    Text("\(Int(hapticIntensity * 100))%")
                        .foregroundColor(GGTheme.textSecondary)
                }
                Slider(value: $hapticIntensity, in: 0.0...1.0, step: 0.1)
                    .onChange(of: hapticIntensity) { _, _ in updateSettings() }
                    .tint(.blue)
            }
            .padding(.vertical, 4)
            .listRowBackground(GGTheme.cardBackground)
            
            Picker(selection: $hapticPattern) {
                Label("Direction Up", systemImage: "arrow.up").tag("directionUp")
                Label("Notification", systemImage: "bell").tag("notification")
                Label("Start", systemImage: "play").tag("start")
                Label("Stop", systemImage: "stop").tag("stop")
                Label("Click", systemImage: "hand.tap").tag("click")
            } label: {
                Label("Pattern", systemImage: "waveform.path")
            }
            .onChange(of: hapticPattern) { _, _ in updateSettings() }
            .listRowBackground(GGTheme.cardBackground)
            
            Toggle(isOn: $repeatHaptics) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Repeat during freeze", systemImage: "repeat")
                    Text("Continue pulsing during prolonged freezing")
                        .font(.caption)
                        .foregroundColor(GGTheme.textSecondary)
                        .padding(.leading, 32)
                }
            }
            .onChange(of: repeatHaptics) { _, _ in updateSettings() }
            .tint(.blue)
            .listRowBackground(GGTheme.cardBackground)
            
        } header: {
            Text("Haptic Feedback")
                .foregroundColor(GGTheme.textSecondary)
        }
    }
}

struct DetectionSection: View {
    @Binding var sensitivity: Double
    @Binding var adaptiveThreshold: Bool
    let updateSettings: () -> Void
    
    private var sensitivityText: String {
        if sensitivity < 1.0 { return "High" }
        if sensitivity < 2.0 { return "Medium" }
        return "Low"
    }
    
    private var sensitivityColor: Color {
        if sensitivity < 1.0 { return .red }
        if sensitivity < 2.0 { return .orange }
        return .green
    }
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Sensitivity", systemImage: "slider.horizontal.3")
                    Spacer()
                    Text(sensitivityText)
                        .fontWeight(.medium)
                        .foregroundColor(sensitivityColor)
                }
                Slider(value: $sensitivity, in: 0.5...3.0, step: 0.1)
                    .onChange(of: sensitivity) { _, _ in updateSettings() }
                    .tint(.blue)
                Text("Lower values = more sensitive detection")
                    .font(.caption)
                    .foregroundColor(GGTheme.textSecondary)
            }
            .padding(.vertical, 4)
            .listRowBackground(GGTheme.cardBackground)
            
            Toggle(isOn: $adaptiveThreshold) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Smart Detection", systemImage: "brain")
                    if adaptiveThreshold {
                        Text("Automatically adjusts to your gait")
                            .font(.caption)
                            .foregroundColor(GGTheme.textSecondary)
                            .padding(.leading, 32)
                    }
                }
            }
            .onChange(of: adaptiveThreshold) { _, _ in updateSettings() }
            .tint(.blue)
            .listRowBackground(GGTheme.cardBackground)
            
        } header: {
            Text("Detection")
                .foregroundColor(GGTheme.textSecondary)
        }
    }
}

struct TestSection: View {
    @Binding var showTestSuccess: Bool
    @Binding var showTestError: Bool
    let connectivityManager: WatchConnectivityManager
    let testHaptic: () -> Void
    
    var body: some View {
        Section {
            Button(action: testHaptic) {
                HStack {
                    Label("Send Test Vibration", systemImage: "iphone.radiowaves.left.and.right")
                        .foregroundColor(.blue)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(GGTheme.textSecondary)
                }
            }
            .listRowBackground(GGTheme.cardBackground)
            
            if showTestSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Vibration sent! Watch should have buzzed.")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .listRowBackground(GGTheme.cardBackground)
            }
            
            if showTestError {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Not connected")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    Text("Keep both apps open. On Watch: tap START. Wait 30–60 sec, then test again.")
                        .font(.caption)
                        .foregroundColor(GGTheme.textSecondary)
                }
                .padding(.vertical, 4)
                .listRowBackground(GGTheme.cardBackground)
            }
            
        } header: {
            Text("Test Connection")
                .foregroundColor(GGTheme.textSecondary)
        } footer: {
            Text("Test vibration confirms connection. Settings sync instantly when connected.")
                .foregroundColor(GGTheme.textSecondary)
        }
    }
}

struct DataSection: View {
    @Binding var showResetConfirmation: Bool
    @Binding var showResetSuccess: Bool
    let resetToFactory: () -> Void
    
    var body: some View {
        Section {
            Button(role: .destructive, action: { showResetConfirmation = true }) {
                HStack {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                    Spacer()
                }
            }
            .listRowBackground(GGTheme.cardBackground)
            
            if showResetSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Reset complete")
                        .foregroundColor(.green)
                }
                .listRowBackground(GGTheme.cardBackground)
            }
        } header: {
            Text("Data")
                .foregroundColor(GGTheme.textSecondary)
        }
        .alert("Reset to Defaults", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive, action: resetToFactory)
        } message: {
            Text("This will reset all calibration data and settings. This cannot be undone.")
        }
    }
}

struct AboutSection: View {
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("GaitGuard")
                    .font(.headline)
                    .foregroundColor(GGTheme.textPrimary)
                Text("GaitGuard is a wellness and activity monitoring tool. It is not intended to diagnose, treat, cure, or prevent any disease or medical condition. Always consult with healthcare professionals for medical advice.")
                    .font(.caption)
                    .foregroundColor(GGTheme.textSecondary)
            }
            .padding(.vertical, 8)
            .listRowBackground(GGTheme.cardBackground)
            
            HStack {
                Label("Version", systemImage: "info.circle")
                    .foregroundColor(GGTheme.textPrimary)
                Spacer()
                Text("1.0")
                    .foregroundColor(GGTheme.textSecondary)
            }
            .listRowBackground(GGTheme.cardBackground)
        } header: {
            Text("About")
                .foregroundColor(GGTheme.textSecondary)
        }
    }
}
