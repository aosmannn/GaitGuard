import { LiveSyncDemo } from "@/components/LiveSyncDemo";

const REPO = "https://github.com/pogami/GaitGuardAI";

const steps = [
  {
    n: "01",
    title: "Detect",
    body: "Your Apple Watch reads motion continuously and spots starts or turns that stall before they become steps.",
    icon: "M3 12h4l3-8 4 16 3-8h4",
  },
  {
    n: "02",
    title: "Cue",
    body: "A metronome-style haptic pulses on your wrist, with different patterns for starting and turning.",
    icon: "M12 2v4m0 12v4M4.9 4.9l2.8 2.8m8.6 8.6 2.8 2.8M2 12h4m12 0h4M4.9 19.1l2.8-2.8m8.6-8.6 2.8-2.8",
  },
  {
    n: "03",
    title: "Review",
    body: "Your iPhone mirrors the session live and keeps a timeline of every cue, so trends are easy to see and share.",
    icon: "M4 19V9m6 10V5m6 14v-7m6 7H2",
  },
];

const features = [
  {
    title: "Real-time on both screens",
    body: "Start, stop, score, steps and cues update on Watch and iPhone together, within a moment.",
    span: "md:col-span-2",
    accent: true,
  },
  {
    title: "Personal calibration",
    body: "A 30-second walk tunes thresholds to your own baseline.",
  },
  {
    title: "Rhythmic haptics",
    body: "Different patterns for starts and turns, with adjustable intensity.",
  },
  {
    title: "Remote control",
    body: "Start or stop monitoring and change sensitivity from your iPhone.",
  },
  {
    title: "Runs in the background",
    body: "A workout session keeps monitoring while the Watch screen sleeps.",
    span: "md:col-span-2",
  },
];

const syncPoints = [
  {
    title: "One source of truth",
    body: "The Watch measures. The iPhone mirrors. Both draw the same gait score from the same state, so they never disagree.",
  },
  {
    title: "Catches up instantly",
    body: "Open either app and it pulls the latest session, settings and cue history straight away.",
  },
  {
    title: "Nothing gets lost",
    body: "If your Watch is out of range, changes queue up and land the moment it reconnects.",
  },
];

const audience = [
  ["Sticky starts", "A foot that stalls when you try to begin walking."],
  ["Hard turns", "Turns that feel stuck or unsafe to attempt alone."],
  ["Festination", "Speeding up or leaning forward as steps shorten."],
  ["Guided practice", "Exploring rhythmic cueing with a clinician or PT."],
];

const faqs = [
  [
    "Is GaitGuardAI a medical device?",
    "No. It is a cueing aid and prototype. It does not diagnose, treat, or prevent any condition, and it does not detect falls or contact emergency services.",
  ],
  [
    "What do I need to use it?",
    "An iPhone (iOS 17+) and a paired Apple Watch (watchOS 10+). Monitoring and haptics run on the Watch; the iPhone is the companion.",
  ],
  [
    "Do I need to be near my iPhone?",
    "No. The Watch keeps cueing on its own. When the two reconnect, history and settings sync automatically.",
  ],
  [
    "When can I get it?",
    "An App Store release is on the way. The open-source project is on GitHub today.",
  ],
];

function Icon({ d }: { d: string }) {
  return (
    <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d={d} />
    </svg>
  );
}

