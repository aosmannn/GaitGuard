import { HeroDemo } from "@/components/HeroDemo";
import { Reveal } from "@/components/Reveal";
import { RhythmTrainer } from "@/components/RhythmTrainer";
import { SyncPlayground } from "@/components/SyncPlayground";

const REPO = "https://github.com/pogami/GaitGuardAI";

const icons = {
  pulse: "M3 12h4l3-8 4 16 3-8h4",
  wave: "M2 12c2-4 4-4 6 0s4 4 6 0 4-4 6 0M22 12h0",
  chart: "M4 20V10m6 10V4m6 16v-7m6 7H2",
  sync: "M4 12a8 8 0 0 1 14-5.3M20 4v4h-4M20 12a8 8 0 0 1-14 5.3M4 20v-4h4",
  target: "M12 3v3m0 12v3m9-9h-3M6 12H3m15.4-6.4-2.1 2.1M7.7 16.3l-2.1 2.1m0-12.8 2.1 2.1m8.6 8.6 2.1 2.1M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6z",
  moon: "M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z",
  sliders: "M4 6h10m4 0h2M4 12h4m4 0h8M4 18h12m4 0h0M14 4v4M8 10v4M16 16v4",
  lock: "M6 11h12v10H6zM8 11V7a4 4 0 0 1 8 0v4",
  note: "M5 4h14v16H5zM9 9h6M9 13h6M9 17h3",
} as const;

function Icon({ d, className = "h-5 w-5" }: { d: string; className?: string }) {
  return (
    <svg viewBox="0 0 24 24" className={className} fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d={d} />
    </svg>
  );
}

const steps = [
  {
    n: "01",
    title: "Senses the stall",
    body: "Apple Watch reads your motion many times a second and recognizes when a start or a turn stops turning into steps.",
    icon: icons.pulse,
  },
  {
    n: "02",
    title: "Taps out a rhythm",
    body: "A metronome-like haptic pulses on your wrist, with a distinct pattern for starting and for turning, to help the next step come.",
    icon: icons.wave,
  },
  {
    n: "03",
    title: "Shows the pattern",
    body: "Your iPhone mirrors the session live and keeps a timeline of every cue, so you and your care team can see what's changing.",
    icon: icons.chart,
  },
];

const features = [
  { title: "Tuned to your walk", body: "A 30-second calibration walk sets thresholds to your own baseline, not an average.", icon: icons.target },
  { title: "Start and turn cues", body: "Different haptic patterns for getting going and for turning, with adjustable strength.", icon: icons.wave },
  { title: "Always in sync", body: "Start, stop, score and cue history match on Watch and iPhone, within a moment.", icon: icons.sync },
  { title: "Keeps working in the background", body: "Monitoring continues when the Watch screen sleeps, like a workout does.", icon: icons.moon },
  { title: "Control from your phone", body: "A care partner can start, stop or adjust sensitivity without touching the Watch.", icon: icons.sliders },
  { title: "Private by design", body: "No account and no cloud. Your history stays on your own devices.", icon: icons.lock },
];

const people = [
  {
    who: "People living with Parkinson's",
    body: "A discreet tap on the wrist when your feet feel glued to the floor, at a doorway, a turn, or the first step.",
  },
  {
    who: "Care partners",
    body: "See how a walk is going from your iPhone, and start or stop cueing without reaching for their wrist.",
  },
  {
    who: "Clinicians & physical therapists",
    body: "Use it alongside the cueing strategies you teach, and review when and where freezes happen.",
  },
];

const faqs = [
  [
    "Is GaitGuard a medical device?",
    "No. GaitGuard is a cueing aid and a prototype. It does not diagnose, treat, or prevent any condition. It doesn't detect falls or contact emergency services.",
  ],
  [
    "What do I need?",
    "An iPhone running iOS 17 or later and a paired Apple Watch running watchOS 10 or later. Detection and haptics run on the Watch; the iPhone is the companion.",
  ],
  [
    "Does it work away from my iPhone?",
    "Yes. The Watch detects and cues on its own. When the two reconnect, history and settings catch up automatically.",
  ],
  [
    "Where is my data stored?",
    "On your Watch and iPhone. GaitGuard has no account and doesn't send your walking data to a server.",
  ],
  [
    "When can I get it?",
    "An App Store release is on the way. The project is open source on GitHub today.",
  ],
];

