import Foundation
import CoreMotion
import WatchKit
import SwiftUI
import Combine
import WatchConnectivity

// NOTE: You may see a harmless CoreMotion warning about reading com.apple.CoreMotion.plist
// (NSCocoaErrorDomain 257). Apps can't read that system file; CoreMotion carries on without it.

/// The Watch-side engine: reads motion, runs the freeze/turn detector, plays cues, runs calibration,
/// and keeps the iPhone in sync. All signal maths lives in GaitAnalysis.swift (unit-tested).
final class MotionDetector: ObservableObject {
    // MARK: UI state
    @Published var isCalibrating = false
    @Published var calibrationProgress: Double = 0.0 // 0.0 to 1.0
    @Published var calibrationTimeRemaining: Int = 30 // seconds
    /// "idle", "getReady" or "walking".
    @Published var calibrationPhase: String = "idle"
    @Published var calibrationSteps: Int = 0
    @Published var calibrationCadence: Double?
    @Published var calibrationError: String?
    @Published var batteryLow: Bool = false
    @Published var monitoringStoppedDueToBattery: Bool = false
    @Published var lastAssistTime: Date?
    @Published var todaysTotal: Int = 0 { didSet { refreshScore() } }
    @Published var isMonitoring = false
    @Published var currentSteps: Int = 0 { didSet { refreshScore() } }
    /// Live steadiness score, owned by the engine so it keeps updating (and syncing) whatever page is on screen.
    @Published private(set) var gaitScore: Int = 0
    @Published var currentCadence: Double?
    @Published var currentDistance: Double?
    /// True while the last few seconds looked like walking.
    @Published private(set) var isWalking = false
    /// The most recent cue, waiting for a thumbs-up / thumbs-down.
    @Published private(set) var pendingFeedback: AssistEvent?

    // MARK: Sensors
    private let motionManager = CMMotionManager()
    private let pedometer = CMPedometer()
    private let sensorQueue: OperationQueue = {
        let q = OperationQueue()
        q.name = "gaitguard.sensors"
        q.maxConcurrentOperationCount = 1
        q.qualityOfService = .userInitiated
        return q
    }()
    private let sampleRate = 50.0

    /// State touched from the sensor queue. Guarded by `lock`.
    private let lock = NSLock()
    private var detector = FreezeDetector()
    private var tracker = TurnTracker()
    private var mags: [Double] = []
    private var sampleCounter = 0
    private var lastStepTime: Date?
    private var collectingForMonitoring = false
    private var collectingForCalibration = false
    private var calSamples: [Double] = []

    // MARK: Timers & bookkeeping
    private var stepDataTimer: Timer?
    private var batteryTimer: Timer?
    private var calibrationTimer: Timer?
    private var feedbackWork: DispatchWorkItem?
    private var cueWork: [DispatchWorkItem] = []
    private var cueBusyUntil = Date.distantPast
    private var beatLoopActive = false
    private var recentEvents: [UUID: AssistEvent] = [:]
    private var activeEventID: UUID?
    private var assistEventsToday: [Date] = []
    private var freezeLog: [(end: Date, seconds: Double)] = []
    private var freezeOngoingSince: Date?
    private var walkFreqs: [Double] = []
    private var settingsCancellable: AnyCancellable?
    #if targetEnvironment(simulator)
    private var simulatedWalkTimer: Timer?
    private var simulatedCueCount = 0
    #endif

    // MARK: Persistence keys
    private let eventsKey = "gaitguard.assistEventsToday"
    private let profileKey = "gaitguard.gaitProfile"
    private let feedbackScaleKey = "gaitguard.feedbackScale"
    private let calibrationDuration: TimeInterval = 30
    private let getReadySeconds = 3

    private var profile: GaitProfile?
    /// Personal sensitivity nudge from thumbs-up / thumbs-down feedback. 1.0 = neutral.
    private var feedbackScale: Double = 1.0

