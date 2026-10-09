// Run with: Tests/run.sh   (compiles GaitAnalysis.swift with these tests; no Xcode target needed)
import Foundation

let fs = 50.0
var failures = 0
var checks = 0
func check(_ cond: Bool, _ name: String, _ detail: String = "") {
    checks += 1
    if cond { print("  PASS  \(name)") } else { failures += 1; print("  FAIL  \(name) \(detail)") }
}

struct RNG { var s: UInt64 = 7; mutating func next() -> Double { s = s &* 6364136223846793005 &+ 1442695040888963407; return Double(s >> 33) / Double(1 << 31) - 0.5 } }
var rng = RNG()

enum Seg { case walk(Double), freeze(Double), still(Double), turnWalk(Double) }

/// Build a magnitude signal plus a yaw-rate signal from segments.
func synth(_ segs: [Seg]) -> (mag: [Double], yaw: [Double]) {
    var mag: [Double] = [], yaw: [Double] = []
    var t = 0.0
    for seg in segs {
        let dur: Double
        switch seg { case .walk(let d), .freeze(let d), .still(let d), .turnWalk(let d): dur = d }
        for _ in 0..<Int(dur * fs) {
            var m = 0.004 * rng.next()
            var y = 0.0
            switch seg {
            case .walk: m += 0.16 * sin(2 * .pi * 1.0 * t) + 0.26 * sin(2 * .pi * 1.9 * t) + 0.03 * sin(2 * .pi * 5 * t)
            case .freeze: m += 0.11 * sin(2 * .pi * 5.0 * t) + 0.02 * sin(2 * .pi * 1.0 * t)
            case .still: break
            case .turnWalk: m += 0.03 * sin(2 * .pi * 1.0 * t); y = 2.4   // ~2.4 rad/s pivot, stride collapsed
            }
            mag.append(m); yaw.append(y); t += 1 / fs
        }
    }
    return (mag, yaw)
}

/// Stream the signal through analysis + detector exactly like the Watch does (3 s window, 0.5 s hop).
func run(_ segs: [Seg], tuning: DetectorTuning = DetectorTuning()) -> [(t: Double, e: DetectorEvent)] {
    let (mag, yaw) = synth(segs)
    let det = FreezeDetector(tuning: tuning)
    var tracker = TurnTracker()
    var out: [(Double, DetectorEvent)] = []
    let base = Date(timeIntervalSinceReferenceDate: 0)
    let win = Int(3 * fs), hop = Int(0.5 * fs)
    var i = win
    while i <= mag.count {
        let t = Double(i) / fs
        for k in (i - hop)..<i { tracker.push(rate: yaw[k], at: Double(k) / fs) }
        let f = GaitSpectrum.analyze(Array(mag[(i - win)..<i]), sampleRate: fs)
        let evs = det.process(f, yawAngle: tracker.angle, stepsRecently: false, now: base.addingTimeInterval(t))
        for e in evs { out.append((t, e)); if case .turnHesitation = e { tracker.reset() } }
        i += hop
    }
    return out
}
func starts(_ r: [(t: Double, e: DetectorEvent)]) -> [(t: Double, sev: Double)] {
    r.compactMap { if case .freezeStart(let s, _) = $0.e { return ($0.t, s) } else { return nil } }
}
func ends(_ r: [(t: Double, e: DetectorEvent)]) -> [Double] {
    r.compactMap { if case .freezeEnd(let d) = $0.e { return d } else { return nil } }
}
func turns(_ r: [(t: Double, e: DetectorEvent)]) -> Int { r.filter { if case .turnHesitation = $0.e { return true } else { return false } }.count }

print("Spectral features")
let walkF = GaitSpectrum.analyze(Array(synth([.walk(3)]).mag.prefix(150)), sampleRate: fs)
let frzF = GaitSpectrum.analyze(Array(synth([.freeze(3)]).mag.prefix(150)), sampleRate: fs)
let stillF = GaitSpectrum.analyze(Array(synth([.still(3)]).mag.prefix(150)), sampleRate: fs)
check(walkF.locoPower > 0.006, "walking has locomotion power", "\(walkF.locoPower)")
check(walkF.freezeIndex < 1.0, "walking has a low freezing index", "\(walkF.freezeIndex)")
check(walkF.dominantFrequency >= 1.75 && walkF.dominantFrequency <= 2.0, "stride frequency near 1.9 Hz", "\(walkF.dominantFrequency)")
check(frzF.freezeIndex > 2.5, "trembling has a high freezing index", "\(frzF.freezeIndex)")
check(frzF.freezePower > 0.0015, "trembling has freeze-band power", "\(frzF.freezePower)")
check(stillF.locoPower < 0.001 && stillF.freezePower < 0.001, "standing still is quiet")

