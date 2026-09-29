import { PhoneMock, WatchMock } from "@/components/DeviceMocks";

const features = [
  {
    title: "Freeze detection",
    body: "Senses start and turn attempts without step cadence, then cues before hesitation deepens.",
  },
  {
    title: "Rhythmic haptics",
    body: "Metronome-style Watch pulses tailored for walking initiation versus turning.",
  },
  {
    title: "Live companion",
    body: "iPhone dashboard streams steps, cadence, distance, and an event timeline.",
  },
  {
    title: "Remote control",
    body: "Tune sensitivity, pattern, and intensity from the phone without interrupting the walk.",
  },
  {
    title: "Personal calibration",
    body: "A short walk sets your baseline so thresholds fit your gait, not a generic model.",
  },
  {
    title: "Background monitoring",
    body: "HealthKit workout sessions keep tracking active when the Watch screen sleeps.",
  },
];

const audience = [
  "A foot that sticks when starting to walk",
  "Turns that feel stuck or unsafe alone",
  "Festination — speeding up or leaning forward",
  "People exploring rhythmic cueing with a clinician or PT",
];

const steps = [
  {
    device: "Watch",
    title: "Sense the freeze",
    body: "Core Motion samples motion at ~50 Hz. When intent shows up without cadence, GaitGuardAI flags a freeze moment.",
  },
  {
    device: "Watch",
    title: "Deliver the cue",
    body: "Rhythmic haptic pulses help re-initiate stepping — different rhythms for starts and turns.",
  },
  {
    device: "iPhone",
    title: "Review & adjust",
    body: "See live metrics, event history, and analytics. Change settings remotely while the Watch keeps cueing.",
  },
];

