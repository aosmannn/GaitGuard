// WatchConnectivityManager.swift
// Shared between watch + iPhone to sync assist events.
import Foundation
import WatchConnectivity
import Combine
#if os(watchOS)
import WatchKit
#endif

struct AssistEvent: Codable {
    let timestamp: Date
    let type: String // "start" or "turn"
    let severity: Double // 0.0 to 1.0, magnitude normalized
    let duration: TimeInterval? // Optional: how long the freeze lasted
}

// Live accelerometer data point
struct AccelerometerData: Codable {
    let x: Double
    let y: Double
    let z: Double
    let timestamp: Date
}

// Calibration results
struct CalibrationResults: Codable {
    let average: Double
    let standardDeviation: Double
    let baselineThreshold: Double
    let sampleCount: Int
    let timestamp: Date
}

// Step data from CMPedometer
struct StepData: Codable {
    let stepCount: Int
    let cadence: Double?
    let distance: Double?
    let timestamp: Date
}

// Settings that can be controlled from iPhone
struct WatchSettings: Codable {
    var hapticIntensity: Double = 1.0 // 0.0 to 1.0
    var sensitivity: Double = 1.3 // Motion threshold
    var adaptiveThreshold: Bool = true
    var hapticPattern: String = "directionUp" // "directionUp", "notification", "start", "stop"
    var repeatHaptics: Bool = false
}

