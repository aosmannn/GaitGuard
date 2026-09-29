import { ProductStage } from "@/components/DeviceMocks";

const steps = [
  {
    n: "01",
    label: "Detect",
    title: "Sense the freeze",
    body: "The Watch samples motion at ~50 Hz and flags start or turn attempts that never become steps.",
  },
  {
    n: "02",
    label: "Cue",
    title: "Pulse a rhythm",
    body: "Metronome-style haptics help re-initiate walking — different patterns for starts and turns.",
  },
  {
    n: "03",
    label: "Review",
    title: "See it on iPhone",
    body: "Live steps, cadence, events, and remote controls stay in your pocket while the Watch keeps cueing.",
  },
];

const features = [
  {
    title: "Freeze detection",
    body: "Catches gait initiation and turning freezes before hesitation deepens.",
  },
  {
    title: "Rhythmic haptics",
    body: "Wrist pulses timed like a metronome — tuned for starts vs turns.",
  },
  {
    title: "Live companion",
    body: "iPhone dashboard for connection status, metrics, and timeline.",
  },
  {
    title: "Remote control",
    body: "Adjust sensitivity, pattern, and intensity without stopping.",
  },
  {
    title: "Personal calibration",
    body: "A short walk sets thresholds to your baseline, not a generic model.",
  },
  {
    title: "Background monitoring",
    body: "HealthKit workouts keep tracking when the Watch screen sleeps.",
  },
];

const audience = [
  {
    n: "01",
    title: "Sticky starts",
    body: "A foot that sticks when you try to begin walking.",
  },
  {
    n: "02",
    title: "Hard turns",
    body: "Turns that feel stuck or unsafe to attempt alone.",
  },
  {
    n: "03",
    title: "Festination",
    body: "Speeding up or leaning forward as steps shorten.",
  },
  {
    n: "04",
    title: "Guided practice",
    body: "Exploring rhythmic cueing with a clinician or PT.",
  },
];