export default function HomePage() {
  return (
    <>
      <a
        href="#main"
        className="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-4 focus:z-50 focus:rounded-lg focus:bg-teal focus:px-3 focus:py-2 focus:text-bg-deep"
      >
        Skip to content
      </a>

      <header className="sticky top-0 z-40 border-b border-border/80 bg-bg-deep/70 backdrop-blur-xl">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-5 sm:px-8">
          <a href="#top" className="group flex items-center gap-2.5">
            <span className="flex h-8 w-8 items-center justify-center rounded-xl bg-teal-dim ring-1 ring-teal/30">
              <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden>
                <path
                  d="M3 11c2-4 4-6 5-6s3 2 5 6"
                  stroke="#2edeb8"
                  strokeWidth="1.6"
                  strokeLinecap="round"
                />
                <circle cx="8" cy="4.5" r="1.4" fill="#2edeb8" />
              </svg>
            </span>
            <span className="font-display text-[15px] font-semibold tracking-tight text-text">
              GaitGuard<span className="text-teal">AI</span>
            </span>
          </a>
          <nav className="hidden items-center gap-7 text-sm text-muted md:flex" aria-label="Primary">
            <a href="#how" className="transition hover:text-text">
              How it works
            </a>
            <a href="#features" className="transition hover:text-text">
              Features
            </a>
            <a href="#safety" className="transition hover:text-text">
              Safety
            </a>
            <a href="#cta" className="transition hover:text-text">
              Get started
            </a>
          </nav>
          <a
            href="https://github.com/aosmannn/GaitGuard"
            target="_blank"
            rel="noopener noreferrer"
            className="rounded-full border border-border bg-white/[0.03] px-3.5 py-1.5 text-sm text-soft transition hover:border-border-strong hover:text-text"
          >
            GitHub
          </a>
        </div>
      </header>

      <main id="main">
        {/* Hero */}
        <section
          id="top"
          className="relative overflow-hidden px-5 pb-20 pt-14 sm:px-8 sm:pb-28 sm:pt-20"
        >
          <div className="pointer-events-none absolute inset-x-0 top-0 h-[520px] bg-[radial-gradient(ellipse_at_center,rgba(46,222,184,0.08),transparent_60%)]" />
          <div className="relative mx-auto grid max-w-6xl items-center gap-14 lg:grid-cols-[1.05fr_0.95fr] lg:gap-10">
            <div>
              <p className="animate-fade-up font-display text-3xl font-semibold tracking-tight text-text sm:text-5xl sm:leading-[1.08]">
                GaitGuard<span className="text-teal">AI</span>
              </p>
              <h1 className="animate-fade-up-delay-1 mt-4 max-w-xl font-display text-2xl font-medium leading-snug text-soft sm:text-3xl">
                Rhythmic haptic cueing when walking freezes.
              </h1>
              <p className="animate-fade-up-delay-2 mt-5 max-w-lg text-base leading-relaxed text-muted sm:text-lg">
                An Apple Watch + iPhone companion that detects freezing-of-gait
                moments and helps you re-initiate with metronome-style pulses.
              </p>
              <div className="animate-fade-up-delay-3 mt-8 flex flex-wrap items-center gap-3">
                <span className="inline-flex items-center rounded-full bg-teal px-5 py-2.5 text-sm font-semibold text-bg-deep">
                  Coming soon on the App Store
                </span>
                <a
                  href="https://github.com/aosmannn/GaitGuard"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center rounded-full border border-border px-5 py-2.5 text-sm font-medium text-soft transition hover:border-border-strong hover:text-text"
                >
                  View on GitHub
                </a>
              </div>
              <p className="mt-6 max-w-md text-xs leading-relaxed text-muted/90">
                Not a medical device — use with supervision. A cueing aid and
                prototype, not a substitute for clinical care.
              </p>
            </div>

            <div className="relative flex min-h-[340px] items-end justify-center gap-4 sm:min-h-[400px]">
              <div className="absolute inset-0 -z-10 rounded-[40%] bg-[radial-gradient(circle,rgba(46,222,184,0.1),transparent_65%)] blur-2xl" />
              <div className="translate-y-6 scale-90 sm:translate-y-8 sm:scale-95">
                <PhoneMock />
              </div>
              <div className="absolute right-[6%] top-2 z-10 sm:right-[10%] sm:top-0">
                <WatchMock />
              </div>
            </div>
          </div>
        </section>

        {/* How it works */}
        <section id="how" className="scroll-mt-24 px-5 py-20 sm:px-8 sm:py-28">
          <div className="mx-auto max-w-6xl">
            <div className="max-w-2xl">
              <p className="text-sm font-medium tracking-wide text-teal">
                How it works
              </p>
              <h2 className="mt-3 font-display text-3xl font-semibold tracking-tight text-text sm:text-4xl">
                Watch senses. Phone clarifies.
              </h2>
              <p className="mt-4 text-base leading-relaxed text-muted sm:text-lg">
                Detection and cueing live on the wrist. Analytics and remote
                control stay on the iPhone — so walks stay simple.
              </p>
            </div>

            <ol className="mt-14 grid gap-8 md:grid-cols-3">
              {steps.map((step, i) => (
                <li key={step.title} className="relative">
                  <div className="mb-4 flex items-center gap-3">
                    <span className="font-display text-sm font-semibold text-teal">
                      0{i + 1}
                    </span>
                    <span className="rounded-full border border-border px-2.5 py-0.5 text-[11px] uppercase tracking-wider text-muted">
                      {step.device}
                    </span>
                  </div>
                  <h3 className="font-display text-xl font-semibold text-text">
                    {step.title}
                  </h3>
                  <p className="mt-3 text-sm leading-relaxed text-muted sm:text-[15px]">
                    {step.body}
                  </p>
                </li>
              ))}
            </ol>

            <div className="mt-16 grid items-center gap-10 rounded-[28px] border border-border bg-bg-panel/50 p-6 sm:p-10 lg:grid-cols-2">
              <div>
                <h3 className="font-display text-2xl font-semibold text-text">
                  Built for the moments that stick
                </h3>
                <p className="mt-3 text-sm leading-relaxed text-muted sm:text-base">
                  Freezing often shows up at gait initiation and turning. GaitGuardAI
                  watches for movement intent without steps, then cues with a
                  rhythm you can feel — while the phone keeps a quiet record.
                </p>
              </div>
              <div className="flex justify-center gap-6 sm:gap-10">
                <WatchMock />
                <div className="hidden sm:block">
                  <PhoneMock />
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Features */}
        <section id="features" className="scroll-mt-24 px-5 py-20 sm:px-8 sm:py-28">
          <div className="mx-auto max-w-6xl">
            <div className="max-w-2xl">
              <p className="text-sm font-medium tracking-wide text-teal">
                Features
              </p>
              <h2 className="mt-3 font-display text-3xl font-semibold tracking-tight text-text sm:text-4xl">
                Cueing on the wrist. Clarity in your pocket.
              </h2>
            </div>
            <ul className="mt-14 grid gap-x-10 gap-y-12 sm:grid-cols-2 lg:grid-cols-3">
              {features.map((feature) => (
                <li key={feature.title}>
                  <div className="mb-3 h-px w-10 bg-teal/60" />
                  <h3 className="font-display text-lg font-semibold text-text">
                    {feature.title}
                  </h3>
                  <p className="mt-2 text-sm leading-relaxed text-muted">
                    {feature.body}
                  </p>
                </li>
              ))}
            </ul>
          </div>
        </section>

        {/* Audience */}
        <section id="audience" className="scroll-mt-24 px-5 py-20 sm:px-8 sm:py-28">
          <div className="mx-auto max-w-6xl">
            <div className="max-w-2xl">
              <p className="text-sm font-medium tracking-wide text-teal">
                Who it&apos;s for
              </p>
              <h2 className="mt-3 font-display text-3xl font-semibold tracking-tight text-text sm:text-4xl">
                People navigating gait freezes — with support nearby.
              </h2>
              <p className="mt-4 text-base leading-relaxed text-muted">
                Designed as a personal cueing aid for everyday walking challenges,
                ideally alongside guidance from a clinician or physical therapist.
              </p>
            </div>
            <ul className="mt-12 grid gap-4 sm:grid-cols-2">
              {audience.map((item) => (
                <li
                  key={item}
                  className="flex gap-3 border-l-2 border-teal/40 pl-4 text-soft"
                >
                  <span className="text-[15px] leading-relaxed">{item}</span>
                </li>
              ))}
            </ul>
          </div>
        </section>

        {/* Safety */}
        <section id="safety" className="scroll-mt-24 px-5 py-20 sm:px-8 sm:py-28">
          <div className="mx-auto max-w-6xl">
            <div className="glass glow-teal max-w-3xl rounded-3xl p-7 sm:p-10">
              <p className="text-sm font-medium tracking-wide text-teal">
                Safety &amp; disclaimer
              </p>
              <h2 className="mt-3 font-display text-2xl font-semibold text-text sm:text-3xl">
                Clear about what this is — and isn&apos;t.
              </h2>
              <ul className="mt-6 space-y-3 text-sm leading-relaxed text-soft sm:text-[15px]">
                <li>
                  <strong className="font-semibold text-text">
                    Not a medical device.
                  </strong>{" "}
                  GaitGuardAI is a cueing aid and prototype. It does not diagnose,
                  treat, or prevent disease.
                </li>
                <li>
                  Use with supervision before relying on it in high-risk
                  situations. Turning difficulty can increase fall risk.
                </li>
                <li>
                  Consider involving a clinician or PT. Rhythmic cueing works best
                  with taught strategies such as staged turns and weight shift.
                </li>
                <li>
                  The app does not detect falls or contact emergency services.
                </li>
              </ul>
            </div>
          </div>
        </section>

        {/* CTA */}
        <section id="cta" className="scroll-mt-24 px-5 pb-24 pt-8 sm:px-8 sm:pb-32">
          <div className="relative mx-auto max-w-6xl overflow-hidden rounded-[32px] border border-border-strong/50 bg-gradient-to-br from-bg-elevated via-bg-panel to-bg-deep px-7 py-14 sm:px-14 sm:py-16">
            <div className="pointer-events-none absolute -right-20 -top-20 h-64 w-64 rounded-full bg-teal/15 blur-3xl" />
            <div className="relative max-w-xl">
              <h2 className="font-display text-3xl font-semibold tracking-tight text-text sm:text-4xl">
                Walk with a quieter kind of confidence.
              </h2>
              <p className="mt-4 text-base leading-relaxed text-muted">
                App Store release is on the way. Star the repo, follow along, or
                build from source today.
              </p>
              <div className="mt-8 flex flex-wrap gap-3">
                <span className="inline-flex items-center rounded-full bg-teal px-5 py-2.5 text-sm font-semibold text-bg-deep">
                  Coming soon
                </span>
                <a
                  href="https://github.com/aosmannn/GaitGuard"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center rounded-full border border-white/15 bg-white/5 px-5 py-2.5 text-sm font-medium text-text transition hover:bg-white/10"
                >
                  github.com/aosmannn/GaitGuard
                </a>
              </div>
              <p className="mt-6 text-xs text-muted">
                Not a medical device — use with supervision.
              </p>
            </div>
          </div>
        </section>
      </main>

      <footer className="border-t border-border px-5 py-10 sm:px-8">
        <div className="mx-auto flex max-w-6xl flex-col gap-6 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p className="font-display text-sm font-semibold text-text">
              GaitGuard<span className="text-teal">AI</span>
            </p>
            <p className="mt-1 text-xs text-muted">
              Not a medical device — use with supervision.
            </p>
          </div>
          <div className="flex flex-wrap gap-5 text-sm text-muted">
            <a
              href="https://github.com/aosmannn/GaitGuard"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-text"
            >
              GitHub
            </a>
            <a href="#safety" className="hover:text-text">
              Safety
            </a>
            <a href="#features" className="hover:text-text">
              Features
            </a>
          </div>
          <p className="text-xs text-muted">
            © {new Date().getFullYear()} GaitGuardAI · MIT License
          </p>
        </div>
      </footer>
    </>
  );
}