    init() {
        loadProfile()
        feedbackScale = UserDefaults.standard.object(forKey: feedbackScaleKey) as? Double ?? 1.0
        loadTodayEvents()
        updateTodaysTotal()
        applyTuning()
        settingsCancellable = WatchConnectivityManager.shared.$watchSettings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.applyTuning() }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ClearAssistEvents"), object: nil, queue: .main) { [weak self] _ in
            self?.clearTodayEvents()
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("RemoteCancelCalibration"), object: nil, queue: .main) { [weak self] _ in
            self?.stopCalibration()
        }
    }

    var lastAssistTimeText: String {
        guard let lastAssist = lastAssistTime else { return "Never" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: lastAssist)
    }

    // MARK: - Persistence

    private func loadTodayEvents() {
        if let data = UserDefaults.standard.data(forKey: eventsKey),
           let dates = try? JSONDecoder().decode([Date].self, from: data) {
            assistEventsToday = dates
            lastAssistTime = dates.last
        }
    }

    private func saveTodayEvents() {
        if let encoded = try? JSONEncoder().encode(assistEventsToday) {
            UserDefaults.standard.set(encoded, forKey: eventsKey)
        }
    }

    private func loadProfile() {
        if let data = UserDefaults.standard.data(forKey: profileKey) {
            profile = try? JSONDecoder().decode(GaitProfile.self, from: data)
        }
    }

    /// History cleared on iPhone: zero today's count so both screens agree.
    func clearTodayEvents() {
        assistEventsToday = []
        lastAssistTime = nil
        todaysTotal = 0
        saveTodayEvents()
    }

    private func updateTodaysTotal() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        assistEventsToday = assistEventsToday.filter { calendar.startOfDay(for: $0) == today }
        todaysTotal = assistEventsToday.count
        saveTodayEvents()
    }

    // MARK: - Tuning

    /// Build detector thresholds from calibration, the Detection mode and the wearer's feedback.
    private func makeTuning() -> DetectorTuning {
        let s = WatchConnectivityManager.shared.watchSettings
        var t = DetectorTuning()
        if s.adaptiveThreshold, let p = profile {
            t.freezeIndexThreshold = p.freezeIndexThreshold
            t.walkPower = p.walkPower
        }
        // Detection modes map to `sensitivity`: 1.3 = Everyday, 2.0 = Exercise (calmer), 0.8 = High alert.
        let mult = max(0.5, min(2.5, s.sensitivity / 1.3))
        t.freezeIndexThreshold = max(1.2, min(8, t.freezeIndexThreshold * mult * feedbackScale))
        t.useStallCriterion = s.sensitivity < 1.0
        return t
    }

    private func applyTuning() {
        let tuning = makeTuning()
        lock.lock(); detector.tuning = tuning; lock.unlock()
    }

    // MARK: - Score

    private func refreshScore() {
        guard isMonitoring else { return }
        let now = Date()
        let tenMinAgo = now.addingTimeInterval(-600)
        freezeLog.removeAll { $0.end < tenMinAgo }
        var freezeSeconds = freezeLog.map(\.seconds).reduce(0, +)
        if let since = freezeOngoingSince { freezeSeconds += now.timeIntervalSince(since) }
        let cues = assistEventsToday.filter { $0 >= tenMinAgo }.count
        var regularity: Double?
        if walkFreqs.count >= 6 {
            let m = walkFreqs.reduce(0, +) / Double(walkFreqs.count)
            let sd = (walkFreqs.map { pow($0 - m, 2) }.reduce(0, +) / Double(walkFreqs.count)).squareRoot()
            regularity = m > 0 ? 1 - min(1, (sd / m) / 0.3) : nil
        }
        let score = Steadiness.score(strideRegularity: regularity, freezeSecondsLast10Min: freezeSeconds, cuesLast10Min: cues)
        if score != gaitScore { gaitScore = score }
        WatchConnectivityManager.shared.updateCachedGaitScore(score)
    }

    // MARK: - Sensors

    private func startSensors() {
        guard motionManager.isDeviceMotionAvailable else { return }
        guard !motionManager.isDeviceMotionActive else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / sampleRate
        motionManager.startDeviceMotionUpdates(to: sensorQueue) { [weak self] motion, error in
            if let error = error {
                #if DEBUG
                if (error as NSError).code != 257 { print("[MotionDetector] motion error: \(error.localizedDescription)") }
                #endif
                return
            }
            guard let self = self, let m = motion else { return }
            self.handleSample(m)
        }
    }

    private func stopSensorsIfIdle() {
        lock.lock()
        let idle = !collectingForMonitoring && !collectingForCalibration
        lock.unlock()
        if idle { motionManager.stopDeviceMotionUpdates() }
    }

    /// Runs on the sensor queue.
    private func handleSample(_ m: CMDeviceMotion) {
        let a = m.userAcceleration
        let mag = (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot()
        let g = m.gravity, r = m.rotationRate
        let yawRate = r.x * g.x + r.y * g.y + r.z * g.z // rotation about gravity ≈ turning

        lock.lock()
        if collectingForCalibration { calSamples.append(mag) }
        var window: SpectralFeatures?
        var events: [DetectorEvent] = []
        var walkingNow = false
        var dominant = 0.0
        if collectingForMonitoring {
            tracker.push(rate: yawRate, at: m.timestamp)
            mags.append(mag)
            if mags.count > 150 { mags.removeFirst(mags.count - 150) }
            sampleCounter += 1
            if sampleCounter % 25 == 0 && mags.count >= 150 {
                let f = GaitSpectrum.analyze(mags, sampleRate: sampleRate)
                let now = Date()
                let stepsRecently = lastStepTime.map { now.timeIntervalSince($0) < 6 } ?? false
                events = detector.process(f, yawAngle: tracker.angle, stepsRecently: stepsRecently, now: now)
                if events.contains(where: { if case .turnHesitation = $0 { return true } else { return false } }) { tracker.reset() }
                walkingNow = f.locoPower >= detector.tuning.walkPower
                dominant = f.dominantFrequency
                window = f
            }
        }
        lock.unlock()

        if window != nil {
            DispatchQueue.main.async { [weak self] in
                self?.applyWindow(walking: walkingNow, dominant: dominant, events: events)
            }
        }
    }

    /// Main thread: apply one analysed window.
    private func applyWindow(walking: Bool, dominant: Double, events: [DetectorEvent]) {
        guard isMonitoring else { return }
        if walking != isWalking { isWalking = walking }
        if walking && dominant > 0 {
            walkFreqs.append(dominant)
            if walkFreqs.count > 20 { walkFreqs.removeFirst() }
        }
        for e in events { handle(e) }
        refreshScore()
    }

    // MARK: - Detector events → cues

    private func handle(_ event: DetectorEvent) {
        switch event {
        case .freezeStart(let severity, _):
            freezeOngoingSince = Date()
            let e = recordCue(type: "start", severity: severity)
            activeEventID = e.id
        case .freezeRepeat:
            if WatchConnectivityManager.shared.watchSettings.repeatHaptics { playCuePattern() }
        case .freezeEnd(let duration):
            freezeOngoingSince = nil
            freezeLog.append((Date(), duration))
            if let id = activeEventID, var e = recentEvents[id] {
                e.duration = duration
                recentEvents[id] = e
                WatchConnectivityManager.shared.sendAssistEvent(e, banner: false)
                if pendingFeedback?.id == id { pendingFeedback = e }
            }
            activeEventID = nil
        case .turnHesitation(let severity):
            _ = recordCue(type: "turn", severity: severity)
        }
    }

    /// Log a cue, play it, tell the iPhone, and ask the wearer how it went.
    @discardableResult
    private func recordCue(type: String, severity: Double) -> AssistEvent {
        let now = Date()
        assistEventsToday.append(now)
        lastAssistTime = now
        updateTodaysTotal()

        let event = AssistEvent(timestamp: now, type: type, severity: severity)
        recentEvents[event.id] = event
        if recentEvents.count > 20, let oldest = recentEvents.min(by: { $0.value.timestamp < $1.value.timestamp }) {
            recentEvents.removeValue(forKey: oldest.key)
        }
        playCuePattern()
        WatchConnectivityManager.shared.sendAssistEvent(event, banner: true)

        pendingFeedback = event
        feedbackWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.pendingFeedback = nil }
        feedbackWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 12, execute: work)
        return event
    }

    /// Thumbs-up / thumbs-down on the latest cue. Teaches the detector and updates the iPhone's copy.
    func recordFeedback(helpful: Bool) {
        guard var e = pendingFeedback else { return }
        e.helpful = helpful
        recentEvents[e.id] = e
        WatchConnectivityManager.shared.sendAssistEvent(e, banner: false)
        // Unneeded cue → be a little calmer. Helpful cue → hold steady, slightly more alert.
        feedbackScale = helpful ? max(0.75, feedbackScale * 0.97) : min(1.6, feedbackScale * 1.08)
        UserDefaults.standard.set(feedbackScale, forKey: feedbackScaleKey)
        applyTuning()
        pendingFeedback = nil
        feedbackWork?.cancel()
        WKInterfaceDevice.current().play(.click)
    }

    // MARK: - Calibration

    func hasCalibrationData() -> Bool { profile != nil }
    func isCalibrationUnstable() -> Bool { calibrationError != nil }

    func startCalibration() {
        guard !isCalibrating, !isMonitoring else { return }
        isCalibrating = true
        calibrationError = nil
        calibrationSteps = 0
        calibrationCadence = nil
        calibrationProgress = 0
        calibrationTimeRemaining = Int(calibrationDuration)
        calibrationPhase = "getReady"
        WKInterfaceDevice.current().play(.start)
        sendCalibrationStatus()

        var countdown = getReadySeconds
        calibrationTimer?.invalidate()
        calibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            countdown -= 1
            if countdown > 0 {
                WKInterfaceDevice.current().play(.click)
                self.sendCalibrationStatus()
            } else {
                timer.invalidate()
                self.beginWalkingPhase()
            }
        }
    }

    private func beginWalkingPhase() {
        guard isCalibrating else { return }
        calibrationPhase = "walking"
        WKInterfaceDevice.current().play(.directionUp)
        let started = Date()

        lock.lock(); calSamples.removeAll(); collectingForCalibration = true; lock.unlock()
        startSensors()
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: started) { [weak self] data, _ in
                guard let data = data else { return }
                DispatchQueue.main.async { self?.calibrationSteps = data.numberOfSteps.intValue }
            }
        }
        sendCalibrationStatus()

        calibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            let elapsed = Date().timeIntervalSince(started)
            let remaining = max(0, self.calibrationDuration - elapsed)
            self.calibrationTimeRemaining = Int(remaining.rounded(.up))
            self.calibrationProgress = min(1.0, elapsed / self.calibrationDuration)
            #if targetEnvironment(simulator)
            self.calibrationSteps += 2
            #endif
            if elapsed > 3 { self.calibrationCadence = Double(self.calibrationSteps) / elapsed * 60 }
            self.sendCalibrationStatus()
            if remaining <= 0 {
                timer.invalidate()
                self.finishCalibration(walkingSeconds: elapsed)
            }
        }
    }

    private func sendCalibrationStatus(finalError: String? = nil) {
        #if os(watchOS)
        struct CalibrationStatus: Codable {
            let isCalibrating: Bool
            let progress: Double
            let timeRemaining: Int
            var phase: String? = nil
            var steps: Int? = nil
            var cadence: Double? = nil
            var error: String? = nil
        }
        let status = CalibrationStatus(isCalibrating: isCalibrating, progress: calibrationProgress,
                                       timeRemaining: calibrationTimeRemaining, phase: calibrationPhase,
                                       steps: calibrationSteps, cadence: calibrationCadence, error: finalError)
        guard let session = WatchConnectivityManager.shared.wcSession, session.isReachable else { return }
        guard let data = try? JSONEncoder().encode(status) else { return }
        session.sendMessage(["calibrationStatus": data], replyHandler: nil) { error in
            #if DEBUG
            print("[MotionDetector] ⚠️ sendMessage calibrationStatus failed: \(error.localizedDescription)")
            #endif
        }
        #endif
    }

    func stopCalibration() {
        calibrationTimer?.invalidate()
        calibrationTimer = nil
        pedometer.stopUpdates()
        lock.lock(); collectingForCalibration = false; calSamples.removeAll(); lock.unlock()
        stopSensorsIfIdle()
        isCalibrating = false
        calibrationPhase = "idle"
        calibrationProgress = 0
        sendCalibrationStatus()
    }

    private func finishCalibration(walkingSeconds: Double) {
        pedometer.stopUpdates()
        lock.lock()
        collectingForCalibration = false
        var samples = calSamples
        calSamples.removeAll()
        lock.unlock()
        stopSensorsIfIdle()

        #if targetEnvironment(simulator)
        if samples.count < 150 { // simulators have no motion sensors; feed a believable walk
            samples = (0..<Int(30 * sampleRate)).map { i in
                let t = Double(i) / sampleRate
                return 0.16 * sin(2 * .pi * 1.0 * t) + 0.26 * sin(2 * .pi * 1.9 * t) + 0.004 * Double.random(in: -0.5...0.5)
            }
        }
        #endif

        let result = CalibrationAnalyzer.analyze(samples: samples, sampleRate: sampleRate,
                                                 steps: calibrationSteps, walkingSeconds: walkingSeconds)
        isCalibrating = false
        calibrationPhase = "idle"
        switch result {
        case .success(let p):
            profile = p
            if let data = try? JSONEncoder().encode(p) { UserDefaults.standard.set(data, forKey: profileKey) }
            feedbackScale = 1.0
            UserDefaults.standard.set(feedbackScale, forKey: feedbackScaleKey)
            calibrationError = nil
            calibrationCadence = p.cadence
            applyTuning()
            WatchConnectivityManager.shared.sendCalibrationResults(
                average: p.freezeIndexMean, standardDeviation: p.freezeIndexStd,
                baselineThreshold: p.freezeIndexThreshold, sampleCount: samples.count,
                cadence: p.cadence, steps: p.steps, quality: p.quality)
            sendCalibrationStatus()
            WKInterfaceDevice.current().play(.success)
        case .failure(let failure):
            calibrationError = failure.message
            sendCalibrationStatus(finalError: failure.message)
            WKInterfaceDevice.current().play(.failure)
        }
    }

    func resetToFactorySettings() {
        UserDefaults.standard.removeObject(forKey: profileKey)
        UserDefaults.standard.removeObject(forKey: feedbackScaleKey)
        for k in ["gaitguard.calibrationData", "gaitguard.calibrationAverage", "gaitguard.calibrationStdDev", "gaitguard.calibrationUnstable"] {
            UserDefaults.standard.removeObject(forKey: k)
        }
        profile = nil
        feedbackScale = 1.0
        calibrationError = nil
        applyTuning()
    }

    // MARK: - Monitoring

    func startMonitoring() {
        #if !targetEnvironment(simulator)
        guard motionManager.isDeviceMotionAvailable else { return }
        #endif

        if batteryTooLowToStart() {
            monitoringStoppedDueToBattery = true
            WatchConnectivityManager.shared.sendMonitoringState(isMonitoring: false, reason: "battery")
            WKInterfaceDevice.current().play(.failure)
            return
        }
        if isCalibrating { stopCalibration() }

        monitoringStoppedDueToBattery = false
        batteryLow = false
        isMonitoring = true
        freezeLog.removeAll(); freezeOngoingSince = nil; walkFreqs.removeAll()
        activeEventID = nil
        applyTuning()
        lock.lock()
        detector.reset(); tracker.reset(); mags.removeAll(); sampleCounter = 0; lastStepTime = nil
        collectingForMonitoring = true
        lock.unlock()
        refreshScore()
        WatchConnectivityManager.shared.sendMonitoringState(isMonitoring: true)
        WatchConnectivityManager.shared.startHeartbeat()

        #if targetEnvironment(simulator)
        startSimulatedWalk()
        #endif

        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: Date()) { [weak self] data, _ in
                guard let self = self, let data = data else { return }
                let steps = data.numberOfSteps.intValue
                self.lock.lock()
                if steps > self.currentStepsForSensor { self.lastStepTime = Date() }
                self.currentStepsForSensor = steps
                self.lock.unlock()
                DispatchQueue.main.async {
                    self.currentSteps = steps
                    if let pace = data.averageActivePace?.doubleValue, pace > 0 {
                        self.currentCadence = pace * 60.0
                    } else {
                        self.currentCadence = nil
                    }
                    self.currentDistance = data.distance?.doubleValue
                }
            }
        }

        stepDataTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.sendStepDataUpdate()
        }

        WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
        batteryTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkBattery()
        }

        startSensors()
        startBeatLoop()
    }

    /// Step count the sensor queue compares against (kept separate from the published value).
    private var currentStepsForSensor = 0

    func stopMonitoring(reason: String = "user") {
        lock.lock(); collectingForMonitoring = false; mags.removeAll(); lock.unlock()
        stopSensorsIfIdle()
        feedbackWork?.cancel()
        pendingFeedback = nil
        freezeOngoingSince = nil
        activeEventID = nil
        isWalking = false
        beatLoopActive = false

        isMonitoring = false
        WatchConnectivityManager.shared.sendMonitoringState(isMonitoring: false, reason: reason)
        WatchConnectivityManager.shared.stopHeartbeat()

        if CMPedometer.isStepCountingAvailable() { pedometer.stopUpdates() }
        stepDataTimer?.invalidate(); stepDataTimer = nil
        batteryTimer?.invalidate(); batteryTimer = nil
        #if targetEnvironment(simulator)
        simulatedWalkTimer?.invalidate()
        simulatedWalkTimer = nil
        #endif

        lock.lock(); currentStepsForSensor = 0; lock.unlock()
        currentSteps = 0
        currentCadence = nil
        currentDistance = nil
        if isCalibrating { stopCalibration() }
    }

    private func sendStepDataUpdate() {
        WatchConnectivityManager.shared.sendStepData(stepCount: currentSteps, cadence: currentCadence, distance: currentDistance)
    }

    // MARK: - Battery

    private func batteryTooLowToStart() -> Bool {
        let d = WKInterfaceDevice.current()
        d.isBatteryMonitoringEnabled = true
        return d.batteryLevel >= 0 && d.batteryLevel <= 0.10 && d.batteryState != .charging && d.batteryState != .full
    }

    private func checkBattery() {
        let d = WKInterfaceDevice.current()
        guard d.batteryLevel >= 0, d.batteryState != .charging, d.batteryState != .full else {
            if batteryLow { batteryLow = false }
            return
        }
        if d.batteryLevel <= 0.10 {
            monitoringStoppedDueToBattery = true
            stopMonitoring(reason: "battery")
            WKInterfaceDevice.current().play(.failure)
        } else if d.batteryLevel <= 0.20 {
            if !batteryLow { WKInterfaceDevice.current().play(.notification) }
            batteryLow = true
        } else {
            batteryLow = false
        }
    }

    // MARK: - Haptic cues

    /// Public method for the test cue (bypasses everything else).
    func triggerTestHaptic() { playCuePattern() }

    /// Rhythmic cue: a short run of evenly spaced haptic beats at the configured tempo,
    /// like a metronome on the wrist. Low intensity uses the lighter click haptic.
    func playCuePattern() {
        let settings = WatchConnectivityManager.shared.watchSettings
        let hapticType: WKHapticType
        if settings.hapticIntensity <= 0.4 {
            hapticType = .click
        } else {
            switch settings.hapticPattern {
            case "notification": hapticType = .notification
            case "start": hapticType = .start
            case "stop": hapticType = .stop
            case "click": hapticType = .click
            default: hapticType = .directionUp
            }
        }
        let beats = max(1, min(8, settings.cueBeats))
        let interval = 60.0 / max(60, min(140, settings.cueTempo))

        cueWork.forEach { $0.cancel() }
        cueWork = (0..<beats).map { i in
            let work = DispatchWorkItem { WKInterfaceDevice.current().play(hapticType) }
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval, execute: work)
            return work
        }
        cueBusyUntil = Date().addingTimeInterval(Double(beats) * interval + 0.4)
    }

    /// Optional soft metronome while walking ("Beat while walking"). Skips while a cue is playing.
    private func startBeatLoop() {
        guard !beatLoopActive else { return }
        beatLoopActive = true
        scheduleBeat()
    }

    private func scheduleBeat() {
        let s = WatchConnectivityManager.shared.watchSettings
        let interval = 60.0 / max(60, min(140, s.cueTempo))
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
            guard let self = self, self.beatLoopActive, self.isMonitoring else { return }
            let s = WatchConnectivityManager.shared.watchSettings
            if s.walkBeat, self.isWalking, self.freezeOngoingSince == nil, Date() > self.cueBusyUntil {
                WKInterfaceDevice.current().play(.click)
            }
            self.scheduleBeat()
        }
    }

    #if targetEnvironment(simulator)
    /// Simulators have no motion sensors or pedometer; fake a steady walk so the
    /// iPhone ↔ Watch sync can be exercised end to end.
    private func startSimulatedWalk() {
        simulatedWalkTimer?.invalidate()
        isWalking = true
        simulatedWalkTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentSteps += 2
            self.currentCadence = Double(104 + Int.random(in: 0...8))
            self.currentDistance = (self.currentDistance ?? 0) + 1.4
        }
    }

    /// Simulator-only: pretend a freeze happened and ended three seconds later.
    func simulateFreeze() {
        guard isMonitoring else { return }
        simulatedCueCount += 1
        if simulatedCueCount % 3 == 0 {
            handle(.turnHesitation(severity: Double.random(in: 0.3...0.9)))
        } else {
            handle(.freezeStart(severity: Double.random(in: 0.2...0.9), start: Date()))
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.handle(.freezeEnd(duration: Double.random(in: 1.5...4.0)))
            }
        }
    }
    #endif
}
