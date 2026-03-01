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
                MonitoringView(
                    engine: engine,
                    gaitTrackingManager: gaitTrackingManager,
                    isActive: $isActive
                )
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
}

struct CalibrationView: View {
    @ObservedObject var engine: MotionDetector
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.path")
                .font(.system(size: 30))
                .foregroundColor(.orange)
                .symbolEffect(.pulse)
            
            Text("\(engine.calibrationTimeRemaining)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.orange)
                .contentTransition(.numericText())
            
            ProgressView(value: engine.calibrationProgress)
                .tint(.orange)
                .padding(.horizontal, 20)
            
            Text("Walk normally for 30s")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(role: .destructive, action: {
                engine.stopCalibration()
            }) {
                Text("Cancel")
            }
        }
        .padding(.vertical, 8)
    }
}

struct MonitoringView: View {
    @ObservedObject var engine: MotionDetector
    @ObservedObject var gaitTrackingManager: GaitTrackingManager
    @Binding var isActive: Bool
    @ObservedObject private var connectivity = WatchConnectivityManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header with icon and connection status
                ZStack {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 36))
                        .foregroundColor(isActive ? .green : .gray)
                        .symbolEffect(.pulse, isActive: isActive)
                    
                    HStack {
                        Spacer()
                        if connectivity.isWatchReachable {
                            Image(systemName: "iphone.and.arrow.forward")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                        } else if connectivity.sessionActivated {
                            Image(systemName: "iphone.slash")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.top, 4)
                
                // Status Text
                Text(isActive ? "Monitoring" : "GaitGuard")
                    .font(.system(.body, design: .rounded).bold())
                
                // Live metrics or inactive state
                if isActive {
                    HStack(spacing: 12) {
                        VStack {
                            Text("\(engine.currentSteps)")
                                .font(.headline)
                            Text("Steps")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().frame(height: 20)
                        
                        VStack {
                            if let cadence = engine.currentCadence {
                                Text(String(format: "%.0f", cadence))
                                    .font(.headline)
                            } else {
                                Text("--")
                                    .font(.headline)
                            }
                            Text("Steps/min")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    if engine.isCalibrationUnstable() {
                        Label("Calibration Failed", systemImage: "xmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                    } else if engine.hasCalibrationData() {
                        Label("Calibrated", systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else {
                        Text("Not Calibrated")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if engine.monitoringStoppedDueToBattery {
                    Text("Low Battery")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                // Main Action Button
                Button(action: {
                    isActive.toggle()
                    if isActive {
                        gaitTrackingManager.startTracking()
                        engine.startMonitoring()
                    } else {
                        gaitTrackingManager.stopTracking()
                        engine.stopMonitoring()
                    }
                }) {
                    Text(isActive ? "STOP" : "START")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .tint(isActive ? .red : .blue)
                .buttonStyle(.borderedProminent)
                
                // Calibrate Action
                if !isActive {
                    Button(action: { engine.startCalibration() }) {
                        Label("Calibrate", systemImage: "tuningfork")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                }
                
                // Footer Stats
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last Assist")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(engine.lastAssistTimeText)
                            .font(.system(size: 12, weight: .medium))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Today")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text("\(engine.todaysTotal)")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 4)
            }
        }
    }
}
