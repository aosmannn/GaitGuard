import Foundation
import CoreMotion
import WatchKit
import SwiftUI
import Combine
import WatchConnectivity

class MotionDetector: ObservableObject {
    @Published var isCalibrating = false
    @Published var calibrationProgress: Double = 0.0
    @Published var calibrationTimeRemaining: Int = 30
    @Published var batteryLow: Bool = false
    @Published var monitoringStoppedDueToBattery: Bool = false
    @Published var isMonitoring = false
    @Published var currentSteps: Int = 0
    @Published var currentCadence: Double?
    @Published var currentDistance: Double?

    private let motionManager = CMMotionManager()
    private let pedometer = CMPedometer()
    private var baselineMagnitude: Double = 1.0
    private var magnitudeHistory: [Double] = []
    private let historySize = 100
    private var freezeStartTime: Date?
    private var lastFreezeTime: Date?
    private var consecutiveFreezes = 0
    private var lastHapticTime: Date?
    private let hapticCooldownPeriod: TimeInterval = 2.5
    private var stepDataTimer: Timer?

    // Calibration data
    private var calibrationData: [Double] = []
    private var calibrationStartTime: Date?
    private var calibrationTimer: Timer?

    private let calibrationDuration: TimeInterval = 30.0
    private let calibrationDataKey = "gaitguard.calibrationData"
    private let calibrationAverageKey = "gaitguard.calibrationAverage"
    private let calibrationStdDevKey = "gaitguard.calibrationStdDev"

    init() {
        loadCalibrationData()
        setupMotionManager()
    }
    
    private func setupMotionManager() {
        // Check availability before accessing motion manager
        guard motionManager.isAccelerometerAvailable else {
            #if DEBUG
            print("[MotionDetector] Accelerometer not available")
            #endif
            return
        }
        
        // The warning about reading CoreMotion.plist is expected and harmless
        // It occurs at the system level when CoreMotion initializes
        // No action needed - the framework handles this gracefully
    }
    
    private func loadCalibrationData() {
        // Load saved calibration average to set baseline
        if let average = UserDefaults.standard.object(forKey: calibrationAverageKey) as? Double {
            baselineMagnitude = average
        }
    }
    
    // Adaptive threshold settings
    private var adaptiveThreshold: Double {
        let settings = WatchConnectivityManager.shared.watchSettings
        
        // First check if we have calibration data
        if let calibratedThreshold = getCalibratedThreshold() {
            if settings.adaptiveThreshold {
                return calibratedThreshold
            } else {
                // Use settings sensitivity but adjust based on calibration
                return max(settings.sensitivity, calibratedThreshold * 0.8)
            }
        }
        
        // Fallback to old logic if no calibration
        if settings.adaptiveThreshold {
            // Adaptive: baseline + 30% variance
            return baselineMagnitude * 1.3
        } else {
            // Fixed threshold from settings
            return settings.sensitivity
        }
    }
    
    // MARK: - Calibration
    
