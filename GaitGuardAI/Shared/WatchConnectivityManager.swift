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

extension AssistEvent: Identifiable {
    var id: Date { timestamp }
}

struct StepData: Codable {
    let stepCount: Int
    let cadence: Double?
    let distance: Double?
    let timestamp: Date
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
    @Published var dailyNotes: [String: String] = [:] // key: yyyy-MM-dd
    
    private let session: WCSession?
    private var heartbeatTimer: Timer?
    var wcSession: WCSession? { session }
    private let eventsKey = "gaitguard.assistEvents"
    private let settingsKey = "gaitguard.watchSettings"
    private let notesKey = "gaitguard.dailyNotes"
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
        sessionStartTime = Date()
        
        loadEvents()
        loadSettings()
        loadNotes()
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
        guard let data = try? JSONEncoder().encode(watchSettings) else { return }
        
        if session.isReachable {
            session.sendMessage(["watchSettings": data], replyHandler: nil) { [weak self] error in
                #if DEBUG
                print("[GaitGuard] ⚠️ sendMessage watchSettings failed: \(error.localizedDescription)")
                #endif
                self?.sendSettingsViaContext(data)
            }
        } else {
            sendSettingsViaContext(data)
        }
    }
    
    private func sendSettingsViaContext(_ data: Data) {
        guard let session = session, session.activationState == .activated else { return }
        do {
            try session.updateApplicationContext(["watchSettings": data])
            #if DEBUG
            print("[GaitGuard] Settings sent via application context (watch not reachable)")
            #endif
        } catch {
            #if DEBUG
            print("[GaitGuard] ⚠️ updateApplicationContext settings failed: \(error.localizedDescription)")
            #endif
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
        
        #if targetEnvironment(simulator)
        if isActivated && !session.isPaired {
            #if DEBUG
            print("[GaitGuard] ⚠️ Running on Simulator - WatchConnectivity requires both apps on physical devices")
            #endif
        }
        #endif
        #endif
        
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
        print("[GaitGuard] Watch → Assist event sent: \(type) (severity: \(String(format: "%.2f", severity)))")
        #endif
        #endif
        
        guard let data = try? JSONEncoder().encode(event) else { return }
        
        #if os(watchOS)
        if session.isReachable {
            session.sendMessage(["assistEvent": data], replyHandler: nil) { [weak self] error in
                #if DEBUG
                print("[GaitGuard] ⚠️ sendMessage assistEvent failed: \(error.localizedDescription)")
                #endif
                self?.pendingEvents.append(event)
                try? session.updateApplicationContext(["assistEvent": data])
            }
        } else {
            pendingEvents.append(event)
            try? session.updateApplicationContext(["assistEvent": data])
        }
        #else
        if session.isReachable || session.isPaired {
            if session.isReachable {
                session.sendMessage(["assistEvent": data], replyHandler: nil) { error in
                    #if DEBUG
                    print("[GaitGuard] ⚠️ sendMessage assistEvent failed: \(error.localizedDescription)")
                    #endif
                }
            } else {
                try? session.updateApplicationContext(["assistEvent": data])
            }
        }
        #endif
    }
    
    private func syncPendingEvents() {
        guard let session = session, session.isReachable, !pendingEvents.isEmpty else { return }
        
        for event in pendingEvents {
            if let data = try? JSONEncoder().encode(event) {
                session.sendMessage(["assistEvent": data], replyHandler: nil) { error in
                    #if DEBUG
                    print("[GaitGuard] ⚠️ syncPendingEvents sendMessage failed: \(error.localizedDescription)")
                    #endif
                }
            }
        }
        pendingEvents.removeAll()
    }
    
    // MARK: - Daily Notes
    
    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: notesKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            dailyNotes = decoded
        }
    }
    
    func saveNote(for date: Date, text: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let key = formatter.string(from: date)
        
        if text.isEmpty {
            dailyNotes.removeValue(forKey: key)
        } else {
            dailyNotes[key] = text
        }
        
        if let encoded = try? JSONEncoder().encode(dailyNotes) {
            UserDefaults.standard.set(encoded, forKey: notesKey)
        }
    }
    
    // MARK: - iPhone (receive + store)
    
    private func receiveAssistEvent(_ data: Data) {
        guard let event = try? JSONDecoder().decode(AssistEvent.self, from: data) else { return }
        
        #if DEBUG
        #if !os(watchOS)
        print("[GaitGuard] iPhone → Assist event received: \(event.type) at \(event.timestamp)")
        #endif
        #endif
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.assistEvents.append(event)
            self.lastEventTime = event.timestamp
            
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
        guard let session = session, session.activationState == .activated else { return }
        
        let data = AccelerometerData(x: x, y: y, z: z, timestamp: timestamp)
        
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        
        if session.isReachable {
            session.sendMessage(["accelerometerData": encoded], replyHandler: nil) { error in
                #if DEBUG
                print("[GaitGuard] ⚠️ sendMessage accelerometerData failed: \(error.localizedDescription)")
                #endif
            }
        }
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
            session.sendMessage(["calibrationResults": encoded], replyHandler: nil) { error in
                #if DEBUG
                print("[GaitGuard] ⚠️ sendMessage calibrationResults failed: \(error.localizedDescription)")
                #endif
                try? session.updateApplicationContext(["calibrationResults": encoded])
            }
        } else {
            try? session.updateApplicationContext(["calibrationResults": encoded])
        }
        
        #if DEBUG
        print("[GaitGuard] Watch → Calibration results sent: avg=\(String(format: "%.3f", average)), stdDev=\(String(format: "%.3f", standardDeviation)), threshold=\(String(format: "%.3f", baselineThreshold))")
        #endif
        #endif
    }
    
    // MARK: - Test Haptic
    
    func testHaptic() {
        updateConnectionStatus()
        
        guard let session = session else {
            #if DEBUG
            print("[GaitGuard] ⚠️ Cannot test haptic: WCSession not available")
            #endif
            return
        }
        
        guard session.activationState == .activated else {
            #if DEBUG
            print("[GaitGuard] ⚠️ Cannot test haptic: WCSession not activated")
            #endif
            return
        }
        
        guard session.isReachable else {
            #if DEBUG
            print("[GaitGuard] ⚠️ Cannot test haptic: Watch not reachable")
            #endif
            return
        }
        
        session.sendMessage(
            ["testHaptic": true],
            replyHandler: { _ in
                #if DEBUG
                print("[GaitGuard] ✅ Test haptic confirmed by watch")
                #endif
            },
            errorHandler: { error in
                #if DEBUG
                print("[GaitGuard] ⚠️ testHaptic sendMessage failed: \(error.localizedDescription)")
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
        guard session.isReachable else {
            #if DEBUG
            print("[GaitGuard] ⚠️ Cannot reset: Watch not reachable")
            #endif
            return
        }
        session.sendMessage(["resetToFactory": true], replyHandler: nil) { error in
            #if DEBUG
            print("[GaitGuard] ⚠️ resetToFactory sendMessage failed: \(error.localizedDescription)")
            #endif
        }
        
        #if DEBUG
        print("[GaitGuard] Reset to factory settings sent to watch")
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
        guard let session = session, session.activationState == .activated else {
            #if DEBUG
            print("[GaitGuard] Watch → Heartbeat skipped (session not activated)")
            #endif
            return
        }
        guard session.isReachable else {
            #if DEBUG
            print("[GaitGuard] Watch → Heartbeat skipped (not reachable)")
            #endif
            return
        }
        
        let timestamp = Date().timeIntervalSince1970
        let heartbeatData: [String: Any] = [
            "heartbeat": timestamp
        ]
        
        session.sendMessage(heartbeatData, replyHandler: nil) { error in
            #if DEBUG
            print("[GaitGuard] ⚠️ sendMessage heartbeat failed: \(error.localizedDescription)")
            #endif
        }
        
        #if DEBUG
        print("[GaitGuard] Watch → Heartbeat sent")
        #endif
        #endif
    }
    
    // MARK: - Monitoring State & Step Data (watchOS only)
    
    #if os(watchOS)
    func sendMonitoringState(isMonitoring: Bool) {
        guard let session = session, session.activationState == .activated else { return }
        
        let payload: [String: Any] = ["monitoringState": isMonitoring]
        
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { [weak self] error in
                #if DEBUG
                print("[GaitGuard] ⚠️ sendMessage monitoringState failed: \(error.localizedDescription)")
                #endif
                try? session.updateApplicationContext(payload)
            }
        } else {
            try? session.updateApplicationContext(payload)
        }
    }
    
    func sendStepData(stepCount: Int, cadence: Double?, distance: Double?) {
        guard let session = session, session.activationState == .activated else { return }
        
        let stepData = StepData(
            stepCount: stepCount,
            cadence: cadence,
            distance: distance,
            timestamp: Date()
        )
        
        guard let encoded = try? JSONEncoder().encode(stepData) else { return }
        
        if session.isReachable {
            session.sendMessage(["stepData": encoded], replyHandler: nil) { error in
                #if DEBUG
                print("[GaitGuard] ⚠️ sendMessage stepData failed: \(error.localizedDescription)")
                #endif
            }
        }
    }
    #endif
    
    #if os(watchOS)
    private func getMotionDetector() -> MotionDetector? {
        return nil
    }
    #endif
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
                switch activationState {
                case .activated:
                    if let startTime = self?.sessionStartTime {
                        let activationTime = Date().timeIntervalSince(startTime)
                        #if DEBUG
                        print("[GaitGuard] ✅ WCSession activated successfully (took \(String(format: "%.1f", activationTime))s)")
                        #endif
                    } else {
                        #if DEBUG
                        print("[GaitGuard] ✅ WCSession activated successfully")
                        #endif
                    }
                case .notActivated:
                    #if DEBUG
                    print("[GaitGuard] ⚠️ WCSession not activated - still initializing")
                    #endif
                case .inactive:
                    #if DEBUG
                    print("[GaitGuard] ⚠️ WCSession is inactive")
                    #endif
                @unknown default:
                    #if DEBUG
                    print("[GaitGuard] ⚠️ WCSession in unknown state")
                    #endif
                }
            }
            self?.activationState = activationState
            self?.updateConnectionStatus()
        }
    }
    
    #if !os(watchOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleIncomingMessage(message, session: session, replyHandler: nil)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        handleIncomingMessage(message, session: session, replyHandler: replyHandler)
    }
    
    private func handleIncomingMessage(_ message: [String : Any], session: WCSession, replyHandler: (([String : Any]) -> Void)?) {
        if let timestamp = message["heartbeat"] as? TimeInterval {
            #if !os(watchOS)
            let now = Date()
            let latency = now.timeIntervalSince1970 - timestamp
            DispatchQueue.main.async { [weak self] in
                self?.lastHeartbeatTime = now
                self?.heartbeatLatency = latency
            }
            #if DEBUG
            print("[GaitGuard] iPhone → Heartbeat received (latency: \(String(format: "%.3f", latency))s)")
            #endif
            #endif
            replyHandler?([:])
            return
        }
        
        if let data = message["assistEvent"] as? Data {
            #if DEBUG
            print("[GaitGuard] iPhone → Assist event received")
            #endif
            receiveAssistEvent(data)
        }
        
        if let data = message["watchSettings"] as? Data,
           let settings = try? JSONDecoder().decode(WatchSettings.self, from: data) {
            DispatchQueue.main.async { [weak self] in
                self?.watchSettings = settings
            }
            #if DEBUG
            print("[GaitGuard] Watch → Settings updated")
            #endif
        }
        
        if let monitoring = message["monitoringState"] as? Bool {
            DispatchQueue.main.async { [weak self] in
                self?.isWatchMonitoring = monitoring
            }
        }
        
        if let data = message["stepData"] as? Data,
           let stepData = try? JSONDecoder().decode(StepData.self, from: data) {
            DispatchQueue.main.async { [weak self] in
                self?.latestStepData = stepData
            }
        }
        
        #if !os(watchOS)
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
            #if DEBUG
            print("[GaitGuard] iPhone → Calibration results received: avg=\(String(format: "%.3f", results.average)), threshold=\(String(format: "%.3f", results.baselineThreshold))")
            #endif
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
        #endif
        
        #if os(watchOS)
        if message["testHaptic"] != nil {
            let device = WKInterfaceDevice.current()
            let hapticType: WKHapticType
            switch watchSettings.hapticPattern {
            case "notification":
                hapticType = .notification
            case "start":
                hapticType = .start
            case "stop":
                hapticType = .stop
            case "click":
                hapticType = .click
            default:
                hapticType = .directionUp
            }
            device.play(hapticType)
            replyHandler?([:])
            
            #if DEBUG
            print("[GaitGuard] Watch → Test haptic triggered")
            #endif
        }
        
        if message["resetToFactory"] != nil {
            NotificationCenter.default.post(name: NSNotification.Name("ResetToFactorySettings"), object: nil)
            #if DEBUG
            print("[GaitGuard] Watch → Factory reset received")
            #endif
        }
        #endif
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
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
            DispatchQueue.main.async { [weak self] in
                self?.isWatchMonitoring = monitoring
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.updateConnectionStatus()
            self?.syncPendingEvents()
        }
    }
}
