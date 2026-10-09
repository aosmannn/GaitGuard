// GaitAnalysis.swift
// Pure, sensor-free gait analysis: spectral features, the freeze/turn state machine and the
// calibration analyser. No CoreMotion or UI in here so it can be unit-tested with synthetic signals.
//
// Approach (after published freezing-of-gait work): walking puts its energy in a "locomotion band"
// (0.5–3 Hz); a freeze shows up as trembling in a "freeze band" (3.5–8 Hz) with the stride gone.
// The ratio of the two is the Freezing Index. We only look for freezes right after walking, and
// thresholds are personal (set by calibration, then nudged by the user's thumbs-up/down feedback).
import Foundation

// MARK: - Spectral features

struct SpectralFeatures: Equatable {
    var locoPower: Double        // mean-square amplitude in 0.5–3 Hz (g²)
    var freezePower: Double      // mean-square amplitude in 3.5–8 Hz (g²)
    var rms: Double              // overall RMS of the window (g)
    var dominantFrequency: Double // strongest frequency in the locomotion band (Hz)

    var freezeIndex: Double {
        if locoPower > 1e-9 { return min(50, freezePower / locoPower) }
        return freezePower > 1e-9 ? 50 : 0
    }
    /// Share of band energy that sits in the freeze band, 0…1.
    var freezeShare: Double {
        let t = locoPower + freezePower
        return t > 1e-12 ? freezePower / t : 0
    }
}

enum GaitSpectrum {
    static let locoBins: [Double] = stride(from: 0.5, through: 3.0, by: 0.25).map { $0 }
    static let locoSpacing = 0.25
    static let freezeBins: [Double] = stride(from: 3.5, through: 8.0, by: 0.5).map { $0 }
    static let freezeSpacing = 0.5

    /// Analyse one window of gravity-free acceleration magnitude samples.
    static func analyze(_ samples: [Double], sampleRate: Double) -> SpectralFeatures {
        let n = samples.count
        guard n >= 16, sampleRate > 0 else {
            return SpectralFeatures(locoPower: 0, freezePower: 0, rms: 0, dominantFrequency: 0)
        }
        let mean = samples.reduce(0, +) / Double(n)
        var hann = [Double](repeating: 0, count: n)
        var gain = 0.0
        for i in 0..<n {
            hann[i] = 0.5 - 0.5 * cos(2 * .pi * Double(i) / Double(n - 1))
            gain += hann[i]
        }
        gain /= Double(n)
        var windowed = [Double](repeating: 0, count: n)
        var sumSq = 0.0
        for i in 0..<n {
            let v = samples[i] - mean
            sumSq += v * v
            windowed[i] = v * hann[i]
        }
        func amplitude(at f: Double) -> Double {
            let coeff = 2 * cos(2 * .pi * f / sampleRate)
            var s1 = 0.0, s2 = 0.0
            for x in windowed {
                let s = x + coeff * s1 - s2
                s2 = s1
                s1 = s
            }
            let power = s1 * s1 + s2 * s2 - coeff * s1 * s2
            return 2 * max(0, power).squareRoot() / (Double(n) * gain)
        }
        var loco = 0.0, freeze = 0.0
        var best = 0.0, bestF = 0.0
        for f in locoBins {
            let a = amplitude(at: f)
            loco += a * a / 2 * locoSpacing
            if a > best { best = a; bestF = f }
        }
        for f in freezeBins {
            let a = amplitude(at: f)
            freeze += a * a / 2 * freezeSpacing
        }
        return SpectralFeatures(locoPower: loco, freezePower: freeze,
                                rms: (sumSq / Double(n)).squareRoot(), dominantFrequency: bestF)
    }
}

// MARK: - Freeze / turn detector

struct DetectorTuning: Equatable {
    /// Freezing Index above which a window counts as "freeze-like".
    var freezeIndexThreshold: Double = 2.5
    /// Minimum locomotion-band power to count as walking.
    var walkPower: Double = 0.006
    /// Minimum freeze-band power to count as trembling.
    var tremorPower: Double = 0.0015
    /// How long the freeze-like state must last before we cue.
    var minStall: TimeInterval = 1.5
    /// How long after walking we still consider the person "on a walk".
    var walkMemory: TimeInterval = 8
    var cooldown: TimeInterval = 4
    var maxEpisode: TimeInterval = 90
    var repeatEvery: TimeInterval = 5
    var maxRepeats = 3
    /// Radians of turning inside the window that count as a turn.
    var turnAngle: Double = 1.2
    /// A turn only cues if walking power fell below this fraction of normal (hesitation).
    var turnHesitation: Double = 0.45
    /// High-alert mode: also cue when walking simply stalls, even without trembling.
    var useStallCriterion = false
}

enum DetectorEvent: Equatable {
    case freezeStart(severity: Double, start: Date)
    case freezeRepeat
    case freezeEnd(duration: TimeInterval)
    case turnHesitation(severity: Double)
}

