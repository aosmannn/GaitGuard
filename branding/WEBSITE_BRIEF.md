# GaitGuard website brief (for the website agent)

## What it is
GaitGuard is an iPhone + Apple Watch app for people with Parkinson's who experience freezing of gait.
When steps start to freeze, the Watch taps a steady rhythm on the wrist (rhythmic cueing) to help them keep moving.
Built by a founder for his mom. Say that plainly; it is the real story.

Name: **GaitGuard** (never "GaitGuard AI". There is no AI in the app.)

## Safety wording (must appear, not hidden in a footer only)
- GaitGuard is a cueing aid, not a medical device. It does not diagnose, treat, or prevent any condition.
- It does not detect falls or contact anyone. Keep Apple Watch Fall Detection and Emergency SOS turned on if you rely on them.
- It can miss a freeze or cue when it wasn't needed. Talk with your care team about how to use it.
- Do NOT claim clinical results, accuracy numbers, "detects freezes", or "prevents falls". Detection has not been validated on real patients yet.
  Safe phrasing: "responds when your walking stalls", "helps you keep a rhythm", "learns your walk".

## What to show (all of this is real and shipped in the app)
1. **The tick dial**: a ring of 60 ticks, like a metronome. The score fills the ticks; one ember tick sweeps at your cue tempo. It is the brand's signature visual.
2. **Rhythm cues on the wrist**: configurable tempo (60-130 bpm), beats per cue, haptic style, strength.
3. **Learns your walk**: a 30-second calibration walk measures your pace and sets a personal threshold, and can match the cue tempo to your walking pace.
4. **Thumbs up / thumbs down on the Watch** after each cue ("Did it help?"). The app adapts to that feedback.
5. **Beat while walking** (optional): a soft metronome tap while you walk.
6. **Steadiness score** from stride regularity and time spent frozen.
7. **History and Trends**: a timeline of every cue with strength and freeze length, daily notes, time-of-day patterns, week/month/3-month trends, CSV export.
8. **Interactive onboarding**: feel the beat on your phone, pick a pace, pair the Watch, calibrate.
9. **Apple Watch app**: tick-dial home, Start/Stop, pace, today, calibration.
10. Private by default: data stays on the phone and Watch. (Confirm before claiming anything about servers or analytics.)

Coming next (do not present as shipped): medication log with ON/OFF correlation, care-team PDF report, Watch complication.

## Screenshots
No store-quality screenshots exist yet. Capture them from the simulator or a real device before launch:
iPhone: Home (live session), Home (ready), History, Trends, Tune, Calibration, Onboarding.
Watch: dial home, "Did it help?" prompt, Pace, Today, Calibration.
Use dark device frames. Never show real health data.
(The debug launch arguments `-seedDemoData -demoMonitoring` fill the iPhone app with realistic demo data.)

## Look and feel
Matte, warm, calm, editorial. Dark charcoal, never pure black or neon. One hot accent (ember) used sparingly. No stock "medical blue", no gradients-on-everything, no glassy 3D.
- Palette: char `#12100E`, card `#1C1917`, bone `#F4EEE6`, ash `#A39A90`, soot `#6B635B`, ember `#FF7A4D`, brass `#E8C9A0`, sage `#A6CC9A`, dusk `#9DB4D6`
- Type: Fraunces (headlines, big numerals, italics for units) + DM Sans (labels, body). Small labels are tracked-out uppercase.
- Logo: `gaitguard-logo.svg` / `gaitguard-mark.svg` / `gaitguard-logo-1024.png` in this folder (dial with an ember G).
- Voice: warm, plain, respectful. Written for people with Parkinson's and their families, not for engineers. Large readable text, high contrast, generous spacing.

## Page ideas
Hero (dial + one sentence + App Store button when live) → how it works in three steps (calibrate, walk, feel the beat) → features → "Built for my mom" story → safety/what it is not → FAQ → footer with disclaimer.
Accessibility matters here: large type, strong contrast, reduced-motion friendly (the dial animation must be optional).

---

# How the app works (structure, detection, new features)

## App structure
**iPhone app, four tabs plus onboarding**
- **Home**: the live session. A tick dial with the Steadiness score, plus time, steps and cadence while walking. Below it: cues today (with an hourly mini chart and "fewer/more than yesterday"), last cue, and calibration status. Tap the dial to start or stop monitoring on the Watch.
- **History**: a timeline of every cue, grouped by day. Each shows start vs turn, strength (mild / moderate / strong), how long the freeze lasted, and whether the wearer marked it helpful. Filter by type, add a daily note (medication timing, sleep, how walking felt), export CSV.
- **Trends**: week, month or 3 months. Daily average, comparison with the previous period, time-of-day pattern, strength split, and the calibration baseline.
- **Tune**: cue tempo (60-130 bpm), beats per cue, strength, haptic style, repeat while frozen, beat while walking, detection mode (Everyday, Exercise, High alert, Custom), send a test cue, calibration, export, reset.
- **Onboarding (5 steps)**: feel the beat on the phone, name and walking pace, live Watch pairing, calibration walk, safety acknowledgement.

**Apple Watch app (works on its own, phone not required while walking)**
- Dial home: tap to start, Stop pill while running, live Steadiness score.
- After every cue: "Did it help?" with a tick and a cross.
- Pace page (cadence, distance) and Today page (cues, steps, last cue, calibrate).
- Calibration screen with a get-ready countdown and a filling dial.

**How they work together**: start and stop from either device and they stay in sync. Settings changed on the phone apply to the Watch. If the phone is away, the Watch keeps detecting and cueing, then syncs history later. No account needed; data stays on the devices (confirm before making any cloud or privacy claims).

## How gait detection works (plain language)
1. The Watch's motion sensor is read 50 times a second, with gravity removed.
2. Every half second it studies the last 3 seconds and splits the movement into two kinds: the steady rhythm of walking, and fast trembling.
3. It only treats something as a possible freeze if you were walking a moment ago, the walking rhythm has stopped, and trembling-like movement shows up for about 1.5 seconds. That means gesturing, eating or sitting still shouldn't trigger it.
4. Turns: it only cues when you turn about 70 degrees and your stride slows down while you do. A smooth turn while still walking is ignored.
5. When it triggers, the Watch plays a short run of haptic taps at your tempo (default 100 bpm, 4 beats). If "repeat while frozen" is on, it repeats a few times while the freeze continues.
6. It then measures how long the freeze lasted and updates the History entry.
7. High alert mode is more sensitive and also cues when walking simply stalls. Exercise mode is calmer.
8. It is personal. The 30-second calibration walk records your pace and sets your own thresholds. After each cue the wearer can tap tick or cross, and the app becomes slightly more or less sensitive.
9. Steadiness score: built from how regular the stride is and how much of the last 10 minutes was spent frozen (not a count of cues).
10. Battery: warns at 20%, stops monitoring and alerts at 10%.

Honest status: the logic is covered by automated tests on simulated signals, but it has not been validated on real patients. Real-world accuracy is unproven. Website copy must reflect that.

## New in this version (what to announce)
- Rebuilt detection that waits for walking first and uses your own baseline
- Freeze duration measured and shown in History
- Smarter calibration: checks you actually walked, learns your pace, suggests a matching cue tempo
- Thumbs up / thumbs down after each cue, and the app learns from it
- Beat while walking (optional metronome on the wrist)
- Steadiness score based on real stride data
- Low-battery warning and automatic stop
- Interactive onboarding with live Watch pairing
- Brand new design: custom floating navigation bar, tick-dial home, serif numerals, matte dark theme
- New Watch app design