export default function HomePage() {
  return (
    <>
      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-[60] focus:rounded-full focus:bg-ink focus:px-4 focus:py-2 focus:text-sm focus:font-semibold focus:text-white"
      >
        Skip to content
      </a>

      <header className="sticky top-0 z-50 border-b border-line/70 bg-paper/80 backdrop-blur-xl">
        <div className="wrap flex h-16 items-center justify-between gap-6">
          <a href="#top" className="flex items-center gap-2.5" aria-label="GaitGuard home">
            <span className="flex h-8 w-8 items-center justify-center rounded-[10px] bg-gradient-to-br from-indigo to-violet">
              <span className="h-3.5 w-3.5 rounded-full border-[2.5px] border-white" />
            </span>
            <span className="text-[1.05rem] font-semibold tracking-tight">GaitGuard</span>
          </a>
          <nav className="hidden items-center gap-8 text-[0.9rem] text-mute md:flex" aria-label="Primary">
            <a href="#how" className="transition hover:text-ink">How it works</a>
            <a href="#rhythm" className="transition hover:text-ink">Try the rhythm</a>
            <a href="#sync" className="transition hover:text-ink">Sync</a>
            <a href="#faq" className="transition hover:text-ink">FAQ</a>
          </nav>
          <a href={REPO} target="_blank" rel="noopener noreferrer" className="btn btn-ink !min-h-[40px] !px-4 !text-[0.85rem]">
            GitHub
          </a>
        </div>
      </header>

      <main id="main">
        {/* ── Hero ─────────────────────────────────────────── */}
        <section id="top" className="relative overflow-hidden">
          <div
            className="pointer-events-none absolute inset-0"
            aria-hidden="true"
            style={{
              background:
                "radial-gradient(50% 55% at 85% 35%, rgba(155,107,255,0.18), transparent 70%), radial-gradient(45% 50% at 65% 70%, rgba(79,85,232,0.16), transparent 70%)",
            }}
          />
          <div className="wrap relative grid items-center gap-14 pb-20 pt-14 md:pt-20 lg:grid-cols-[1.05fr_1fr] lg:gap-8 lg:pb-28">
            <div>
              <p className="rise inline-flex items-center gap-2 rounded-full border border-line bg-card px-3.5 py-1.5 text-[0.8rem] font-medium text-mute">
                <span className="h-2 w-2 rounded-full bg-cue" />
                For freezing of gait · Apple Watch + iPhone
              </p>
              <h1 className="display rise rise-1 mt-7 text-[clamp(2.9rem,7.2vw,5.6rem)]">
                Keep the beat when your steps <span className="serif brand-grad pr-1">stall.</span>
              </h1>
              <p className="rise rise-2 mt-7 max-w-[30em] text-[1.12rem] leading-relaxed text-mute">
                GaitGuard notices a freeze on your wrist and answers with a steady, rhythmic tap. Your iPhone mirrors every moment, live.
              </p>
              <div className="rise rise-3 mt-9 flex flex-col gap-3 sm:flex-row">
                <span className="btn btn-ink" aria-disabled="true">
                  <svg viewBox="0 0 24 24" className="h-5 w-5" fill="currentColor" aria-hidden="true">
                    <path d="M16.4 12.6c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.8-1.4-.1-2.8.9-3.5.9-.7 0-1.8-.8-3-.8-1.5 0-3 .9-3.8 2.3-1.6 2.8-.4 7 1.2 9.3.8 1.1 1.7 2.4 2.9 2.3 1.2 0 1.6-.7 3-.7s1.8.7 3 .7c1.3 0 2.1-1.1 2.8-2.3.9-1.3 1.3-2.5 1.3-2.6 0 0-2.5-1-2.5-3.8zM14.1 5.8c.6-.8 1.1-1.9 1-3-1 0-2.1.7-2.8 1.4-.6.7-1.1 1.8-1 2.9 1.1.1 2.1-.5 2.8-1.3z" />
                  </svg>
                  Coming soon to the App Store
                </span>
                <a href="#rhythm" className="btn btn-ghost">
                  Try the rhythm
                </a>
              </div>
              <ul className="rise rise-4 mt-10 flex flex-wrap gap-x-7 gap-y-2 text-[0.85rem] text-mute">
                <li className="flex items-center gap-2"><Icon d={icons.lock} className="h-4 w-4" /> No account, no cloud</li>
                <li className="flex items-center gap-2"><Icon d={icons.sync} className="h-4 w-4" /> Real-time Watch ↔ iPhone</li>
                <li className="flex items-center gap-2"><Icon d={icons.note} className="h-4 w-4" /> Open source</li>
              </ul>
            </div>

            <div className="rise rise-2 -mb-[120px] origin-top scale-[0.78] sm:mb-0 sm:scale-100">
              <HeroDemo />
            </div>
          </div>
        </section>

        {/* ── The moment ─────────────────────────────────── */}
        <section className="border-y border-line bg-card">
          <div className="wrap py-[clamp(72px,9vw,128px)]">
            <Reveal>
              <p className="eyebrow">The moment it&apos;s for</p>
              <p className="mt-6 max-w-[26em] text-[clamp(1.6rem,3.3vw,2.6rem)] font-medium leading-[1.2] tracking-[-0.025em] text-ink-2">
                A freeze can feel like your feet are{" "}
                <span className="serif text-ink">glued to the floor</span>, often on the first step, at a turn, or in a doorway.
                A steady outside rhythm can help the next step come.{" "}
                <span className="text-mute-2">GaitGuard puts that rhythm on your wrist, right when it&apos;s needed.</span>
              </p>
            </Reveal>
          </div>
        </section>

        {/* ── How it works ───────────────────────────────── */}
        <section id="how" className="section scroll-mt-16">
          <div className="wrap">
            <Reveal className="max-w-2xl">
              <p className="eyebrow">How it works</p>
              <h2 className="h2 mt-4">
                Sense. Cue. <span className="serif text-mute-2">Understand.</span>
              </h2>
            </Reveal>
            <ol className="mt-14 grid gap-5 md:grid-cols-3">
              {steps.map((s, i) => (
                <Reveal as="li" key={s.n} delay={i * 90} className="panel flex flex-col p-8">
                  <div className="flex items-center justify-between">
                    <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-indigo/10 text-indigo">
                      <Icon d={s.icon} className="h-6 w-6" />
                    </span>
                    <span className="font-mono text-[0.8rem] text-mute-2">{s.n}</span>
                  </div>
                  <h3 className="mt-10 text-[1.35rem] font-semibold tracking-tight">{s.title}</h3>
                  <p className="mt-3 text-[1rem] leading-relaxed text-mute">{s.body}</p>
                </Reveal>
              ))}
            </ol>
          </div>
        </section>

        {/* ── Rhythm trainer ─────────────────────────────── */}
        <section id="rhythm" className="section scroll-mt-16">
          <div className="wrap">
            <Reveal className="panel overflow-hidden p-7 sm:p-12">
              <div className="max-w-2xl">
                <p className="eyebrow">Try it</p>
                <h2 className="h2 mt-4">
                  Feel the <span className="serif brand-grad">rhythm.</span>
                </h2>
                <p className="mt-5 text-[1.05rem] leading-relaxed text-mute">
                  This is the idea behind the cue. Pick a tempo, press start, and try stepping in time.
                </p>
              </div>
              <div className="mt-12">
                <RhythmTrainer />
              </div>
            </Reveal>
          </div>
        </section>

        {/* ── Sync playground ────────────────────────────── */}
        <section id="sync" className="section scroll-mt-16">
          <div className="bg-night text-white">
            <div className="relative overflow-hidden">
              <div
                className="pointer-events-none absolute inset-0"
                aria-hidden="true"
                style={{
                  background:
                    "radial-gradient(40% 50% at 20% 0%, rgba(124,140,255,0.22), transparent 70%), radial-gradient(40% 50% at 85% 10%, rgba(181,140,255,0.18), transparent 70%)",
                }}
              />
              <div className="wrap relative py-[clamp(80px,10vw,140px)]">
                <Reveal className="mx-auto max-w-2xl text-center">
                  <p className="eyebrow !text-indigo-soft">Real-time sync</p>
                  <h2 className="h2 mt-4">
                    One walk. Two screens. <span className="serif text-indigo-soft">Always in step.</span>
                  </h2>
                  <p className="mt-5 text-[1.05rem] leading-relaxed text-white/60">
                    Try it: start on either device, then simulate a freeze. Everything mirrors instantly, just like the real apps.
                  </p>
                </Reveal>
                <div className="mt-16">
                  <SyncPlayground />
                </div>
                <ul className="mx-auto mt-16 grid max-w-[980px] gap-4 md:grid-cols-3">
                  {[
                    ["One source of truth", "The Watch measures, the iPhone mirrors. Both draw the same score from the same state."],
                    ["Catches up on open", "Open either app and it pulls the latest session, settings and history straight away."],
                    ["Nothing gets lost", "Out of range? Changes queue up and land the moment the devices reconnect."],
                  ].map(([t, b], i) => (
                    <Reveal as="li" key={t} delay={i * 90} className="rounded-3xl border border-white/10 bg-white/[0.03] p-6">
                      <h3 className="text-[1.05rem] font-semibold">{t}</h3>
                      <p className="mt-2 text-[0.95rem] leading-relaxed text-white/60">{b}</p>
                    </Reveal>
                  ))}
                </ul>
              </div>
            </div>
          </div>
        </section>

        {/* ── Features ───────────────────────────────────── */}
        <section id="features" className="section scroll-mt-16">
          <div className="wrap">
            <Reveal className="max-w-2xl">
              <p className="eyebrow">Features</p>
              <h2 className="h2 mt-4">Built for the moments that stick.</h2>
            </Reveal>
            <ul className="mt-14 grid gap-x-10 gap-y-12 sm:grid-cols-2 lg:grid-cols-3">
              {features.map((f, i) => (
                <Reveal as="li" key={f.title} delay={(i % 3) * 80} className="border-t border-line pt-7">
                  <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-card text-indigo shadow-[inset_0_0_0_1px_var(--line)]">
                    <Icon d={f.icon} />
                  </span>
                  <h3 className="mt-5 text-[1.15rem] font-semibold tracking-tight">{f.title}</h3>
                  <p className="mt-2 text-[1rem] leading-relaxed text-mute">{f.body}</p>
                </Reveal>
              ))}
            </ul>
          </div>
        </section>

        {/* ── Who it&apos;s for ───────────────────────────────── */}
        <section id="who" className="section scroll-mt-16">
          <div className="wrap">
            <Reveal className="max-w-2xl">
              <p className="eyebrow">Who it&apos;s for</p>
              <h2 className="h2 mt-4">
                Made with the people <span className="serif text-mute-2">around the walk</span> in mind.
              </h2>
            </Reveal>
            <ul className="mt-14 grid gap-5 lg:grid-cols-3">
              {people.map((p, i) => (
                <Reveal
                  as="li"
                  key={p.who}
                  delay={i * 90}
                  className={`rounded-[32px] p-8 ${
                    i === 0 ? "bg-gradient-to-br from-indigo to-violet text-white" : "panel"
                  }`}
                >
                  <h3 className="text-[1.3rem] font-semibold tracking-tight">{p.who}</h3>
                  <p className={`mt-3 text-[1rem] leading-relaxed ${i === 0 ? "text-white/80" : "text-mute"}`}>{p.body}</p>
                </Reveal>
              ))}
            </ul>
          </div>
        </section>

        {/* ── Safety ─────────────────────────────────────── */}
        <section id="safety" className="section scroll-mt-16">
          <div className="wrap">
            <Reveal className="grid gap-10 rounded-[32px] border border-cue/30 bg-[#fff8ea] p-8 sm:p-12 lg:grid-cols-[0.8fr_1.2fr]">
              <div>
                <p className="eyebrow !text-[#a8620a]">Safety</p>
                <h2 className="mt-4 text-[clamp(1.7rem,3vw,2.4rem)] font-semibold leading-[1.08] tracking-[-0.03em]">
                  Clear about what this is, and what it isn&apos;t.
                </h2>
              </div>
              <ul className="grid gap-5 text-[1rem] leading-relaxed text-ink-2 sm:grid-cols-2">
                <li><strong className="font-semibold">Not a medical device.</strong> GaitGuard is a cueing aid and prototype. It doesn&apos;t diagnose, treat, or prevent disease.</li>
                <li><strong className="font-semibold">Use with supervision</strong> before relying on it in risky situations. Turning difficulty can raise fall risk.</li>
                <li><strong className="font-semibold">Pair it with care.</strong> Rhythmic cueing works best alongside strategies taught by a clinician or PT.</li>
                <li><strong className="font-semibold">No fall detection.</strong> The app doesn&apos;t detect falls or contact emergency services.</li>
              </ul>
            </Reveal>
          </div>
        </section>

        {/* ── FAQ ────────────────────────────────────────── */}
        <section id="faq" className="section scroll-mt-16">
          <div className="wrap grid gap-12 lg:grid-cols-[0.8fr_1.2fr]">
            <Reveal>
              <p className="eyebrow">FAQ</p>
              <h2 className="h2 mt-4">Questions, answered.</h2>
            </Reveal>
            <Reveal className="divide-y divide-line border-y border-line">
              {faqs.map(([q, a]) => (
                <details key={q} className="group py-6">
                  <summary className="flex cursor-pointer list-none items-center justify-between gap-6 text-[1.1rem] font-medium">
                    {q}
                    <span
                      className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full border border-line text-mute transition group-open:rotate-45 group-open:border-ink group-open:text-ink"
                      aria-hidden="true"
                    >
                      +
                    </span>
                  </summary>
                  <p className="mt-3 max-w-[40em] text-[1rem] leading-relaxed text-mute">{a}</p>
                </details>
              ))}
            </Reveal>
          </div>
        </section>

        {/* ── CTA ────────────────────────────────────────── */}
        <section className="section pb-[var(--section)]">
          <div className="wrap">
            <Reveal className="relative overflow-hidden rounded-[40px] bg-night px-7 py-20 text-center text-white sm:px-14">
              <div
                className="pointer-events-none absolute inset-0"
                aria-hidden="true"
                style={{
                  background:
                    "radial-gradient(50% 70% at 50% 110%, rgba(124,140,255,0.45), transparent 70%), radial-gradient(30% 40% at 90% 0%, rgba(181,140,255,0.3), transparent 70%)",
                }}
              />
              <div className="relative mx-auto max-w-2xl">
                <h2 className="h2">
                  Walk with a <span className="serif text-indigo-soft">quieter</span> kind of confidence.
                </h2>
                <p className="mx-auto mt-5 max-w-[30em] text-[1.05rem] leading-relaxed text-white/60">
                  The App Store release is on the way. Follow along, or explore the code, on GitHub.
                </p>
                <div className="mt-9 flex flex-col items-center justify-center gap-3 sm:flex-row">
                  <a href={REPO} target="_blank" rel="noopener noreferrer" className="btn bg-white text-night hover:-translate-y-px">
                    View on GitHub
                  </a>
                  <a href="#rhythm" className="btn border border-white/20 text-white hover:border-white/50">
                    Try the rhythm
                  </a>
                </div>
              </div>
            </Reveal>
          </div>
        </section>
      </main>

      <footer className="border-t border-line">
        <div className="wrap flex flex-col gap-6 py-10 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center gap-2.5">
            <span className="flex h-7 w-7 items-center justify-center rounded-[9px] bg-gradient-to-br from-indigo to-violet">
              <span className="h-3 w-3 rounded-full border-2 border-white" />
            </span>
            <div>
              <p className="text-[0.9rem] font-semibold">GaitGuard</p>
              <p className="text-[0.75rem] text-mute-2">Not a medical device. Use with supervision.</p>
            </div>
          </div>
          <nav className="flex flex-wrap gap-6 text-[0.85rem] text-mute" aria-label="Footer">
            <a href="#how" className="hover:text-ink">How it works</a>
            <a href="#safety" className="hover:text-ink">Safety</a>
            <a href="#faq" className="hover:text-ink">FAQ</a>
            <a href={REPO} target="_blank" rel="noopener noreferrer" className="hover:text-ink">GitHub</a>
          </nav>
          <p className="text-[0.75rem] text-mute-2">© {new Date().getFullYear()} GaitGuard · MIT</p>
        </div>
      </footer>
    </>
  );
}
