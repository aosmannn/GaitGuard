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
