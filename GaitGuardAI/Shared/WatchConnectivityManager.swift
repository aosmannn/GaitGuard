// WatchConnectivityManager.swift
// Shared between watch + iPhone to sync assist events.
import Foundation
import WatchConnectivity
import Combine
#if os(watchOS)
import WatchKit
#endif

struct AssistEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let type: String // "start" or "turn"
    let severity: Double // 0.0 to 1.0, magnitude normalized
    let duration: TimeInterval? // Optional: how long the freeze lasted

    init(id: UUID = UUID(), timestamp: Date = Date(), type: String, severity: Double, duration: TimeInterval? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.severity = severity
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey {
        case id, timestamp, type, severity, duration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        type = try container.decode(String.self, forKey: .type)
        severity = try container.decode(Double.self, forKey: .severity)
        duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
    }
}

extension AssistEvent {
    /// Softened severity label for UI (honest but less punitive mid-range wording).
    var severityLabel: String {
        if severity < 0.33 { return "Mild" }
        if severity < 0.66 { return "Moderate" }
        return "Strong"
    }
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

/// Shared Watch gait-score formula (Watch is source of truth when live).
enum GaitScoreCalculator {
    static func score(todaysAssists: Int, steps: Int) -> Int {
        var penalty = Double(todaysAssists * 10) // softened from *12
        let offset = Double(steps) / 150.0
        penalty = max(0, penalty - offset)
        return max(0, min(100, Int(100.0 - penalty)))
    }

    static func label(for score: Int, isMonitoring: Bool) -> String {
        guard isMonitoring else { return "Ready" }
        if score >= 85 { return "Steady" }
        if score >= 65 { return "Supported" }
        if score >= 40 { return "Assisting" }
        return "High Support"
    }
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
    /// Set when monitoring starts; cleared when monitoring stops. Not WC activation time.
    @Published var sessionStartTime: Date?
    @Published var liveAccelerometerData: [AccelerometerData] = []
    @Published var lastCalibrationResults: CalibrationResults?
    @Published var isWatchMonitoring = false
    @Published var latestStepData: StepData?
    @Published var dailyNotes: [String: String] = [:] // key: yyyy-MM-dd
    /// Watch-sourced gait score (nil when idle / unknown).
    @Published var latestGaitScore: Int?
    /// Why monitoring last stopped (e.g. "battery", "session_expired", "remote", "user").
    @Published var monitoringStopReason: String?
    /// True when settings were saved locally but Watch was not reachable.
    @Published var settingsQueuedOffline = false
    /// Watch-only: brief assist cue banner payload.
    @Published var assistBannerType: String?
    @Published var assistBannerVisible = false

    private let session: WCSession?
    private var heartbeatTimer: Timer?
    var wcSession: WCSession? { session }
    private let eventsKey = "gaitguard.assistEvents"
    private let settingsKey = "gaitguard.watchSettings"
    private let notesKey = "gaitguard.dailyNotes"
    private let calibrationKey = "gaitguard.lastCalibrationResults"
    private var pendingEvents: [AssistEvent] = []
    private let maxLiveDataPoints = 500
    private let eventRetentionDays: TimeInterval = 90 * 24 * 60 * 60
    private var cachedGaitScore: Int = 0
    /// Full application-context payload. `updateApplicationContext` REPLACES the previous
    /// dictionary, so every push must send the merged state or fields overwrite each other.
    private var contextCache: [String: Any] = [:]
    private var assistBannerClearWork: DispatchWorkItem?

    override init() {
        if WCSession.isSupported() {
            session = WCSession.default
        } else {
            session = nil
        }
        super.init()

        session?.delegate = self
        session?.activate()
        // Do NOT set sessionStartTime here — that tracks live monitoring, not WC activation.

        loadEvents()
        loadSettings()
        loadNotes()
        loadCalibrationResults()
        updateConnectionStatus()
        syncPendingEvents()

        #if DEBUG
        print("[GaitGuard] WatchConnectivityManager initialized")
        #endif
    }

    deinit {
        stopHeartbeat()
    }

    // MARK: - State Snapshot (latest-wins channel)

    /// Merge fields into the shared context and publish the whole dictionary.
    private func mergeContext(_ updates: [String: Any]) {
        for (k, v) in updates { contextCache[k] = v }
        guard let session = session, session.activationState == .activated else { return }
        do {
            try session.updateApplicationContext(contextCache)
        } catch {
            #if DEBUG
            print("[GaitGuard] ⚠️ updateApplicationContext failed: \(error.localizedDescription)")
            #endif
        }
    }