print("Freeze episodes")
let r1 = run([.walk(20), .freeze(8), .walk(10)])
check(starts(r1).count == 1, "one freeze detected in walk→freeze→walk", "\(starts(r1))")
if let s = starts(r1).first { check(s.t >= 21.5 && s.t <= 25.5, "cue lands within ~4 s of freeze onset", "t=\(s.t)") }
check(ends(r1).count == 1, "the freeze ends when walking resumes")
if let d = ends(r1).first { check(d >= 5 && d <= 12, "measured duration is plausible (true 8 s)", "d=\(d)") }

let r2 = run([.walk(20), .still(10), .walk(10)])
check(starts(r2).isEmpty, "a normal stop does NOT cue (default mode)", "\(starts(r2))")

var high = DetectorTuning(); high.useStallCriterion = true
let r3 = run([.walk(20), .still(10), .walk(10)], tuning: high)
check(starts(r3).count <= 1, "high-alert mode cues at most once on a stop")

let r4 = run([.still(30)])
check(r4.isEmpty, "no events while sitting still")

let r5 = run([.freeze(20)])
check(starts(r5).isEmpty, "trembling with no walking before it does NOT cue (arm gesture / tremor at rest)", "\(starts(r5))")

let r6 = run([.walk(15), .freeze(40), .walk(8)])
let rep = r6.filter { if case .freezeRepeat = $0.e { return true } else { return false } }.count
check(starts(r6).count == 1 && rep >= 1 && rep <= 3, "long freeze: one start, a few repeat cues", "repeats=\(rep)")

let r7 = run([.walk(15), .freeze(4), .walk(10), .freeze(4), .walk(10)])
check(starts(r7).count == 2, "two separate freezes are two episodes", "\(starts(r7))")

print("Turns")
let t1 = run([.walk(15), .turnWalk(3), .walk(10)])
check(turns(t1) == 1, "a turn with a collapsed stride cues once", "\(turns(t1))")
let t2 = run([.walk(30)])
check(turns(t2) == 0, "ordinary walking does not cue a turn")
var t3sig = synth([.walk(20)])
for k in 700..<850 { t3sig.yaw[k] = 2.4 }   // pivot while the stride continues normally
do {
    let det = FreezeDetector(); var tr = TurnTracker(); var n = 0
    let win = 150, hop = 25; var i = win
    while i <= t3sig.mag.count {
        for k in (i - hop)..<i { tr.push(rate: t3sig.yaw[k], at: Double(k) / fs) }
        let f = GaitSpectrum.analyze(Array(t3sig.mag[(i - win)..<i]), sampleRate: fs)
        for e in det.process(f, yawAngle: tr.angle, stepsRecently: false, now: Date(timeIntervalSinceReferenceDate: Double(i) / fs)) {
            if case .turnHesitation = e { n += 1 }
        }
        i += hop
    }
    check(n == 0, "a smooth turn while still walking does NOT cue", "\(n)")
}

print("Calibration")
let good = synth([.walk(30)]).mag
if case .success(let p) = CalibrationAnalyzer.analyze(samples: good, sampleRate: fs, steps: 52, walkingSeconds: 30) {
    check(p.cadence > 95 && p.cadence < 110, "cadence from steps/time", "\(p.cadence)")
    check(p.freezeIndexThreshold >= 1.5 && p.freezeIndexThreshold <= 5, "personal threshold is in range", "\(p.freezeIndexThreshold)")
    check(p.walkPower >= 0.002, "personal walking level is set", "\(p.walkPower)")
    check(p.quality > 0.6, "a clean walk scores well", "\(p.quality)")
} else { check(false, "clean walk calibrates") }
if case .failure(.tooFewSteps) = CalibrationAnalyzer.analyze(samples: good, sampleRate: fs, steps: 8, walkingSeconds: 30) {
    check(true, "too few steps is rejected")
} else { check(false, "too few steps is rejected") }
if case .failure(.notWalking) = CalibrationAnalyzer.analyze(samples: synth([.still(30)]).mag, sampleRate: fs, steps: 40, walkingSeconds: 30) {
    check(true, "standing still is rejected")
} else { check(false, "standing still is rejected") }

print("Steadiness")
check(Steadiness.score(strideRegularity: 0.95, freezeSecondsLast10Min: 0, cuesLast10Min: 0) >= 90, "calm, regular walking scores high")
check(Steadiness.score(strideRegularity: 0.5, freezeSecondsLast10Min: 45, cuesLast10Min: 5) < 50, "many freezes score low")

print("\n\(checks - failures)/\(checks) checks passed")
exit(failures == 0 ? 0 : 1)
