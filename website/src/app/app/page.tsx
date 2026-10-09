import type { Metadata } from "next";
import { Button } from "@/components/Button";
import { PhoneShot, WatchShot } from "@/components/DeviceShot";
import { Reveal } from "@/components/Reveal";
import { PageHero } from "@/components/SiteChrome";

export const metadata: Metadata = {
  title: "The app",
  description: "Every screen of GaitGuard on iPhone and Apple Watch: the tick dial, History, Trends, Tune, calibration, onboarding, and the Watch app with Did it help?",
};

const phone = [
  {
    name: "Home",
    body: "The live session. A tick dial shows your steadiness score, with time, steps and cadence while you walk. Below it: cues today, the last cue and your calibration status. Tap the dial to start or stop monitoring on your Watch.",
    shots: [
      { src: "/app/home-live.png", alt: "Home during a walk: steadiness 86, time, steps and cadence" },
      { src: "/app/home-ready.png", alt: "Home before a walk: Ready to walk, with a Start button on the dial" },
    ],
  },
  {
    name: "History",
    body: "A timeline of every cue, grouped by day. Each shows whether it was a start or a turn, how strong it was, how long the freeze lasted, and whether you marked it helpful. Filter by type, add a daily note about medication timing, sleep or how walking felt, and export to CSV.",
    shots: [{ src: "/app/history.png", alt: "History: today's cues with strength and freeze length, and daily notes" }],
  },
  {
    name: "Trends",
    body: "Switch between week, month and three months. See the daily average, how this period compares with the last, the time-of-day pattern, the strength split and your calibration baseline.",
    shots: [{ src: "/app/trends.png", alt: "Trends: daily cues, comparison with the previous period and time-of-day pattern" }],
  },
  {
    name: "Tune",
    body: "Cue tempo from 60 to 130 beats per minute, beats per cue, strength and haptic style. Repeat while frozen, beat while walking, and a detection mode: Everyday, Exercise, High alert or Custom. Send a test cue, calibrate, export or reset.",
    shots: [{ src: "/app/tune.png", alt: "Tune: cue tempo, beats per cue, strength, haptic style and options" }],
  },
  {
    name: "Calibration",
    body: "A 30-second walk that teaches GaitGuard your pace. It checks that you actually walked, learns your cadence and suggests a matching cue tempo.",
    shots: [{ src: "/app/calibration.png", alt: "Calibration: a 30-second dial and three short instructions" }],
  },
  {
    name: "Guided setup",
    body: "Five short steps: feel the beat on your phone, say who it's for and pick your pace, pair your Watch, take the calibration walk, and read the safety notes.",
    shots: [
      { src: "/app/onboarding-1.png", alt: "Onboarding: A steady beat for every step, tap to feel the beat" },
      { src: "/app/onboarding-2.png", alt: "Onboarding: Make it yours, with name and walking pace" },
    ],
  },
];

const watch = [
  { src: "/app/watch-home.png", alt: "Apple Watch home: the tick dial with a Start button", label: "Dial home", body: "Tap to start. A Stop pill appears while you walk, with your live steadiness score." },
  { src: "/app/watch-feedback.png", alt: "Apple Watch after a cue: Did it help? with a tick and a cross", label: "Did it help?", body: "After every cue, a tick or a cross. The app adapts to your answers." },
  { src: "/app/watch-pace.png", alt: "Apple Watch Pace page: cadence and distance", label: "Pace", body: "Your cadence and distance as you walk." },
  { src: "/app/watch-today.png", alt: "Apple Watch Today page: cues today, steps and last cue, with a Calibrate button", label: "Today", body: "Cues, steps and the last cue, plus a Calibrate button." },
  { src: "/app/watch-calibration.png", alt: "Apple Watch calibration: a filling dial with a seconds count", label: "Calibration", body: "A get-ready countdown, then a dial that fills as you walk." },
];

