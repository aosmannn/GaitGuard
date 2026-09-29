# GaitGuardAI 🛡️

**GaitGuardAI** is an iOS + watchOS app that monitors gait on an Apple Watch and provides rhythmic haptic cueing to help during walking initiation and turning—where freezing of gait (FoG) often occurs. It streams live data to an iPhone companion app for analytics and remote control.

This is a cueing aid and prototype. It is not a medical device. Use with supervision before relying on it for safety-critical situations.

---

## What GaitGuard Does

### On the Apple Watch
- **Freeze detection**: Detects when you attempt to start walking or turn but don’t produce steps
- **Rhythmic haptic cueing**: Metronome-style pulses to help break freezes (different rhythms for start vs turn), with a brief on-screen assist banner
- **Step tracking**: Live step count, cadence, and distance via CMPedometer
- **Calibration**: 30-second walk to personalize detection thresholds
- **Background monitoring**: Uses HealthKit workout sessions so tracking continues when the screen is off
- **Pager pages**: SCORE / METRICS / TODAY with page dots

### On the iPhone
- **Home dashboard**: Connection status, Ready vs live gait score, today’s assists, remote **Start/Stop** when the Watch is reachable
- **History**: Assist timeline with severity labels; daily notes; clear requires confirmation
- **Trends**: Charts by assist type, hour, and severity (raw XYZ motion under Advanced)
- **Settings** (formerly Profile): Haptics, detection presets, calibration guide, test vibration, factory reset
- **Calibration results**: Persisted on the phone and shown after calibration
- **Synced gait score**: Watch is the source of truth; phone displays the score the Watch sends

---

## Who It’s For

People who:
- Have a foot that “sticks” when starting to walk
- Struggle to turn without assistance
- May speed up or lean forward (festination)

---

## How Detection Works

The app uses Core Motion on the watch:

- **Sensors**: `CMDeviceMotion`, `userAcceleration`, `rotationRate` (yaw for turning)
- **Sampling**: ~50 Hz
- **Logic**: Detects movement attempts without step cadence → triggers haptic cue
- **Calibration**: Personalizes the baseline threshold from a 30-second walk

---

## Setup & Running

### Prerequisites
- Xcode 15+
- watchOS 10+ / iOS 17+
- Physical Apple Watch paired with iPhone (WatchConnectivity needs real devices)

### Build & Run
1. Open `GaitGuardAI/GaitGuardAI.xcodeproj` in Xcode
2. Run **GaitGuardAI-iPhone** on your iPhone (this installs the Watch app too)
3. Run **GaitGuard Watch App** on your paired Apple Watch
4. Launch both apps and wait for WatchConnectivity to connect
5. Start monitoring from the Watch **or** from iPhone Home/Settings when the Watch is reachable

### HealthKit (for background monitoring)
- Enable the HealthKit capability for the Watch app in the Apple Developer portal
- The app uses `HKWorkoutSession` to keep monitoring when the screen is off

---

## Project Structure

```
GaitGuardAI/
├── GaitGuardAI Watch App/
│   ├── ContentView.swift          # Watch UI (SCORE / METRICS / TODAY)
│   ├── MotionDetector.swift       # Motion processing, freeze detection, cueing, step counting
│   ├── GaitTrackingManager.swift  # HKWorkoutSession for background
│   └── GaitGuardAIApp.swift
├── GaitGuardAI-iPhone/
│   ├── ContentView.swift          # Home + History
│   ├── AnalyticsView.swift        # Trends
│   ├── RemoteControlsView.swift   # Settings
│   └── GaitGuardAIiPhoneApp.swift
└── Shared/
    └── WatchConnectivityManager.swift  # Watch ↔ iPhone sync (score, assists, remote start/stop)
```

---

## Safety Notes

- Turning difficulty can be high fall-risk. Use as a cueing aid, not a replacement for supervision.
- Consider involving a clinician or PT. Rhythmic cueing works best with taught strategies (staged turns, weight shift).
- The app does not detect falls or call emergency contacts.
- **Not a medical device**—use with supervision and professional guidance.

---

## License

MIT License. See LICENSE for details.