export default function HomePage() {
  return (
    <>
      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-[60] focus:rounded-full focus:bg-accent focus:px-4 focus:py-2 focus:text-sm focus:font-semibold focus:text-bg"
      >
        Skip to content
      </a>

      <div className="pointer-events-none fixed left-1/2 top-[clamp(0.75rem,2vw,1.25rem)] z-50 w-max max-w-[calc(100vw-1.5rem)] -translate-x-1/2">
        <header className="pointer-events-auto flex items-center gap-4 rounded-full border border-white/10 bg-[rgba(18,21,31,0.7)] py-1.5 pl-4 pr-1.5 shadow-[0_16px_40px_rgba(0,0,0,0.4)] backdrop-blur-xl sm:gap-7 sm:pl-5">
          <a href="#top" className="flex shrink-0 items-center gap-2">
            <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-gradient-to-br from-accent to-accent-2 text-[13px] font-extrabold text-bg">
              G
            </span>
            <span className="text-[15px] font-semibold tracking-tight">GaitGuardAI</span>
          </a>
          <nav className="hidden items-center gap-6 text-[14px] text-text-2 md:flex" aria-label="Primary">
            <a href="#how" className="transition hover:text-text">How it works</a>
            <a href="#sync" className="transition hover:text-text">Real-time sync</a>
            <a href="#features" className="transition hover:text-text">Features</a>
            <a href="#faq" className="transition hover:text-text">FAQ</a>
          </nav>
          <a
            href={REPO}
            target="_blank"
            rel="noopener noreferrer"
            className="btn-primary inline-flex items-center rounded-full px-4 py-2 text-[13.5px] font-semibold transition hover:-translate-y-px"
          >
            GitHub
          </a>
        </header>
      </div>

      <main id="main">
        {/* Hero */}
        <section id="top" className="relative overflow-hidden">
          <div className="aurora" aria-hidden="true" />
          <div className="grid-bg" aria-hidden="true" />

          <div className="wrap relative pb-6 pt-[clamp(120px,15vw,190px)] text-center">
            <p className="anim-up mx-auto inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.04] px-3.5 py-1.5 text-[12.5px] font-medium text-text-2">
              <span className="h-1.5 w-1.5 rounded-full bg-cue" />
              Apple Watch + iPhone · for freezing of gait
            </p>
            <h1 className="anim-up-1 mx-auto mt-7 max-w-[15ch] text-[clamp(42px,7.4vw,96px)] font-semibold leading-[0.98] tracking-[-0.045em] text-balance">
              A steady rhythm <span className="grad-text">when walking freezes</span>
            </h1>
            <p className="anim-up-2 mx-auto mt-7 max-w-[36em] text-[clamp(16px,1.5vw,19px)] leading-relaxed text-text-2 text-balance">
              GaitGuardAI senses a freeze on your wrist and answers with a gentle rhythmic haptic, while your iPhone mirrors everything live.
            </p>
            <div className="anim-up-3 mt-9 flex flex-col items-center justify-center gap-3 sm:flex-row">
              <span className="btn-primary inline-flex items-center rounded-full px-7 py-3.5 text-base font-semibold">
                Coming soon to the App Store
              </span>
              <a
                href="#sync"
                className="inline-flex items-center rounded-full border border-white/15 px-7 py-3.5 text-base font-medium transition hover:border-white/40 hover:bg-white/[0.04]"
              >
                See it in sync
              </a>
            </div>
            <p className="mt-5 text-[13px] text-text-3">Not a medical device. Use with supervision.</p>
          </div>

          <div className="wrap relative pb-24 pt-[clamp(40px,6vw,72px)]">
            <LiveSyncDemo />
          </div>
        </section>

        {/* How it works */}
        <section id="how" className="scroll-mt-24" style={{ paddingTop: "var(--gap-section)" }}>
          <div className="wrap">
            <p className="text-[12px] font-semibold uppercase tracking-[0.16em] text-accent">How it works</p>
            <h2 className="mt-3 max-w-[16em] text-[clamp(30px,4.4vw,56px)] font-semibold leading-[1.04] tracking-[-0.035em] text-balance">
              Sense it. Cue it. <span className="text-text-3">Understand it.</span>
            </h2>
            <ul className="mt-14 grid gap-5 md:grid-cols-3">
              {steps.map((s) => (
                <li key={s.n} className="card p-7">
                  <div className="flex items-center justify-between">
                    <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-accent/12 text-accent">
                      <Icon d={s.icon} />
                    </span>
                    <span className="text-sm font-semibold tabular-nums text-text-3">{s.n}</span>
                  </div>
                  <h3 className="mt-8 text-[22px] font-semibold tracking-tight">{s.title}</h3>
                  <p className="mt-3 text-[15px] leading-relaxed text-text-2">{s.body}</p>
                </li>
              ))}
            </ul>
          </div>
        </section>

        {/* Sync */}
        <section id="sync" className="scroll-mt-24" style={{ paddingTop: "var(--gap-section)" }}>
          <div className="wrap">
            <div className="card relative overflow-hidden px-7 py-12 sm:px-12 sm:py-16">
              <div className="pointer-events-none absolute -right-24 -top-24 h-80 w-80 rounded-full bg-accent-2/25 blur-[90px]" aria-hidden="true" />
              <div className="relative grid gap-12 lg:grid-cols-[1fr_1.1fr] lg:items-center">
                <div>
                  <p className="text-[12px] font-semibold uppercase tracking-[0.16em] text-accent">Real-time sync</p>
                  <h2 className="mt-3 text-[clamp(28px,3.8vw,48px)] font-semibold leading-[1.05] tracking-[-0.035em] text-balance">
                    One session, <span className="grad-text">two screens, always in step</span>
                  </h2>
                  <p className="mt-5 max-w-[32em] text-[16px] leading-relaxed text-text-2">
                    Start on your wrist or from your phone. The score, cues and settings follow you across both.
                  </p>
                </div>
                <ul className="space-y-3">
                  {syncPoints.map((p) => (
                    <li key={p.title} className="rounded-2xl border border-white/8 bg-white/[0.03] p-5">
                      <h3 className="text-[16px] font-semibold">{p.title}</h3>
                      <p className="mt-1.5 text-[14.5px] leading-relaxed text-text-2">{p.body}</p>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </div>
        </section>

        {/* Features bento */}
        <section id="features" className="scroll-mt-24" style={{ paddingTop: "var(--gap-section)" }}>
          <div className="wrap">
            <p className="text-[12px] font-semibold uppercase tracking-[0.16em] text-accent">Features</p>
            <h2 className="mt-3 max-w-[16em] text-[clamp(30px,4.4vw,56px)] font-semibold leading-[1.04] tracking-[-0.035em] text-balance">
              Built for the moments that stick
            </h2>
            <ul className="mt-14 grid gap-4 md:grid-cols-4">
              {features.map((f) => (
                <li
                  key={f.title}
                  className={`card p-7 ${f.span ?? ""} ${f.accent ? "!border-accent/30 bg-gradient-to-br from-accent/15 to-accent-2/5" : ""}`}
                >
                  <h3 className="text-[19px] font-semibold tracking-tight">{f.title}</h3>
                  <p className="mt-2.5 max-w-[28em] text-[15px] leading-relaxed text-text-2">{f.body}</p>
                </li>
              ))}
            </ul>
          </div>
        </section>

        {/* Audience */}
        <section id="audience" className="scroll-mt-24" style={{ paddingTop: "var(--gap-section)" }}>
          <div className="wrap">
            <h2 className="max-w-[16em] text-[clamp(30px,4.4vw,56px)] font-semibold leading-[1.04] tracking-[-0.035em] text-balance">
              Made for people <span className="text-text-3">navigating gait freezes</span>
            </h2>
            <ul className="mt-14 grid gap-4 sm:grid-cols-2">
              {audience.map(([title, body], i) => (
                <li key={title} className="flex gap-5 rounded-[24px] border border-white/8 bg-white/[0.025] p-6">
                  <span className="text-sm font-semibold tabular-nums text-accent">0{i + 1}</span>
                  <div>
                    <h3 className="text-[19px] font-semibold tracking-tight">{title}</h3>
                    <p className="mt-2 text-[15px] leading-relaxed text-text-2">{body}</p>
                  </div>
                </li>
              ))}
            </ul>
          </div>
        </section>

        {/* Safety */}
        <section id="safety" className="scroll-mt-24" style={{ paddingTop: "var(--gap-section)" }}>
          <div className="wrap">
            <div className="rounded-[28px] border border-cue/25 bg-cue/[0.05] px-7 py-10 sm:px-12 sm:py-12">
              <p className="text-[12px] font-semibold uppercase tracking-[0.16em] text-cue">Safety</p>
              <h2 className="mt-3 max-w-[20em] text-[clamp(26px,3.4vw,42px)] font-semibold leading-[1.06] tracking-[-0.03em]">
                Clear about what this is, and isn&apos;t
              </h2>
              <ul className="mt-7 grid gap-x-10 gap-y-4 text-[15px] leading-relaxed text-text-2 md:grid-cols-2">
                <li><strong className="font-semibold text-text">Not a medical device.</strong> GaitGuardAI is a cueing aid and prototype. It does not diagnose, treat, or prevent disease.</li>
                <li>Use with supervision before relying on it in high-risk situations. Turning difficulty can increase fall risk.</li>
                <li>Consider involving a clinician or PT. Rhythmic cueing works best with taught strategies.</li>
                <li>The app does not detect falls or contact emergency services.</li>
              </ul>
            </div>
          </div>
        </section>

        {/* FAQ */}
        <section id="faq" className="scroll-mt-24" style={{ paddingTop: "var(--gap-section)" }}>
          <div className="wrap max-w-[860px]">
            <h2 className="text-[clamp(28px,3.8vw,46px)] font-semibold leading-[1.05] tracking-[-0.035em]">Questions</h2>
            <div className="mt-10 divide-y divide-white/10 border-y border-white/10">
              {faqs.map(([q, a]) => (
                <details key={q} className="group py-5">
                  <summary className="flex cursor-pointer list-none items-center justify-between gap-4 text-[17px] font-medium">
                    {q}
                    <span className="text-text-3 transition group-open:rotate-45" aria-hidden="true">+</span>
                  </summary>
                  <p className="mt-3 max-w-[42em] text-[15px] leading-relaxed text-text-2">{a}</p>
                </details>
              ))}
            </div>
          </div>
        </section>

        {/* CTA */}
        <section id="cta" className="scroll-mt-24" style={{ paddingTop: "var(--gap-section)", paddingBottom: "var(--gap-section)" }}>
          <div className="wrap">
            <div className="relative overflow-hidden rounded-[32px] border border-white/10 bg-gradient-to-br from-[#1b2050] via-[#171a3a] to-[#241a4a] px-7 py-16 text-center sm:px-14">
              <div className="aurora opacity-70" aria-hidden="true" />
              <div className="relative mx-auto max-w-2xl">
                <h2 className="text-[clamp(30px,4.6vw,56px)] font-semibold leading-[1.04] tracking-[-0.035em] text-balance">
                  Walk with a quieter kind of confidence
                </h2>
                <p className="mt-4 text-base leading-relaxed text-text-2">
                  App Store release is on the way. Follow the open-source build on GitHub today.
                </p>
                <div className="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
                  <a href={REPO} target="_blank" rel="noopener noreferrer" className="btn-primary inline-flex items-center rounded-full px-7 py-3.5 text-base font-semibold">
                    View on GitHub
                  </a>
                  <span className="text-[13px] text-text-3">Not a medical device. Use with supervision.</span>
                </div>
              </div>
            </div>
          </div>
        </section>
      </main>

      <footer className="border-t border-white/8 px-[var(--pad)] py-10">
        <div className="mx-auto flex max-w-[var(--wrap)] flex-col gap-5 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p className="text-sm font-semibold">GaitGuardAI</p>
            <p className="mt-1 text-xs text-text-3">Not a medical device. Use with supervision.</p>
          </div>
          <div className="flex flex-wrap gap-5 text-sm text-text-2">
            <a href={REPO} target="_blank" rel="noopener noreferrer" className="hover:text-text">GitHub</a>
            <a href="#safety" className="hover:text-text">Safety</a>
            <a href="#how" className="hover:text-text">How it works</a>
          </div>
          <p className="text-xs text-text-3">© {new Date().getFullYear()} GaitGuardAI · MIT</p>
        </div>
      </footer>
    </>
  );
}