    /// Push everything the other device needs to render the same UI. Called on activation,
    /// reachability changes and whenever the counterpart asks via `requestSync`.
    func pushSnapshot() {
        var snapshot: [String: Any] = [:]
        #if os(watchOS)
        snapshot["monitoringState"] = isWatchMonitoring
        if isWatchMonitoring { snapshot["gaitScore"] = cachedGaitScore }
        if let start = sessionStartTime { snapshot["sessionStart"] = start.timeIntervalSince1970 }
        if let cal = lastCalibrationResults, let data = try? JSONEncoder().encode(cal) {
            snapshot["calibrationResults"] = data
        }
        if let data = latestStepData.flatMap({ try? JSONEncoder().encode($0) }) {
            snapshot["stepData"] = data
        }
        #else
        if let data = try? JSONEncoder().encode(watchSettings) { snapshot["watchSettings"] = data }
        #endif
        mergeContext(snapshot)

        if let session = session, session.isReachable {
            session.sendMessage(snapshot, replyHandler: nil, errorHandler: nil)
        }
    }

    /// Ask the counterpart to push its latest snapshot (used right after launch/activation).
    func requestSync() {
        guard let session = session, session.activationState == .activated, session.isReachable else { return }
        session.sendMessage(["requestSync": true], replyHandler: nil, errorHandler: nil)
    }