    func startCalibration() {
        guard !isCalibrating else { return }
        
        // Trigger haptic when calibration begins
        WKInterfaceDevice.current().play(.start)
        
        isCalibrating = true
        calibrationData.removeAll()
        calibrationStartTime = Date()
        calibrationProgress = 0.0
        calibrationTimeRemaining = Int(calibrationDuration)
        
        // Notify iPhone that calibration started
        sendCalibrationStatus()
        
        // Start collecting data
        startCalibrationDataCollection()
        
        // Start countdown timer
        calibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let elapsed = Date().timeIntervalSince(self.calibrationStartTime ?? Date())
            let remaining = max(0, self.calibrationDuration - elapsed)
            
            self.calibrationTimeRemaining = Int(remaining)
            self.calibrationProgress = min(1.0, elapsed / self.calibrationDuration)
            
            // Update iPhone every second
            self.sendCalibrationStatus()
            
            if remaining <= 0 {
                self.finishCalibration()
                timer.invalidate()
            }
        }
    }
    
    private func sendCalibrationStatus() {
        #if os(watchOS)
        struct CalibrationStatus: Codable {
            let isCalibrating: Bool
            let progress: Double
            let timeRemaining: Int
        }
        
        let status = CalibrationStatus(
            isCalibrating: isCalibrating,
            progress: calibrationProgress,
            timeRemaining: calibrationTimeRemaining
        )
        
        guard let session = WatchConnectivityManager.shared.wcSession, session.isReachable else { return }
        guard let data = try? JSONEncoder().encode(status) else { return }
        session.sendMessage(["calibrationStatus": data], replyHandler: nil)
        #endif
    }
    
    func stopCalibration() {
        isCalibrating = false
        calibrationTimer?.invalidate()
        calibrationTimer = nil
        calibrationData.removeAll()
        calibrationStartTime = nil
        motionManager.stopAccelerometerUpdates()
        
        // Notify iPhone that calibration stopped
        sendCalibrationStatus()
    }
    
    private func startCalibrationDataCollection() {
        guard motionManager.isAccelerometerAvailable else {
            stopCalibration()
            return
        }
        
        motionManager.accelerometerUpdateInterval = 1.0 / 50.0 // 50Hz
        
        // Counter for throttling live data streaming (10Hz = every 5th sample)
        var sampleCounter = 0
        
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            if let error = error {
                // Suppress harmless CoreMotion preference reading errors
                #if DEBUG
                if (error as NSError).code != 257 {
                    print("[MotionDetector] Calibration accelerometer error: \(error.localizedDescription)")
                }
                #endif
                return
            }
            guard let self = self, self.isCalibrating, let data = data else { return }
            
            let x = data.acceleration.x
            let y = data.acceleration.y
            let z = data.acceleration.z
            let magnitude = sqrt(x*x + y*y + z*z)
            
            // Only collect magnitude for baseline calculation
            self.calibrationData.append(magnitude)
            
            // Stream live data to iPhone during calibration (throttled to 10Hz to avoid overwhelming)
            sampleCounter += 1
            if sampleCounter % 5 == 0 { // 50Hz / 5 = 10Hz
                WatchConnectivityManager.shared.sendAccelerometerData(
                    x: x,
                    y: y,
                    z: z,
                    timestamp: Date()
                )
            }
        }
    }
    
    private func finishCalibration() {
        guard !calibrationData.isEmpty else {
            stopCalibration()
            return
        }
        
        // Calculate average
        let average = calibrationData.reduce(0, +) / Double(calibrationData.count)
        
        // Calculate standard deviation
        let variance = calibrationData.map { pow($0 - average, 2) }.reduce(0, +) / Double(calibrationData.count)
        let standardDeviation = sqrt(variance)
        
        // Quality check: if stdDev is too high (>50% of average), calibration is unstable
        let coefficientOfVariation = standardDeviation / average
        if coefficientOfVariation > 0.5 {
            // Calibration unstable - too noisy
            stopCalibration()
            // Show error state (will be handled in UI)
            DispatchQueue.main.async {
                // Store error state
                UserDefaults.standard.set(true, forKey: "gaitguard.calibrationUnstable")
            }
            // Error haptic
            WKInterfaceDevice.current().play(.failure)
            return
        }
        
        // Clear any previous error
        UserDefaults.standard.removeObject(forKey: "gaitguard.calibrationUnstable")
        
        // Calculate baseline threshold (mean + 2 standard deviations)
        let baselineThreshold = average + (2.0 * standardDeviation)
        
        // Save to UserDefaults
        UserDefaults.standard.set(calibrationData, forKey: calibrationDataKey)
        UserDefaults.standard.set(average, forKey: calibrationAverageKey)
        UserDefaults.standard.set(standardDeviation, forKey: calibrationStdDevKey)
        
        // Update baseline magnitude
        baselineMagnitude = average
        
        // Send calibration results to iPhone
        WatchConnectivityManager.shared.sendCalibrationResults(
            average: average,
            standardDeviation: standardDeviation,
            baselineThreshold: baselineThreshold,
            sampleCount: calibrationData.count
        )
        
        // Stop calibration
        stopCalibration()
        
        // Provide haptic feedback for completion
        WKInterfaceDevice.current().play(.success)
    }
    
    func isCalibrationUnstable() -> Bool {
        return UserDefaults.standard.bool(forKey: "gaitguard.calibrationUnstable")
    }
    
    func resetCalibrationError() {
        UserDefaults.standard.removeObject(forKey: "gaitguard.calibrationUnstable")
    }
    
    func resetToFactorySettings() {
        // Clear calibration data
        UserDefaults.standard.removeObject(forKey: calibrationDataKey)
        UserDefaults.standard.removeObject(forKey: calibrationAverageKey)
        UserDefaults.standard.removeObject(forKey: calibrationStdDevKey)
        UserDefaults.standard.removeObject(forKey: "gaitguard.calibrationUnstable")
        
        // Reset baseline to default
        baselineMagnitude = 1.0
    }
    
    private func getCalibratedThreshold() -> Double? {
        guard let average = UserDefaults.standard.object(forKey: calibrationAverageKey) as? Double,
              let stdDev = UserDefaults.standard.object(forKey: calibrationStdDevKey) as? Double else {
            return nil
        }
        
        // Threshold = average + 2 standard deviations (covers ~95% of normal gait)
        return average + (2.0 * stdDev)
    }
    
    func hasCalibrationData() -> Bool {
        return UserDefaults.standard.object(forKey: calibrationAverageKey) != nil
    }
    
    func getCalibrationInfo() -> (average: Double, stdDev: Double, threshold: Double)? {
        guard let average = UserDefaults.standard.object(forKey: calibrationAverageKey) as? Double,
              let stdDev = UserDefaults.standard.object(forKey: calibrationStdDevKey) as? Double else {
            return nil
        }
        
        let threshold = average + (2.0 * stdDev)
        return (average: average, stdDev: stdDev, threshold: threshold)
    }
    
    func startMonitoring() {
        guard motionManager.isAccelerometerAvailable else { return }

        if checkBatteryLevel() {
            monitoringStoppedDueToBattery = true
            WKInterfaceDevice.current().play(.failure)
            return
        }

        monitoringStoppedDueToBattery = false
        isMonitoring = true

        WatchConnectivityManager.shared.startHeartbeat()
        WatchConnectivityManager.shared.sendMonitoringState(isMonitoring: true)

        startStepCounting()

        motionManager.accelerometerUpdateInterval = 1.0 / 50.0

        var sampleCounter = 0

        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            if let error = error {
                #if DEBUG
                if (error as NSError).code != 257 {
                    print("[MotionDetector] Accelerometer error: \(error.localizedDescription)")
                }
                #endif
                return
            }
            guard let data = data else { return }

            if let self = self, self.magnitudeHistory.count % 3000 == 0, self.magnitudeHistory.count > 0 {
                if self.checkBatteryLevel() {
                    self.stopMonitoring()
                    self.monitoringStoppedDueToBattery = true
                    WKInterfaceDevice.current().play(.failure)
                    return
                }
            }

            let ax = data.acceleration.x
            let ay = data.acceleration.y
            let az = data.acceleration.z
            let magnitude = sqrt(ax * ax + ay * ay + az * az)

            self?.updateBaseline(magnitude)

            sampleCounter += 1
            if sampleCounter % 5 == 0 {
                WatchConnectivityManager.shared.sendAccelerometerData(
                    x: ax, y: ay, z: az, timestamp: Date()
                )
            }

            if magnitude > self?.adaptiveThreshold ?? 1.3 {
                self?.handleFreeze(magnitude: magnitude)
            }
        }

        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 1.0 / 50.0
            motionManager.startGyroUpdates(to: .main) { [weak self] gyroData, error in
                if let error = error {
                    #if DEBUG
                    if (error as NSError).code != 257 {
                        print("[MotionDetector] Gyroscope error: \(error.localizedDescription)")
                    }
                    #endif
                    return
                }
                guard let gyroData = gyroData else { return }

                if let accelData = self?.motionManager.accelerometerData {
                    let ax = accelData.acceleration.x
                    let ay = accelData.acceleration.y
                    let az = accelData.acceleration.z
                    let magnitude = sqrt(ax * ax + ay * ay + az * az)
                    self?.detectTurn(gyroData: gyroData, magnitude: magnitude)
                }
            }
        }
    }
    
    func stopMonitoring() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        freezeStartTime = nil
        lastFreezeTime = nil
        consecutiveFreezes = 0
        isMonitoring = false

        stopStepCounting()
        WatchConnectivityManager.shared.stopHeartbeat()
        WatchConnectivityManager.shared.sendMonitoringState(isMonitoring: false)

        if isCalibrating {
            stopCalibration()
        }
    }

    // MARK: - Step Counting

    private func startStepCounting() {
        guard CMPedometer.isStepCountingAvailable() else {
            #if DEBUG
            print("[MotionDetector] Step counting not available")
            #endif
            return
        }

        currentSteps = 0
        currentCadence = nil
        currentDistance = nil

        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            DispatchQueue.main.async {
                self.currentSteps = data.numberOfSteps.intValue
                self.currentCadence = data.currentCadence?.doubleValue
                self.currentDistance = data.distance?.doubleValue
            }
        }

        stepDataTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            WatchConnectivityManager.shared.sendStepData(
                stepCount: self.currentSteps,
                cadence: self.currentCadence,
                distance: self.currentDistance
            )
        }

        #if DEBUG
        print("[MotionDetector] Step counting started")
        #endif
    }

    private func stopStepCounting() {
        pedometer.stopUpdates()
        stepDataTimer?.invalidate()
        stepDataTimer = nil
    }
    
    // MARK: - Baseline & Adaptive Threshold
    
    private func updateBaseline(_ magnitude: Double) {
        magnitudeHistory.append(magnitude)
        if magnitudeHistory.count > historySize {
            magnitudeHistory.removeFirst()
        }
        
        // Calculate baseline as median of recent history
        if magnitudeHistory.count >= 20 {
            let sorted = magnitudeHistory.sorted()
            baselineMagnitude = sorted[sorted.count / 2]
        }
    }
    
    // MARK: - Freeze Detection
    
    private func handleFreeze(magnitude: Double) {
        let now = Date()
        
        // Calculate severity (0.0 to 1.0)
        let severity = min(1.0, (magnitude - adaptiveThreshold) / (adaptiveThreshold * 0.5))
        
        // Track freeze duration
        if freezeStartTime == nil {
            freezeStartTime = now
        }
        
        let duration = now.timeIntervalSince(freezeStartTime ?? now)
        
        // Only trigger if enough time has passed since last freeze (debounce)
        if let lastFreeze = lastFreezeTime, now.timeIntervalSince(lastFreeze) < 0.5 {
            return // Too soon, ignore
        }
        
        triggerRescue(type: "start", severity: severity, duration: duration > 0.1 ? duration : nil)
        lastFreezeTime = now
        
        // If freeze continues, repeat haptics if enabled
        if WatchConnectivityManager.shared.watchSettings.repeatHaptics && duration > 2.0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                if self?.freezeStartTime != nil {
                    self?.triggerRescue(type: "start", severity: severity, duration: duration)
                }
            }
        }
    }
    
    // MARK: - Turn Detection
    
    private func detectTurn(gyroData: CMGyroData, magnitude: Double) {
        let rotationRate = sqrt(gyroData.rotationRate.x * gyroData.rotationRate.x +
                                gyroData.rotationRate.y * gyroData.rotationRate.y +
                                gyroData.rotationRate.z * gyroData.rotationRate.z)
        
        // Turn detection: high rotation rate with low acceleration (pivoting)
        if rotationRate > 2.0 && magnitude < adaptiveThreshold * 0.8 {
            let now = Date()
            if let lastFreeze = lastFreezeTime, now.timeIntervalSince(lastFreeze) < 1.0 {
                return // Debounce
            }
            
            triggerRescue(type: "turn", severity: min(1.0, rotationRate / 5.0), duration: nil)
            lastFreezeTime = now
        }
    }
    
    // MARK: - Haptic Feedback
    
    private func triggerRescue(type: String, severity: Double, duration: TimeInterval?) {
        let now = Date()
        
        // Haptic fatigue prevention: enforce cooldown period
        if let lastHaptic = lastHapticTime {
            let timeSinceLastHaptic = now.timeIntervalSince(lastHaptic)
            if timeSinceLastHaptic < hapticCooldownPeriod {
                // Too soon - skip haptic but still send event
                WatchConnectivityManager.shared.sendAssistEvent(
                    type: type,
                    severity: severity,
                    duration: duration
                )
                return
            }
        }
        
        let settings = WatchConnectivityManager.shared.watchSettings
        let device = WKInterfaceDevice.current()
        
        // Select haptic pattern based on settings
        let hapticType: WKHapticType
        switch settings.hapticPattern {
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
        
        // Adjust intensity (watchOS doesn't support intensity directly, but we can repeat)
        let intensity = settings.hapticIntensity
        if intensity > 0.7 {
            device.play(hapticType)
        } else if intensity > 0.4 {
            // Medium: single haptic
            device.play(hapticType)
        } else {
            // Low: lighter haptic
            device.play(.click)
        }
        
        // Update last haptic time
        lastHapticTime = now
        
        // Send event to iPhone
        WatchConnectivityManager.shared.sendAssistEvent(
            type: type,
            severity: severity,
            duration: duration
        )
        
        // Reset freeze tracking if freeze ended
        if duration == nil || duration! < 0.1 {
            freezeStartTime = nil
        }
    }
    
    // Public method for test haptic (bypasses cooldown for testing)
    func triggerTestHaptic() {
        let settings = WatchConnectivityManager.shared.watchSettings
        let device = WKInterfaceDevice.current()
        
        let hapticType: WKHapticType
        switch settings.hapticPattern {
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
    }
    
    // MARK: - Battery Monitoring
    
    private func checkBatteryLevel() -> Bool {
        // Note: watchOS doesn't provide direct battery level API
        // However, we can monitor for low battery through:
        // 1. WKExtendedRuntimeSession expiration warnings
        // 2. System notifications (would need UNUserNotificationCenter setup)
        // 3. Session invalidation reasons
        
        // For now, we'll rely on session expiration warnings
        // The SessionManager will handle session expiration and stop monitoring
        // This method can be enhanced when battery APIs become available
        
        // Return false (battery OK) - actual monitoring happens via session expiration
        return false
    }
}
