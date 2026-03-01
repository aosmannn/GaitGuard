# GaitGuardAI 🛡️

**GaitGuardAI** is an iOS + watchOS app that monitors gait on an Apple Watch and provides rhythmic haptic cueing to help during walking initiation and turning—where freezing of gait (FoG) often occurs. It streams live data to an iPhone companion app for analytics and remote control.

This is a cueing aid and prototype. It is not a medical device. Use with supervision before relying on it for safety-critical situations.

---

## What GaitGuard Does

### On the Apple Watch
- **Freeze detection**: Detects when you attempt to start walking or turn but don’t produce steps
- **Rhythmic haptic cueing**: Metronome-style pulses to help break freezes (different rhythms for start vs turn)
- **Step tracking**: Live step count, cadence, and distance via CMPedometer
- **Calibration**: 30-second walk to personalize detection thresholds
- **Background monitoring**: Uses HealthKit workout sessions so tracking continues when the screen is off

### On the iPhone
- **Dashboard**: Connection status, live steps/cadence/distance, event timeline
- **Analytics**: Charts by event type, hour, and severity
- **Remote controls**: Adjust sensitivity, haptic pattern, and intensity from the phone
- **Calibration results**: View baseline threshold and stats after calibration

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

### HealthKit (for background monitoring)
- Enable the HealthKit capability for the Watch app in the Apple Developer portal
- The app uses `HKWorkoutSession` to keep monitoring when the screen is off

---

## Project Structure

```
GaitGuardAI/
├── GaitGuardAI Watch App/
│   ├── ContentView.swift          # Watch UI
│   ├── MotionDetector.swift       # Motion processing, freeze detection, cueing, step counting
│   ├── GaitTrackingManager.swift  # HKWorkoutSession for background
│   └── GaitGuardAIApp.swift
├── GaitGuardAI-iPhone/
│   ├── ContentView.swift          # iPhone dashboard
│   ├── AnalyticsView.swift        # Charts and insights
│   ├── RemoteControlsView.swift   # Settings
│   └── GaitGuardAIiPhoneApp.swift
└── Shared/
    └── WatchConnectivityManager.swift  # Watch ↔ iPhone sync
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