final class FreezeDetector {
    var tuning: DetectorTuning
    private(set) var isFreezing = false
    /// Smoothed normal walking power (used for hesitation and stall checks).
    private(set) var walkPowerEMA: Double = 0

    private var lastWalking: Date?
    private var walkingSince: Date?
    private var resumeWindows = 0
    private var candidateSince: Date?
    private var quietSince: Date?
    private var episodeStart: Date?
    private var lastEnd: Date = .distantPast
    private var lastRepeat: Date = .distantPast
    private var repeats = 0
    private var lastTurn: Date = .distantPast

    init(tuning: DetectorTuning = DetectorTuning()) { self.tuning = tuning }

    func reset() {
        isFreezing = false; walkPowerEMA = 0
        lastWalking = nil; walkingSince = nil; resumeWindows = 0
        candidateSince = nil; quietSince = nil; episodeStart = nil
        lastEnd = .distantPast; lastRepeat = .distantPast; repeats = 0; lastTurn = .distantPast
    }

    /// Feed one analysis window. `yawAngle` is the net turn (radians) inside the window;
    /// `stepsRecently` is true when the pedometer saw steps in the last few seconds.
    func process(_ f: SpectralFeatures, yawAngle: Double, stepsRecently: Bool, now: Date) -> [DetectorEvent] {
        var out: [DetectorEvent] = []
        let walking = f.locoPower >= tuning.walkPower && f.freezeIndex < tuning.freezeIndexThreshold

        if walking {
            if walkingSince == nil { walkingSince = now }
            lastWalking = now
            walkPowerEMA = walkPowerEMA == 0 ? f.locoPower : walkPowerEMA * 0.9 + f.locoPower * 0.1
            resumeWindows += 1
        } else {
            resumeWindows = 0
            if !(f.locoPower >= tuning.walkPower * 0.5) { walkingSince = nil }
        }

        let recentlyWalking = stepsRecently || (lastWalking.map { now.timeIntervalSince($0) <= tuning.walkMemory } ?? false)
        let trembling = f.freezePower >= tuning.tremorPower && f.freezeIndex >= tuning.freezeIndexThreshold
        let sustainedWalk = (walkingSince.map { now.timeIntervalSince($0) >= 6 } ?? false) || walkPowerEMA >= tuning.walkPower * 2
        let stalled = tuning.useStallCriterion && sustainedWalk
            && walkPowerEMA > 0 && f.locoPower < walkPowerEMA * 0.25 && f.rms > 0.004
        let candidate = recentlyWalking && !walking && (trembling || stalled)

        if isFreezing {
            if resumeWindows >= 2 {
                out.append(.freezeEnd(duration: now.timeIntervalSince(episodeStart ?? now)))
                endEpisode(now)
            } else if candidate {
                quietSince = nil
                if let start = episodeStart, now.timeIntervalSince(start) >= tuning.maxEpisode {
                    out.append(.freezeEnd(duration: now.timeIntervalSince(start)))
                    endEpisode(now)
                } else if repeats < tuning.maxRepeats && now.timeIntervalSince(lastRepeat) >= tuning.repeatEvery {
                    lastRepeat = now; repeats += 1
                    out.append(.freezeRepeat)
                }
            } else {
                if quietSince == nil { quietSince = now }
                if now.timeIntervalSince(quietSince!) >= 3 {
                    out.append(.freezeEnd(duration: now.timeIntervalSince(episodeStart ?? now)))
                    endEpisode(now)
                }
            }
            return out
        }

        if candidate {
            if candidateSince == nil { candidateSince = now }
            if let since = candidateSince,
               now.timeIntervalSince(since) >= tuning.minStall,
               now.timeIntervalSince(lastEnd) >= tuning.cooldown {
                isFreezing = true
                episodeStart = since
                lastRepeat = now; repeats = 0; quietSince = nil
                let severity = trembling ? max(0.15, min(1, f.freezeShare)) : 0.35
                out.append(.freezeStart(severity: severity, start: since))
                return out
            }
        } else {
            candidateSince = nil
        }

        // Turn hesitation: a real turn while the stride collapses.
        if abs(yawAngle) >= tuning.turnAngle,
           recentlyWalking,
           walkPowerEMA > 0,
           f.locoPower < walkPowerEMA * tuning.turnHesitation,
           now.timeIntervalSince(lastTurn) >= tuning.cooldown,
           now.timeIntervalSince(lastEnd) >= tuning.cooldown {
            lastTurn = now
            out.append(.turnHesitation(severity: min(1, max(0.2, abs(yawAngle) / 3))))
        }
        return out
    }

    private func endEpisode(_ now: Date) {
        isFreezing = false; episodeStart = nil; candidateSince = nil; quietSince = nil
        lastEnd = now; resumeWindows = 0
    }
}

// MARK: - Calibration