const whatsNew = [
  "Detection that waits for walking first and uses your own baseline",
  "Freeze length measured and shown in History",
  "Smarter calibration: checks you walked, learns your pace and suggests a matching cue tempo",
  "A tick or a cross after each cue, and the app learns from it",
  "Beat while walking: an optional soft metronome on your wrist",
  "A steadiness score based on real stride data",
  "A low-battery warning and automatic stop",
  "Guided setup with live Watch pairing",
  "A new design: floating navigation bar, tick-dial home, serif numerals, a matte dark theme",
  "A new Apple Watch app design",
];

const next = ["A medication log, to see how cues relate to ON and OFF times", "A PDF report to share with your care team", "A Watch complication"];

export default function AppPage() {
  return (
    <>
      <PageHero
        eyebrow="The app"
        title={<>Calm on the wrist. <span className="serif">Clear on the phone.</span></>}
        intro="Four tabs on the iPhone, a Watch app that works on its own, and one dial that tells you at a glance how steady things are."
      />

      <section className="section !pt-8">
        <div className="wrap grid gap-24">
          <p className="-mb-14 text-[0.85rem] text-ash">iPhone</p>
          {phone.map((s, i) => (
            <Reveal key={s.name} className={`grid items-center gap-10 lg:grid-cols-2 lg:gap-20 ${i % 2 ? "lg:[&>*:first-child]:order-2" : ""}`}>
              <div>
                <p className="num text-[1.2rem] text-ember">0{i + 1}</p>
                <h2 className="display mt-3 !text-[clamp(2.2rem,4vw,3.2rem)]">{s.name}</h2>
                <p className="mt-5 max-w-[30em] text-[1.1rem] leading-relaxed text-ash">{s.body}</p>
              </div>
              <div className={`mx-auto grid w-full gap-5 ${s.shots.length > 1 ? "max-w-[600px] grid-cols-2" : "max-w-[300px]"}`}>
                {s.shots.map((sh, k) => (
                  <PhoneShot key={sh.src} src={sh.src} alt={sh.alt} className={k === 1 ? "mt-10" : ""} />
                ))}
              </div>
            </Reveal>
          ))}
        </div>
      </section>

      <section className="section">
        <div className="wrap">
          <Reveal className="max-w-2xl">
            <p className="eyebrow">Apple Watch</p>
            <h2 className="h2 mt-4">Works on its own. <span className="serif">Phone not required while walking.</span></h2>
          </Reveal>
          <ul className="mt-14 grid gap-x-6 gap-y-12 sm:grid-cols-2 lg:grid-cols-5">
            {watch.map((w, i) => (
              <Reveal as="li" key={w.label} delay={i * 60}>
                <WatchShot src={w.src} alt={w.alt} />
                <h3 className="display mt-5 !text-[1.35rem]">{w.label}</h3>
                <p className="mt-2 text-[0.95rem] leading-relaxed text-ash">{w.body}</p>
              </Reveal>
            ))}
          </ul>
          <p className="mt-12 text-[0.82rem] text-ash">Screenshots from a development build, showing demo data.</p>
        </div>
      </section>

      <section className="section">
        <div className="wrap grid gap-12 lg:grid-cols-[1fr_1fr]">
          <Reveal>
            <p className="eyebrow">New in this version</p>
            <h2 className="h2 mt-4">What&apos;s <span className="serif">new.</span></h2>
            <ul className="mt-8 grid gap-4 text-[1.02rem] leading-relaxed text-ink-2">
              {whatsNew.map((n) => (
                <li key={n} className="flex gap-3"><span className="mt-[0.7em] h-1.5 w-1.5 shrink-0 rounded-full bg-ember" />{n}</li>
              ))}
            </ul>
          </Reveal>
          <Reveal delay={100} className="self-start rounded-[22px] border border-bone/10 bg-hearth p-8">
            <p className="label">Coming next</p>
            <p className="mt-3 text-[0.95rem] text-ash">Not available yet. These are planned.</p>
            <ul className="mt-5 grid gap-3 text-[1.02rem] text-ink-2">
              {next.map((n) => (<li key={n}>{n}</li>))}
            </ul>
          </Reveal>
        </div>
        <div className="wrap mt-14 flex flex-wrap gap-3">
          <Button href="/pilot" arrow>Join the pilot</Button>
          <Button href="/how-it-works" variant="ghost">How it works</Button>
        </div>
      </section>
    </>
  );
}