    /// Apply a snapshot received through any channel (message, userInfo or context).
    private func applySnapshot(_ payload: [String: Any]) {
        if let data = payload["watchSettings"] as? Data,
           let settings = try? JSONDecoder().decode(WatchSettings.self, from: data) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.watchSettings = settings
                if let encoded = try? JSONEncoder().encode(settings) {
                    UserDefaults.standard.set(encoded, forKey: self.settingsKey)
                }
            }
        }
        if let monitoring = payload["monitoringState"] as? Bool {
            let reason = payload["monitoringStopReason"] as? String
            let start = (payload["sessionStart"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
            DispatchQueue.main.async { [weak self] in
                self?.applyMonitoringState(monitoring, reason: reason)
                if monitoring, let start = start { self?.sessionStartTime = start }
            }
        }
        if let score = payload["gaitScore"] as? Int {
            DispatchQueue.main.async { [weak self] in self?.applyGaitScore(score) }
        }
        if let data = payload["stepData"] as? Data,
           let stepData = try? JSONDecoder().decode(StepData.self, from: data) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let current = self.latestStepData, current.timestamp > stepData.timestamp { return }
                self.latestStepData = stepData
            }
        }
        #if !os(watchOS)
        if let data = payload["calibrationResults"] as? Data,
           let results = try? JSONDecoder().decode(CalibrationResults.self, from: data) {
            DispatchQueue.main.async { [weak self] in self?.persistCalibrationResults(results) }
        }
        #endif
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
            DispatchQueue.main.async { [weak self] in self?.settingsQueuedOffline = true }
            return
        }
        guard let data = try? JSONEncoder().encode(watchSettings) else { return }

        // Context is the durable channel: the Watch picks it up even if it is asleep.
        mergeContext(["watchSettings": data])

        if session.isReachable {
            session.sendMessage(["watchSettings": data], replyHandler: { [weak self] _ in
                DispatchQueue.main.async { self?.settingsQueuedOffline = false }
            }, errorHandler: { [weak self] _ in
                DispatchQueue.main.async { self?.settingsQueuedOffline = true }
            })
        } else {
            DispatchQueue.main.async { [weak self] in self?.settingsQueuedOffline = true }
        }
    }

    // MARK: - Calibration Persistence

    private func loadCalibrationResults() {
        if let data = UserDefaults.standard.data(forKey: calibrationKey),
           let decoded = try? JSONDecoder().decode(CalibrationResults.self, from: data) {
            lastCalibrationResults = decoded
        }
    }

    private func persistCalibrationResults(_ results: CalibrationResults) {
        lastCalibrationResults = results
        if let encoded = try? JSONEncoder().encode(results) {
            UserDefaults.standard.set(encoded, forKey: calibrationKey)
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

            if isReachable {
                self?.settingsQueuedOffline = false
            }

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
        let event = AssistEvent(timestamp: Date(), type: type, severity: severity, duration: duration)

        #if os(watchOS)
        DispatchQueue.main.async { [weak self] in
            self?.showAssistBanner(type: type)
        }
        #endif

        guard let session = session, session.activationState == .activated else {
            pendingEvents.append(event)
            #if DEBUG
            print("[GaitGuard] ⚠️ Cannot send event: WCSession not activated - queued for later")
            #endif
            return
        }

        #if DEBUG
        #if os(watchOS)
        print("[GaitGuard] Watch → Assist event sent: \(type) (severity: \(String(format: "%.2f", severity)))")
        #endif
        #endif

        guard let data = try? JSONEncoder().encode(event) else { return }

        #if os(watchOS)
        // Prefer transferUserInfo so events survive when application context is overwritten.
        session.transferUserInfo(["assistEvent": data])

        if session.isReachable {
            session.sendMessage(["assistEvent": data], replyHandler: nil) { error in
                #if DEBUG
                print("[GaitGuard] ⚠️ sendMessage assistEvent failed: \(error.localizedDescription)")
                #endif
            }
        }
        #else
        if session.isReachable {
            session.sendMessage(["assistEvent": data], replyHandler: nil) { error in
                #if DEBUG
                print("[GaitGuard] ⚠️ sendMessage assistEvent failed: \(error.localizedDescription)")
                #endif
            }
        } else {
            session.transferUserInfo(["assistEvent": data])
        }
        #endif
    }

    #if os(watchOS)
    private func showAssistBanner(type: String) {
        assistBannerType = type
        assistBannerVisible = true
        assistBannerClearWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.assistBannerVisible = false
            self?.assistBannerType = nil
        }
        assistBannerClearWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: work)
    }
    #endif

    private func syncPendingEvents() {
        guard let session = session, session.activationState == .activated, !pendingEvents.isEmpty else { return }

        for event in pendingEvents {
            if let data = try? JSONEncoder().encode(event) {
                session.transferUserInfo(["assistEvent": data])
                if session.isReachable {
                    session.sendMessage(["assistEvent": data], replyHandler: nil) { error in
                        #if DEBUG
                        print("[GaitGuard] ⚠️ syncPendingEvents sendMessage failed: \(error.localizedDescription)")
                        #endif
                    }
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
            if self.assistEvents.contains(where: { $0.id == event.id }) { return }
            // Also skip near-duplicates with same timestamp+type (legacy events without stable UUID on wire)
            if self.assistEvents.contains(where: {
                abs($0.timestamp.timeIntervalSince(event.timestamp)) < 0.05 && $0.type == event.type
            }) { return }

            self.assistEvents.append(event)
            self.lastEventTime = event.timestamp
            self.pruneOldEvents()
            self.saveEvents()
        }
    }

    private func pruneOldEvents() {
        let cutoff = Date().addingTimeInterval(-eventRetentionDays)
        assistEvents.removeAll { $0.timestamp < cutoff }
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
        pruneOldEvents()
    }

    func clearEvents() {
        assistEvents.removeAll()
        UserDefaults.standard.removeObject(forKey: eventsKey)
        if let session = session, session.activationState == .activated {
            if session.isReachable {
                session.sendMessage(["clearEvents": true], replyHandler: nil, errorHandler: nil)
            } else {
                session.transferUserInfo(["clearEvents": true])
            }
        }
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

        DispatchQueue.main.async { [weak self] in
            self?.persistCalibrationResults(results)
        }

        guard let encoded = try? JSONEncoder().encode(results) else { return }

        if session.isReachable {
            session.sendMessage(["calibrationResults": encoded], replyHandler: nil) { [self] error in
                #if DEBUG
                print("[GaitGuard] ⚠️ sendMessage calibrationResults failed: \(error.localizedDescription)")
                #endif
                self.mergeContext(["calibrationResults": encoded])
            }
        } else {
            mergeContext(["calibrationResults": encoded])
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

    // MARK: - Remote Start / Stop (iPhone → Watch)

    #if !os(watchOS)
    @discardableResult
    func requestStartMonitoring() -> Bool {
        updateConnectionStatus()
        guard let session = session,
              session.activationState == .activated,
              session.isReachable else { return false }
        session.sendMessage(["startMonitoring": true], replyHandler: { [weak self] _ in
            DispatchQueue.main.async {
                self?.applyMonitoringState(true, reason: nil)
            }
        }, errorHandler: { error in
            #if DEBUG
            print("[GaitGuard] ⚠️ startMonitoring failed: \(error.localizedDescription)")
            #endif
        })
        return true
    }

    @discardableResult
    func requestStopMonitoring() -> Bool {
        updateConnectionStatus()
        guard let session = session, session.activationState == .activated else { return false }
        guard session.isReachable else {
            // Safe to queue: the Watch stops as soon as it next wakes.
            session.transferUserInfo(["stopMonitoring": true])
            applyMonitoringState(false, reason: "remote")
            return true
        }
        session.sendMessage(["stopMonitoring": true], replyHandler: { [weak self] _ in
            DispatchQueue.main.async {
                self?.applyMonitoringState(false, reason: "remote")
            }
        }, errorHandler: { error in
            #if DEBUG
            print("[GaitGuard] ⚠️ stopMonitoring failed: \(error.localizedDescription)")
            #endif
        })
        return true
    }
    #endif

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

    /// Cache the latest Watch-computed score so heartbeats / step updates include it.
    func updateCachedGaitScore(_ score: Int) {
        cachedGaitScore = score
        #if os(watchOS)
        // Avoid flooding WC: cache here; heartbeat + step payloads carry the score.
        DispatchQueue.main.async { [weak self] in
            self?.latestGaitScore = score
        }
        #endif
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
            "heartbeat": timestamp,
            "gaitScore": cachedGaitScore,
            "monitoringState": true
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
    func sendMonitoringState(isMonitoring: Bool, reason: String? = nil) {
        guard let session = session, session.activationState == .activated else {
            DispatchQueue.main.async { [weak self] in
                self?.applyMonitoringState(isMonitoring, reason: reason)
            }
            return
        }

        var payload: [String: Any] = [
            "monitoringState": isMonitoring
        ]
        if isMonitoring {
            payload["gaitScore"] = cachedGaitScore
        }
        if let reason = reason {
            payload["monitoringStopReason"] = reason
        }

        DispatchQueue.main.async { [weak self] in
            self?.applyMonitoringState(isMonitoring, reason: reason)
        }

        if isMonitoring { payload["sessionStart"] = (sessionStartTime ?? Date()).timeIntervalSince1970 }
        mergeContext(payload)
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else if !isMonitoring {
            // Queue the stop so the reason is delivered even if the context is superseded.
            session.transferUserInfo(payload)
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

        let payload: [String: Any] = [
            "stepData": encoded,
            "gaitScore": cachedGaitScore
        ]

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { error in
                #if DEBUG
                print("[GaitGuard] ⚠️ sendMessage stepData failed: \(error.localizedDescription)")
                #endif
            }
        } else {
            mergeContext(payload)
        }
        DispatchQueue.main.async { [weak self] in self?.latestStepData = stepData }
    }
    #endif

    /// Apply monitoring flag + session timer + optional stop reason (both platforms).
    func applyMonitoringState(_ monitoring: Bool, reason: String?) {
        isWatchMonitoring = monitoring
        if monitoring {
            if sessionStartTime == nil {
                sessionStartTime = Date()
            }
            monitoringStopReason = nil
        } else {
            sessionStartTime = nil
            latestGaitScore = nil
            if let reason = reason {
                monitoringStopReason = reason
            }
        }
    }

    private func applyGaitScore(_ score: Int) {
        latestGaitScore = score
        cachedGaitScore = score
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
                switch activationState {
                case .activated:
                    #if DEBUG
                    print("[GaitGuard] ✅ WCSession activated successfully")
                    #endif
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
            if activationState == .activated {
                // Catch up on anything sent while this app was not running.
                self?.applySnapshot(session.receivedApplicationContext)
                self?.pushSnapshot()
                self?.requestSync()
            }
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

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handleIncomingMessage(userInfo, session: session, replyHandler: nil)
    }

    private func handleIncomingMessage(_ message: [String : Any], session: WCSession, replyHandler: (([String : Any]) -> Void)?) {
        if let timestamp = message["heartbeat"] as? TimeInterval {
            #if !os(watchOS)
            let now = Date()
            let latency = now.timeIntervalSince1970 - timestamp
            DispatchQueue.main.async { [weak self] in
                self?.lastHeartbeatTime = now
                self?.heartbeatLatency = latency
                if let score = message["gaitScore"] as? Int {
                    self?.applyGaitScore(score)
                }
                if let monitoring = message["monitoringState"] as? Bool {
                    self?.applyMonitoringState(monitoring, reason: nil)
                }
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

        applySnapshot(message)

        if message["requestSync"] != nil {
            DispatchQueue.main.async { [weak self] in self?.pushSnapshot() }
        }

        if message["clearEvents"] != nil {
            DispatchQueue.main.async { [weak self] in
                self?.assistEvents.removeAll()
                UserDefaults.standard.removeObject(forKey: self?.eventsKey ?? "")
                #if os(watchOS)
                NotificationCenter.default.post(name: NSNotification.Name("ClearAssistEvents"), object: nil)
                #endif
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

        if message["startMonitoring"] != nil {
            NotificationCenter.default.post(name: NSNotification.Name("RemoteStartMonitoring"), object: nil)
            replyHandler?(["ok": true])
            #if DEBUG
            print("[GaitGuard] Watch → Remote start monitoring received")
            #endif
        }

        if message["stopMonitoring"] != nil {
            NotificationCenter.default.post(name: NSNotification.Name("RemoteStopMonitoring"), object: nil)
            replyHandler?(["ok": true])
            #if DEBUG
            print("[GaitGuard] Watch → Remote stop monitoring received")
            #endif
        }
        #endif
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let data = applicationContext["assistEvent"] as? Data {
            receiveAssistEvent(data)
        }
        applySnapshot(applicationContext)
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.updateConnectionStatus()
            self?.syncPendingEvents()
            if session.isReachable {
                self?.pushSnapshot()
                self?.requestSync()
            }
        }
    }
}