struct GaitProfile: Codable, Equatable {
    var walkPower: Double            // personal "this is walking" level
    var freezeIndexMean: Double
    var freezeIndexStd: Double
    var freezeIndexThreshold: Double // personal freeze threshold
    var cadence: Double              // steps per minute during calibration
    var steps: Int
    var quality: Double              // 0…1
    var timestamp: Date

    var qualityLabel: String {
        quality >= 0.7 ? "Good" : quality >= 0.45 ? "Fair" : "Low"
    }
}

enum CalibrationFailure: Error, Equatable {
    case notWalking
    case tooFewSteps(Int)
    case tooUnsteady

    var message: String {
        switch self {
        case .notWalking: return "We didn't pick up a steady walk. Try again and keep your arm swinging naturally."
        case .tooFewSteps(let n): return "We only counted \(n) steps. Walk a little longer and keep a steady pace."
        case .tooUnsteady: return "The walk was too uneven to learn from. Try a straight, clear path."
        }
    }
}

enum CalibrationAnalyzer {
    static let minimumSteps = 20

    /// `samples` are gravity-free acceleration magnitudes recorded while walking.
    static func analyze(samples: [Double], sampleRate: Double, steps: Int, walkingSeconds: Double, now: Date = Date())
        -> Result<GaitProfile, CalibrationFailure> {
        let win = Int(sampleRate * 3), hop = Int(sampleRate * 1.5)
        guard samples.count >= win else { return .failure(.notWalking) }
        var feats: [SpectralFeatures] = []
        var i = 0
        while i + win <= samples.count {
            feats.append(GaitSpectrum.analyze(Array(samples[i..<i + win]), sampleRate: sampleRate))
            i += hop
        }
        let walkingWindows = feats.filter { $0.locoPower >= 0.0015 }
        guard Double(walkingWindows.count) / Double(max(1, feats.count)) >= 0.6 else { return .failure(.notWalking) }
        guard steps >= minimumSteps else { return .failure(.tooFewSteps(steps)) }

        let fis = walkingWindows.map(\.freezeIndex)
        let mu = fis.reduce(0, +) / Double(fis.count)
        let sd = (fis.map { pow($0 - mu, 2) }.reduce(0, +) / Double(fis.count)).squareRoot()
        let threshold = min(5, max(1.5, mu + 3 * max(sd, 0.15 * mu)))

        let powers = walkingWindows.map(\.locoPower).sorted()
        let median = powers[powers.count / 2]
        let walkPower = min(0.03, max(0.002, median * 0.35))

        let freqs = walkingWindows.map(\.dominantFrequency).filter { $0 > 0 }
        let fMean = freqs.isEmpty ? 0 : freqs.reduce(0, +) / Double(freqs.count)
        let fSd = freqs.isEmpty ? 1 : (freqs.map { pow($0 - fMean, 2) }.reduce(0, +) / Double(freqs.count)).squareRoot()
        let cv = fMean > 0 ? fSd / fMean : 1
        let regularity = 1 - min(1, cv / 0.35)
        let stepScore = min(1, Double(steps) / 45)
        let shareScore = Double(walkingWindows.count) / Double(feats.count)
        let quality = (regularity + stepScore + shareScore) / 3
        guard quality >= 0.3 else { return .failure(.tooUnsteady) }

        let cadence = walkingSeconds > 0 ? Double(steps) / walkingSeconds * 60 : 0
        return .success(GaitProfile(walkPower: walkPower, freezeIndexMean: mu, freezeIndexStd: sd,
                                    freezeIndexThreshold: threshold, cadence: cadence, steps: steps,
                                    quality: quality, timestamp: now))
    }
}

// MARK: - Turn tracking

/// Integrates yaw rate (rad/s, about gravity) over a short rolling window.
struct TurnTracker {
    private var samples: [(t: TimeInterval, rate: Double)] = []
    let span: TimeInterval

    init(span: TimeInterval = 2.5) { self.span = span }

    mutating func push(rate: Double, at t: TimeInterval) {
        samples.append((t, rate))
        while let first = samples.first, t - first.t > span { samples.removeFirst() }
    }
    /// Net signed angle in the window (radians).
    var angle: Double {
        guard samples.count > 1 else { return 0 }
        var total = 0.0
        for i in 1..<samples.count { total += samples[i].rate * (samples[i].t - samples[i - 1].t) }
        return total
    }
    mutating func reset() { samples.removeAll() }
}

// MARK: - Steadiness score

/// A score built from real signals: how regular the stride is, and how much of the last
/// ten minutes was spent in freezes. (Replaces the old "100 − 10 × cues" estimate.)
enum Steadiness {
    static func score(strideRegularity: Double?, freezeSecondsLast10Min: Double, cuesLast10Min: Int) -> Int {
        let r = strideRegularity ?? 0.8
        let freezeFraction = min(1, freezeSecondsLast10Min / 60)
        let raw = 100 * (0.5 * r + 0.5 * (1 - freezeFraction)) - Double(min(cuesLast10Min, 5)) * 4
        return max(0, min(100, Int(raw.rounded())))
    }
}
