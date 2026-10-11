<p align="center">
  <img src="branding/gaitguard-logo-1024.png" width="120" alt="GaitGuard logo" />
</p>

<h1 align="center">GaitGuard</h1>

<p align="center">
  Rhythmic haptic cueing on Apple Watch for people with Parkinson's who experience freezing of gait.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-26.2+-12100E?logo=apple&logoColor=white" alt="iOS 26.2+" />
  <img src="https://img.shields.io/badge/watchOS-11.6+-12100E?logo=apple&logoColor=white" alt="watchOS 11.6+" />
  <img src="https://img.shields.io/badge/SwiftUI-FF7A4D?logo=swift&logoColor=white" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/version-1.3-E8C9A0" alt="Version 1.3" />
</p>

---

When walking stalls, the Watch taps a steady rhythm on the wrist to help you keep moving. It learns your walk from a short calibration, asks whether each cue helped, and adjusts from your answers. The iPhone app shows your history and trends.

> **GaitGuard is a cueing aid, not a medical device.** It does not diagnose, treat, or prevent any condition, and it does not detect falls or contact anyone. It can miss a freeze or cue when one wasn't needed. Detection has not been tested with real patients yet. Keep Apple Watch Fall Detection and Emergency SOS on if you rely on them, and talk with your care team about how to use it.

## Features

**Apple Watch** (runs on its own; the phone doesn't need to be nearby while you walk)
- **Tick dial home**: a ring of 60 ticks. The score fills the ring and an ember tick sweeps at your cue tempo. Tap the dial to start or stop.
- **Rhythm cues**: tempo from 60 to 130 bpm, with adjustable beats per cue, haptic style, and strength
- **"Did it help?"**: a tick or cross after every cue, which makes detection a little more or less sensitive
- **Beat while walking** (optional): a soft metronome tap while you walk
- **Pace and Today pages**: cadence, distance, cues, steps, and the last cue
- **Background monitoring** through a HealthKit workout session, with a warning at 20% battery and an automatic stop at 10%

**iPhone**
- **Home**: the live session with the Steadiness score, time, steps, and cadence, plus cues today with an hourly chart
- **History**: every cue grouped by day, showing start or turn, strength, freeze length, and whether it helped. Includes daily notes, filters, and CSV export.
- **Trends**: week, month, or 3-month view with comparison to the previous period, time-of-day pattern, and strength split
- **Tune**: cue settings, detection mode (Everyday, Exercise, High alert, Custom), test cue, calibration, export, and reset
- **Onboarding**: feel the beat on the phone, pick a pace, pair the Watch live, do the calibration walk, and accept the safety notice

You can start or stop from either device and the two stay in sync. Settings changed on the phone apply to the Watch. There's no account, and data stays on your devices.

## How detection works

1. The Watch reads the motion sensor at **50 Hz** with gravity removed.
2. Every 0.5 s it looks at the last 3 s of motion and separates the **walking rhythm** from **fast trembling**.
3. It only flags a possible freeze if you **were just walking**, the rhythm has **stopped**, and trembling-like motion lasts **~1.5 s**. Gesturing, eating, or sitting still shouldn't trigger it.
4. **Turns** trigger a cue only for a turn of about 70° where your stride also slows down. Smooth turns while walking are ignored.
5. A cue plays a short run of taps at your tempo (default **100 bpm × 4 beats**). It can repeat while the freeze continues, and the freeze length is saved to History.
6. **Calibration** is a 30-second walk. It checks that you actually walked, records your pace, sets your thresholds, and suggests a matching tempo.
7. The **Steadiness score** comes from how regular your stride is and how much of the last 10 minutes you spent frozen.

**High alert** mode is more sensitive and also cues when walking simply stalls. **Exercise** mode is calmer.

## Availability

**Coming soon to TestFlight.** Before release, I'm doing thorough research to make sure GaitGuard is safe and actually helps. Beta testing on TestFlight opens once that's finished. It will need an iPhone on iOS 26.2 or later, paired with an Apple Watch on watchOS 11.6 or later.

## Project structure

```
GaitGuardAI/
├── GaitGuardAI Watch App/
│   ├── ContentView.swift            # Dial, Pace, Today, calibration, "Did it help?"
│   ├── MotionDetector.swift         # Sensor loop, cueing, steps, battery guard
│   ├── GaitAnalysis.swift           # Pure detection logic (rhythm vs. trembling, turns, profile)
│   ├── GaitTrackingManager.swift    # HKWorkoutSession for background monitoring
│   └── GaitGuardAIApp.swift
├── GaitGuardAI-iPhone/
│   ├── ContentView.swift            # Tab shell
│   ├── SummaryView.swift            # Home
│   ├── HistoryView.swift
│   ├── TrendsView.swift
│   ├── SettingsView.swift           # Tune
│   ├── CalibrationView.swift
│   ├── OnboardingView.swift
│   ├── Components.swift             # Floating tab bar and shared controls
│   └── GaitGuardAIiPhoneApp.swift
├── Shared/
│   ├── WatchConnectivityManager.swift   # iPhone ↔ Watch sync, models, Steadiness score
│   └── DesignSystem.swift               # Theme, tick dial
└── Tests/
    ├── main.swift                   # Detection tests
    └── run.sh
branding/                            # Logo, palette, website brief
```

## Roadmap

- Medication log with ON/OFF correlation
- Care-team PDF report
- Watch complication

## License

MIT