export default function HomePage() {
  return (
    <>
      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-[60] focus:rounded-full focus:bg-accent focus:px-4 focus:py-2 focus:text-sm focus:font-semibold focus:text-white"
      >
        Skip to content
      </a>

      {/* Floating pill nav */}
      <div className="pointer-events-none fixed left-1/2 top-[clamp(0.9rem,2vw,1.5rem)] z-50 w-max max-w-[calc(100vw-1.5rem)] -translate-x-1/2">
        <header className="pointer-events-auto flex items-center gap-4 rounded-full border border-[rgba(35,33,29,0.1)] bg-[rgba(251,249,244,0.78)] py-1.5 pl-4 pr-1.5 shadow-[0_12px_32px_rgba(20,70,55,0.12)] backdrop-blur-xl supports-[backdrop-filter]:bg-[rgba(251,249,244,0.72)] sm:gap-6 sm:pl-5">
          <a href="#top" className="flex shrink-0 items-center gap-2">
            <span className="flex h-7 w-7 items-center justify-center rounded-full bg-accent text-[13px] font-bold text-white">
              G
            </span>
            <span className="text-[15px] font-semibold tracking-tight text-ink">
              GaitGuardAI
            </span>
          </a>
          <nav
            className="hidden items-center gap-5 text-[14.5px] text-ink-3 md:flex"
            aria-label="Primary"
          >
            <a href="#how" className="transition hover:text-ink">
              How it works
            </a>
            <a href="#features" className="transition hover:text-ink">
              Features
            </a>
            <a href="#safety" className="transition hover:text-ink">
              Safety
            </a>
          </nav>
          <a
            href="https://github.com/aosmannn/GaitGuard"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center rounded-full bg-accent px-4 py-2 text-[13.5px] font-semibold text-white shadow-[0_14px_30px_-14px_rgba(20,154,124,0.7)] transition hover:bg-accent-hover hover:-translate-y-px"
          >
            View on GitHub
          </a>
        </header>
      </div>

      <main id="main">
        {/* Hero */}
        <section id="top" className="relative px-[clamp(10px,1.4vw,18px)]">
          <div
            className="pointer-events-none absolute inset-x-[clamp(10px,1.4vw,18px)] top-0 h-[clamp(560px,64vw,900px)] overflow-hidden rounded-b-[32px]"
            aria-hidden="true"
          >
            <div
              className="absolute inset-0"
              style={{
                background: `
                  radial-gradient(74% 62% at 4% 6%, var(--hero-g1) 0%, transparent 58%),
                  radial-gradient(62% 56% at 96% 2%, var(--hero-g2) 0%, transparent 60%),
                  radial-gradient(86% 70% at 26% 100%, var(--hero-g3) 0%, transparent 62%),
                  radial-gradient(56% 52% at 92% 84%, var(--hero-g4) 0%, transparent 60%),
                  linear-gradient(180deg, var(--hero-base-a) 0%, var(--hero-base-b) 62%, var(--bg) 100%)
                `,
              }}
            />
            <div className="noise" />
          </div>

          <div className="wrap relative grid grid-cols-1 items-start gap-8 pb-0 pt-[calc(clamp(56px,7vw,104px)+72px)] md:grid-cols-[minmax(0,3fr)_minmax(0,7fr)] md:gap-[clamp(24px,5vw,72px)]">
            <div className="anim-up pt-2 md:pt-4">
              <p className="flex items-start gap-2.5 text-[clamp(15px,1.2vw,17.5px)] font-semibold leading-snug tracking-[-0.01em] text-ink">
                <span className="pin mt-1" aria-hidden="true" />
                <span className="max-w-[12em]">
                  Cueing on the wrist, clarity in your pocket
                </span>
              </p>
            </div>

            <div>
              <h1 className="anim-up-1 max-w-[14ch] text-[clamp(40px,6.4vw,88px)] font-semibold leading-[0.98] tracking-[-0.04em] text-balance">
                <span className="text-mute-2">Rhythmic cueing</span>
                <br />
                <span>when walking freezes</span>
              </h1>

              <div className="anim-up-2 mt-9 flex flex-col items-start gap-4">
                <div className="flex flex-wrap items-center gap-3">
                  <span className="inline-flex items-center rounded-full bg-accent px-7 py-[15px] text-base font-semibold text-white shadow-[0_14px_30px_-14px_rgba(20,154,124,0.7)]">
                    Coming soon on the App Store
                  </span>
                  <a
                    href="#how"
                    className="inline-flex items-center rounded-full border border-[rgba(35,33,29,0.2)] px-7 py-[15px] text-base font-medium text-ink transition hover:border-ink"
                  >
                    See how it works
                  </a>
                </div>
                <p className="max-w-[36em] text-[13px] leading-relaxed text-mute-3">
                  Apple Watch + iPhone companion for freezing of gait. Not a
                  medical device — use with supervision.
                </p>
              </div>
            </div>
          </div>

          <div className="wrap relative mt-[clamp(44px,6vw,80px)] pb-8">
            <ProductStage />
          </div>
        </section>

        {/* How it works */}
        <section
          id="how"
          className="scroll-mt-28"
          style={{ paddingTop: "var(--gap-section)" }}
        >
          <div className="wrap">
            <h2 className="max-w-[18em] text-[clamp(30px,4.2vw,58px)] font-semibold leading-[1.03] tracking-[-0.035em] text-balance">
              <span className="text-mute-2">Your walk,</span> cued at every
              step
            </h2>

            <ul className="mt-14 grid gap-5 md:grid-cols-3">
              {steps.map((step) => (
                <li
                  key={step.n}
                  className="relative overflow-hidden rounded-[22px] border border-[rgba(35,33,29,0.06)] bg-card p-7 shadow-[0_18px_40px_-28px_rgba(20,70,55,0.28)]"
                >
                  <div className="flex items-start justify-between">
                    <span className="text-[42px] font-semibold leading-none tracking-tight text-[rgba(35,33,29,0.12)]">
                      {step.n}
                    </span>
                    <span className="text-[11px] font-semibold uppercase tracking-[0.14em] text-mute-3">
                      {step.label}
                    </span>
                  </div>
                  <h3 className="mt-10 text-[22px] font-semibold tracking-tight text-ink">
                    {step.title}
                  </h3>
                  <p className="mt-3 text-[15px] leading-relaxed text-mute">
                    {step.body}
                  </p>
                </li>
              ))}
            </ul>
          </div>
        </section>

        {/* Features */}
        <section
          id="features"
          className="scroll-mt-28"
          style={{ paddingTop: "var(--gap-section)" }}
        >
          <div className="wrap">
            <div className="max-w-2xl">
              <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-mute-3">
                Features
              </p>
              <h2 className="mt-3 text-[clamp(30px,4.2vw,58px)] font-semibold leading-[1.03] tracking-[-0.035em] text-balance">
                Built for the moments that stick
              </h2>
            </div>

            <ul className="mt-14 grid gap-x-10 gap-y-12 sm:grid-cols-2 lg:grid-cols-3">
              {features.map((f) => (
                <li key={f.title} className="border-t border-line pt-5">
                  <h3 className="text-lg font-semibold tracking-tight text-ink">
                    {f.title}
                  </h3>
                  <p className="mt-2 text-[15px] leading-relaxed text-mute">
                    {f.body}
                  </p>
                </li>
              ))}
            </ul>
          </div>
        </section>

        {/* Audience */}
        <section
          id="audience"
          className="scroll-mt-28"
          style={{ paddingTop: "var(--gap-section)" }}
        >
          <div className="wrap">
            <h2 className="max-w-[16em] text-[clamp(30px,4.2vw,58px)] font-semibold leading-[1.03] tracking-[-0.035em] text-balance">
              Built for people navigating gait freezes
            </h2>
            <ul className="mt-14 grid gap-6 sm:grid-cols-2">
              {audience.map((a) => (
                <li
                  key={a.n}
                  className="rounded-[22px] border border-[rgba(35,33,29,0.06)] bg-well/60 px-6 py-7"
                >
                  <div className="flex items-baseline gap-3">
                    <span className="text-sm font-semibold text-accent-deep">
                      {a.n}
                    </span>
                    <h3 className="text-xl font-semibold tracking-tight text-ink">
                      {a.title}
                    </h3>
                  </div>
                  <p className="mt-3 text-[15px] leading-relaxed text-mute">
                    {a.body}
                  </p>
                </li>
              ))}
            </ul>
          </div>
        </section>

        {/* Safety */}
        <section
          id="safety"
          className="scroll-mt-28"
          style={{ paddingTop: "var(--gap-section)" }}
        >
          <div className="wrap">
            <div className="max-w-3xl rounded-[28px] border border-[rgba(35,33,29,0.08)] bg-paper px-7 py-9 shadow-[0_24px_60px_-40px_rgba(20,70,55,0.35)] sm:px-10 sm:py-11">
              <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-mute-3">
                Safety
              </p>
              <h2 className="mt-3 text-[clamp(28px,3.6vw,44px)] font-semibold leading-[1.05] tracking-[-0.03em] text-ink">
                Clear about what this is — and isn&apos;t
              </h2>
              <ul className="mt-7 space-y-4 text-[15px] leading-relaxed text-mute">
                <li>
                  <strong className="font-semibold text-ink">
                    Not a medical device.
                  </strong>{" "}
                  GaitGuardAI is a cueing aid and prototype. It does not
                  diagnose, treat, or prevent disease.
                </li>
                <li>
                  Use with supervision before relying on it in high-risk
                  situations. Turning difficulty can increase fall risk.
                </li>
                <li>
                  Consider involving a clinician or PT. Rhythmic cueing works
                  best with taught strategies.
                </li>
                <li>
                  The app does not detect falls or contact emergency services.
                </li>
              </ul>
            </div>
          </div>
        </section>

        {/* CTA */}
        <section
          id="cta"
          className="scroll-mt-28"
          style={{
            paddingTop: "var(--gap-section)",
            paddingBottom: "var(--gap-section)",
          }}
        >
          <div className="wrap">
            <div className="relative overflow-hidden rounded-[32px] border border-[rgba(35,33,29,0.08)] bg-ink px-7 py-14 text-bg sm:px-14 sm:py-16">
              <div
                className="pointer-events-none absolute -right-16 -top-20 h-72 w-72 rounded-full opacity-40"
                style={{
                  background:
                    "radial-gradient(circle, rgba(46,222,184,0.55), transparent 70%)",
                }}
              />
              <div className="relative max-w-xl">
                <h2 className="text-[clamp(32px,4.5vw,52px)] font-semibold leading-[1.05] tracking-[-0.035em]">
                  Walk with a quieter kind of confidence
                </h2>
                <p className="mt-4 text-base leading-relaxed text-[rgba(251,249,244,0.72)]">
                  App Store release is on the way. Follow the open-source build
                  on GitHub today.
                </p>
                <div className="mt-8 flex flex-wrap gap-3">
                  <span className="inline-flex items-center rounded-full bg-accent px-7 py-[15px] text-base font-semibold text-white">
                    Coming soon
                  </span>
                  <a
                    href="https://github.com/aosmannn/GaitGuard"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center rounded-full border border-[rgba(251,249,244,0.28)] px-7 py-[15px] text-base font-medium text-bg transition hover:border-bg"
                  >
                    github.com/aosmannn/GaitGuard
                  </a>
                </div>
                <p className="mt-6 text-xs text-[rgba(251,249,244,0.5)]">
                  Not a medical device — use with supervision.
                </p>
              </div>
            </div>
          </div>
        </section>
      </main>

      <footer className="border-t border-line px-[var(--pad)] py-10">
        <div className="mx-auto flex max-w-[var(--wrap)] flex-col gap-5 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p className="text-sm font-semibold text-ink">GaitGuardAI</p>
            <p className="mt-1 text-xs text-mute-3">
              Not a medical device — use with supervision.
            </p>
          </div>
          <div className="flex flex-wrap gap-5 text-sm text-mute">
            <a
              href="https://github.com/aosmannn/GaitGuard"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-ink"
            >
              GitHub
            </a>
            <a href="#safety" className="hover:text-ink">
              Safety
            </a>
            <a href="#how" className="hover:text-ink">
              How it works
            </a>
          </div>
          <p className="text-xs text-mute-3">
            © {new Date().getFullYear()} GaitGuardAI · MIT
          </p>
        </div>
      </footer>
    </>
  );
}