final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var assistEvents: [AssistEvent] = []
    @Published var isWatchConnected = false
    @Published var isWatchReachable = false
    @Published var lastEventTime: Date?
    @Published var watchSessionActive = false
    @Published var watchSettings = WatchSettings()
    @Published var isWatchCalibrating = false
    @Published var calibrationProgress: Double = 0.0
    @Published var calibrationTimeRemaining: Int = 30
    @Published var lastHeartbeatTime: Date?
    @Published var heartbeatLatency: TimeInterval = 0.0
    @Published var sessionActivated = false
    @Published var activationState: WCSessionActivationState = .notActivated
    @Published var sessionStartTime: Date?
    @Published var liveAccelerometerData: [AccelerometerData] = []
    @Published var lastCalibrationResults: CalibrationResults?
    @Published var isWatchMonitoring = false
    @Published var latestStepData: StepData?

    private let session: WCSession?
    private var heartbeatTimer: Timer?
    var wcSession: WCSession? { session }
    private let eventsKey = "gaitguard.assistEvents"
    private let settingsKey = "gaitguard.watchSettings"
    private var pendingEvents: [AssistEvent] = []
    private let maxLiveDataPoints = 500
    
    override init() {
        if WCSession.isSupported() {
            session = WCSession.default
        } else {
            session = nil
        }
        super.init()
        
        session?.delegate = self
        session?.activate()
        sessionStartTime = Date() // Track when we started activation
        
        loadEvents()
        loadSettings()
        updateConnectionStatus()
        syncPendingEvents()
        
        #if DEBUG
        print("[GaitGuard] WatchConnectivityManager initialized")
        #endif
    }
    
    deinit {
        stopHeartbeat()
    }
    
    // MARK: - Settings Management
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(WatchSettings.self, from: data) {
            watchSettings = decoded
        }
    }
    
    func updateSettings(_ newSettings: WatchSettings) {
        watchSettings = newSettings
        if let encoded = try? JSONEncoder().encode(newSettings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
        sendSettingsToWatch()
    }
    
    private func sendSettingsToWatch() {
        guard let session = session, session.activationState == .activated else {
            #if DEBUG
            print("[GaitGuard] ⚠️ Cannot send settings: WCSession not activated")
            #endif
            return
        }

        if let data = try? JSONEncoder().encode(watchSettings) {
            if session.isReachable {
                session.sendMessage(
                    ["watchSettings": data],
                    replyHandler: nil,
                    errorHandler: { error in
                        #if DEBUG
                        print("[GaitGuard] ⚠️ Settings send error: \(error.localizedDescription)")
                        #endif
                    }
                )
            } else {
                try? session.updateApplicationContext(["watchSettings": data])
            }
        }
    }
    
    // MARK: - Connection Status
    
    func updateConnectionStatus() {
        guard let session = session else {
            DispatchQueue.main.async { [weak self] in
                self?.isWatchConnected = false
                self?.isWatchReachable = false
                self?.watchSessionActive = false
                self?.sessionActivated = false
            }
            return
        }
        
        // Check if session is activated
        let currentActivationState = session.activationState
        let isActivated = currentActivationState == .activated
        
        let isPaired: Bool
        let isReachable: Bool
        
        #if os(watchOS)
        isPaired = true
        isReachable = isActivated && session.isReachable
        #else
        isPaired = isActivated && session.isPaired
        isReachable = isActivated && session.isReachable
        
        // Check for simulator/device mismatch
        #if targetEnvironment(simulator)
        if isActivated && !session.isPaired {
            #if DEBUG
            print("[GaitGuard] ⚠️ Running on Simulator - WatchConnectivity requires both apps on physical devices")
            #endif
        }
        #endif
        #endif
        
        // Update on main thread for UI
        DispatchQueue.main.async { [weak self] in
            self?.activationState = currentActivationState
            self?.sessionActivated = isActivated
            self?.isWatchConnected = isPaired
            self?.isWatchReachable = isReachable
            self?.watchSessionActive = isActivated
            
            #if DEBUG
            if !isActivated {
                switch currentActivationState {
                case .notActivated:
                    print("[GaitGuard] ⚠️ WCSession not activated yet (still initializing)")
                case .inactive:
                    print("[GaitGuard] ⚠️ WCSession is inactive")
                case .activated:
                    // Shouldn't reach here, but included for exhaustiveness
                    break
                @unknown default:
                    print("[GaitGuard] ⚠️ WCSession in unknown state")
                }
            }
            
            #if !os(watchOS)
            if isActivated && !session.isPaired {
                print("[GaitGuard] ⚠️ iPhone: Watch app not installed on paired watch")
            }
            #else
            if isActivated && !session.isReachable {
                print("[GaitGuard] ⚠️ Watch: iPhone app not installed or not reachable")
            }
            #endif
            #endif
        }
    }
    
    // MARK: - Watch → iPhone (send from watch)
    
    func sendAssistEvent(type: String, severity: Double = 0.5, duration: TimeInterval? = nil) {
        guard let session = session, session.activationState == .activated else {
            let event = AssistEvent(timestamp: Date(), type: type, severity: severity, duration: duration)
            pendingEvents.append(event)
            #if DEBUG
            print("[GaitGuard] ⚠️ Cannot send event: WCSession not activated - queued for later")
            #endif
            return
        }

        let event = AssistEvent(timestamp: Date(), type: type, severity: severity, duration: duration)

        #if DEBUG
        #if os(watchOS)
        print("[GaitGuard] Watch → Assist event: \(type) (severity: \(String(format: "%.2f", severity)))")
        #endif
        #endif

        guard let data = try? JSONEncoder().encode(event) else { return }

        if session.isReachable {
            session.sendMessage(
                ["assistEvent": data],
                replyHandler: nil,
                errorHandler: { [weak self] error in
                    self?.pendingEvents.append(event)
                    #if DEBUG
                    print("[GaitGuard] ⚠️ Event send error, queued: \(error.localizedDescription)")
                    #endif
                }
            )
        } else {
            pendingEvents.append(event)
            try? session.updateApplicationContext(["assistEvent": data])
        }
    }
    
    private func syncPendingEvents() {
        guard let session = session,
              session.activationState == .activated,
              session.isReachable,
              !pendingEvents.isEmpty else { return }

        let eventsToSync = pendingEvents
        pendingEvents.removeAll()

        for event in eventsToSync {
            if let data = try? JSONEncoder().encode(event) {
                session.sendMessage(
                    ["assistEvent": data],
                    replyHandler: nil,
                    errorHandler: { [weak self] error in
                        self?.pendingEvents.append(event)
                        #if DEBUG
                        print("[GaitGuard] ⚠️ Pending event sync error: \(error.localizedDescription)")
                        #endif
                    }
                )
            }
        }

        #if DEBUG
        print("[GaitGuard] Synced \(eventsToSync.count) pending events")
        #endif
    }

    // MARK: - Monitoring State Sync

    #if os(watchOS)
    func sendMonitoringState(isMonitoring: Bool) {
        guard let session = session, session.activationState == .activated else { return }

        let payload: [String: Any] = ["monitoringState": isMonitoring]

        if session.isReachable {
            session.sendMessage(
                payload,
                replyHandler: nil,
                errorHandler: { error in
                    #if DEBUG
                    print("[GaitGuard] ⚠️ Monitoring state send error: \(error.localizedDescription)")
                    #endif
                }
            )
        }
        try? session.updateApplicationContext(payload)
    }

    func sendStepData(stepCount: Int, cadence: Double?, distance: Double?) {
        guard let session = session, session.activationState == .activated else { return }

        let data = StepData(
            stepCount: stepCount,
            cadence: cadence,
            distance: distance,
            timestamp: Date()
        )

        guard let encoded = try? JSONEncoder().encode(data) else { return }

        if session.isReachable {
            session.sendMessage(
                ["stepData": encoded],
                replyHandler: nil,
                errorHandler: { error in
                    #if DEBUG
                    print("[GaitGuard] ⚠️ Step data send error: \(error.localizedDescription)")
                    #endif
                }
            )
        }
    }
    #endif
    
    // MARK: - iPhone (receive + store)
    
    private func receiveAssistEvent(_ data: Data) {
        guard let event = try? JSONDecoder().decode(AssistEvent.self, from: data) else { return }
        
        #if DEBUG
        #if !os(watchOS)
        print("[GaitGuard] iPhone → Assist event received: \(event.type) at \(event.timestamp)")
        #endif
        #endif
        
        // Update on main thread for real-time UI updates
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.assistEvents.append(event)
            self.lastEventTime = event.timestamp
            
            // Keep last 100 events
            if self.assistEvents.count > 100 {
                self.assistEvents.removeFirst(self.assistEvents.count - 100)
            }
            self.saveEvents()
        }
    }
    
    private func saveEvents() {
        if let encoded = try? JSONEncoder().encode(assistEvents) {
            UserDefaults.standard.set(encoded, forKey: eventsKey)
        }
    }
    
    private func loadEvents() {
        guard let data = UserDefaults.standard.data(forKey: eventsKey),
              let decoded = try? JSONDecoder().decode([AssistEvent].self, from: data) else { return }
        assistEvents = decoded
    }
    
    func clearEvents() {
        assistEvents.removeAll()
        UserDefaults.standard.removeObject(forKey: eventsKey)
    }
    
    // MARK: - Live Accelerometer Data Streaming
    
    #if os(watchOS)
    func sendAccelerometerData(x: Double, y: Double, z: Double, timestamp: Date) {
        guard let session = session, session.activationState == .activated,
              session.isReachable else { return }

        let data = AccelerometerData(x: x, y: y, z: z, timestamp: timestamp)
        guard let encoded = try? JSONEncoder().encode(data) else { return }

        session.sendMessage(
            ["accelerometerData": encoded],
            replyHandler: nil,
            errorHandler: { _ in }
        )
    }
    #endif
    
    func sendCalibrationResults(average: Double, standardDeviation: Double, baselineThreshold: Double, sampleCount: Int) {
        #if os(watchOS)
        guard let session = session, session.activationState == .activated else { return }

        let results = CalibrationResults(
            average: average,
            standardDeviation: standardDeviation,
            baselineThreshold: baselineThreshold,
            sampleCount: sampleCount,
            timestamp: Date()
        )

        guard let encoded = try? JSONEncoder().encode(results) else { return }

        if session.isReachable {
            session.sendMessage(
                ["calibrationResults": encoded],
                replyHandler: nil,
                errorHandler: { error in
                    try? session.updateApplicationContext(["calibrationResults": encoded])
                    #if DEBUG
                    print("[GaitGuard] ⚠️ Calibration results fallback to context: \(error.localizedDescription)")
                    #endif
                }
            )
        } else {
            try? session.updateApplicationContext(["calibrationResults": encoded])
        }

        #if DEBUG
        print("[GaitGuard] Watch → Calibration results sent: avg=\(String(format: "%.3f", average)), threshold=\(String(format: "%.3f", baselineThreshold))")
        #endif
        #endif
    }
    
    // MARK: - Test Haptic

    func testHaptic() {
        updateConnectionStatus()

        guard let session = session,
              session.activationState == .activated,
              session.isReachable else {
            #if DEBUG
            print("[GaitGuard] ⚠️ Cannot test haptic: session not ready")
            #endif
            return
        }

        session.sendMessage(
            ["testHaptic": true],
            replyHandler: nil,
            errorHandler: { error in
                #if DEBUG
                print("[GaitGuard] ⚠️ Test haptic error: \(error.localizedDescription)")
                #endif
            }
        )
    }
    
    // MARK: - Factory Reset
    
    func resetToFactorySettings() {
        guard let session = session, session.activationState == .activated else {
            #if DEBUG
            print("[GaitGuard] ⚠️ Cannot reset: WCSession not activated")
            #endif
            return
        }

        if session.isReachable {
            session.sendMessage(
                ["resetToFactory": true],
                replyHandler: nil,
                errorHandler: { error in
                    #if DEBUG
                    print("[GaitGuard] ⚠️ Reset send error: \(error.localizedDescription)")
                    #endif
                }
            )
        } else {
            try? session.updateApplicationContext(["resetToFactory": true])
        }

        #if DEBUG
        print("[GaitGuard] Reset to factory settings sent")
        #endif
    }
    
    // MARK: - Heartbeat System

    func startHeartbeat() {
        stopHeartbeat()

        #if os(watchOS)
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
        #endif

        #if DEBUG
        print("[GaitGuard] Heartbeat started")
        #endif
    }

    func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    private func sendHeartbeat() {
        #if os(watchOS)
        guard let session = session, session.activationState == .activated,
              session.isReachable else { return }

        let heartbeatData: [String: Any] = [
            "heartbeat": Date().timeIntervalSince1970
        ]

        session.sendMessage(
            heartbeatData,
            replyHandler: nil,
            errorHandler: { error in
                #if DEBUG
                print("[GaitGuard] ⚠️ Heartbeat error: \(error.localizedDescription)")
                #endif
            }
        )
        #endif
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            if let error = error {
                #if DEBUG
                print("[GaitGuard] ❌ WCSession activation failed: \(error.localizedDescription)")
                #endif
            } else {
                #if DEBUG
                if let startTime = self?.sessionStartTime {
                    let elapsed = Date().timeIntervalSince(startTime)
                    print("[GaitGuard] ✅ WCSession activated (took \(String(format: "%.1f", elapsed))s)")
                } else {
                    print("[GaitGuard] ✅ WCSession activated")
                }
                #endif
            }
            self?.activationState = activationState
            self?.updateConnectionStatus()
            self?.syncPendingEvents()
        }
    }

    #if !os(watchOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        #if DEBUG
        print("[GaitGuard] WCSession became inactive")
        #endif
    }

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.updateConnectionStatus()
            if session.isReachable {
                self?.syncPendingEvents()
                #if DEBUG
                print("[GaitGuard] ✅ Counterpart app became reachable")
                #endif
            } else {
                #if DEBUG
                print("[GaitGuard] ⚠️ Counterpart app became unreachable")
                #endif
            }
        }
    }

    // MARK: - Message Handling (no reply expected)

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncomingMessage(message)
    }

    // MARK: - Message Handling (reply expected)

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        handleIncomingMessage(message)
        replyHandler(["ack": true])
    }

    private func handleIncomingMessage(_ message: [String: Any]) {
        // Heartbeat from watch
        if message["heartbeat"] != nil {
            handleHeartbeat(message)
            return
        }

        // Shared messages (both platforms)
        if let data = message["assistEvent"] as? Data {
            receiveAssistEvent(data)
        }
        if let data = message["watchSettings"] as? Data,
           let settings = try? JSONDecoder().decode(WatchSettings.self, from: data) {
            DispatchQueue.main.async { [weak self] in
                self?.watchSettings = settings
            }
        }

        // Platform-specific handling
        #if os(watchOS)
        handleWatchIncoming(message)
        #else
        handleiPhoneIncoming(message)
        #endif
    }

    private func handleHeartbeat(_ message: [String: Any]) {
        #if !os(watchOS)
        guard let timestamp = message["heartbeat"] as? TimeInterval else { return }
        let sentDate = Date(timeIntervalSince1970: timestamp)
        let latency = Date().timeIntervalSince(sentDate)
        DispatchQueue.main.async { [weak self] in
            self?.lastHeartbeatTime = Date()
            self?.heartbeatLatency = latency
            self?.isWatchReachable = true
        }
        #if DEBUG
        print("[GaitGuard] iPhone ← Heartbeat (\(String(format: "%.0f", latency * 1000))ms)")
        #endif
        #endif
    }

    #if !os(watchOS)
    private func handleiPhoneIncoming(_ message: [String: Any]) {
        if let monitoring = message["monitoringState"] as? Bool {
            DispatchQueue.main.async { [weak self] in
                self?.isWatchMonitoring = monitoring
            }
        }
        if let data = message["stepData"] as? Data,
           let steps = try? JSONDecoder().decode(StepData.self, from: data) {
            DispatchQueue.main.async { [weak self] in
                self?.latestStepData = steps
            }
        }
        if let data = message["calibrationStatus"] as? Data {
            struct CalibrationStatus: Codable {
                let isCalibrating: Bool
                let progress: Double
                let timeRemaining: Int
            }
            if let status = try? JSONDecoder().decode(CalibrationStatus.self, from: data) {
                DispatchQueue.main.async { [weak self] in
                    self?.isWatchCalibrating = status.isCalibrating
                    self?.calibrationProgress = status.progress
                    self?.calibrationTimeRemaining = status.timeRemaining
                }
            }
        }
        if let data = message["calibrationResults"] as? Data,
           let results = try? JSONDecoder().decode(CalibrationResults.self, from: data) {
            DispatchQueue.main.async { [weak self] in
                self?.lastCalibrationResults = results
            }
        }
        if let data = message["accelerometerData"] as? Data,
           let accelData = try? JSONDecoder().decode(AccelerometerData.self, from: data) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.liveAccelerometerData.append(accelData)
                if self.liveAccelerometerData.count > self.maxLiveDataPoints {
                    self.liveAccelerometerData.removeFirst(self.liveAccelerometerData.count - self.maxLiveDataPoints)
                }
            }
        }
    }
    #endif

    #if os(watchOS)
    private func handleWatchIncoming(_ message: [String: Any]) {
        if message["testHaptic"] != nil {
            let device = WKInterfaceDevice.current()
            let hapticType: WKHapticType
            switch watchSettings.hapticPattern {
            case "notification": hapticType = .notification
            case "start": hapticType = .start
            case "stop": hapticType = .stop
            case "click": hapticType = .click
            default: hapticType = .directionUp
            }
            device.play(hapticType)
        }
        if message["resetToFactory"] != nil {
            NotificationCenter.default.post(name: NSNotification.Name("ResetToFactorySettings"), object: nil)
        }
    }
    #endif

    // MARK: - Application Context

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let data = applicationContext["assistEvent"] as? Data {
            receiveAssistEvent(data)
        }

        if let data = applicationContext["watchSettings"] as? Data,
           let settings = try? JSONDecoder().decode(WatchSettings.self, from: data) {
            DispatchQueue.main.async { [weak self] in
                self?.watchSettings = settings
            }
        }

        if let monitoring = applicationContext["monitoringState"] as? Bool {
            #if !os(watchOS)
            DispatchQueue.main.async { [weak self] in
                self?.isWatchMonitoring = monitoring
            }
            #endif
        }

        #if !os(watchOS)
        if let data = applicationContext["calibrationResults"] as? Data,
           let results = try? JSONDecoder().decode(CalibrationResults.self, from: data) {
            DispatchQueue.main.async { [weak self] in
                self?.lastCalibrationResults = results
            }
        }
        #endif
    }
}

