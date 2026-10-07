import Link from "next/link";
import { Cite } from "@/components/Cite";
import { HeroDemo } from "@/components/HeroDemo";
import { Icon, icons } from "@/components/Icon";
import { Reveal } from "@/components/Reveal";
import { RhythmTrainer } from "@/components/RhythmTrainer";
import { REPO } from "@/components/SiteChrome";
import { SyncPlayground } from "@/components/SyncPlayground";

const steps = [
  {
    n: "01",
    title: "Senses the stall",
    body: "Apple Watch reads wrist motion 50 times a second and spots a start or a turn that stops turning into steps.",
    icon: icons.pulse,
  },
  {
    n: "02",
    title: "Taps out a rhythm",
    body: "A short run of evenly spaced haptic beats, at a tempo you choose, gives your next step something to follow.",
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
  { title: "Tuned to your walk", body: "A 30-second calibration walk sets detection to your own baseline, not an average.", icon: icons.target },
  { title: "A rhythm you set", body: "Choose the tempo, number of beats, haptic style and strength of every cue.", icon: icons.wave },
  { title: "Always in sync", body: "Start, stop, score and cue history match on Watch and iPhone, within a moment.", icon: icons.sync },
  { title: "Works in the background", body: "Monitoring keeps running when the Watch screen sleeps, like a workout does.", icon: icons.moon },
  { title: "Control from your phone", body: "A care partner can start, stop, test or adjust cueing without touching the Watch.", icon: icons.sliders },
  { title: "Private by design", body: "No account and no cloud. Your history stays on your own Watch and iPhone.", icon: icons.lock },
];

const faqs = [
  ["Is GaitGuard a medical device?", "No. It's a cueing aid and a prototype. It doesn't diagnose, treat or prevent any condition, detect falls, or contact emergency services."],
  ["What do I need?", "An iPhone on iOS 17 or later and a paired Apple Watch on watchOS 10 or later. Detection and cueing run on the Watch; the iPhone is the companion."],
  ["Does it work away from my iPhone?", "Yes. The Watch detects and cues on its own. When the two reconnect, history and settings catch up automatically."],
  ["Does GaitGuard use AI?", "No. Detection uses your own calibration walk and simple, transparent motion thresholds that run entirely on the Watch."],
  ["When can I get it?", "An App Store release is on the way. The project is open source on GitHub today."],
];

export default function HomePage() {
  return (
    <>
      {/* Hero */}
      <section className="relative overflow-hidden">
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
            <h1 className="display rise rise-1 mt-7 text-[clamp(2.9rem,6.6vw,5.2rem)]">
              Keep the beat when your steps <span className="serif brand-grad pr-1">stall.</span>
            </h1>
            <p className="rise rise-2 mt-7 max-w-[30em] text-[1.12rem] leading-relaxed text-mute">
              GaitGuard notices a freeze on your wrist and answers with a steady, rhythmic tap, built on decades of research into cueing. Your iPhone mirrors every moment, live.
            </p>
            <div className="rise rise-3 mt-9 flex flex-col gap-3 sm:flex-row">
              <span className="btn btn-ink" aria-disabled="true">
                <svg viewBox="0 0 24 24" className="h-5 w-5" fill="currentColor" aria-hidden="true">
                  <path d="M16.4 12.6c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.8-1.4-.1-2.8.9-3.5.9-.7 0-1.8-.8-3-.8-1.5 0-3 .9-3.8 2.3-1.6 2.8-.4 7 1.2 9.3.8 1.1 1.7 2.4 2.9 2.3 1.2 0 1.6-.7 3-.7s1.8.7 3 .7c1.3 0 2.1-1.1 2.8-2.3.9-1.3 1.3-2.5 1.3-2.6 0 0-2.5-1-2.5-3.8zM14.1 5.8c.6-.8 1.1-1.9 1-3-1 0-2.1.7-2.8 1.4-.6.7-1.1 1.8-1 2.9 1.1.1 2.1-.5 2.8-1.3z" />
                </svg>
                Coming soon to the App Store
              </span>
              <Link href="/how-it-works" className="btn btn-ghost">
                See how it works
              </Link>
            </div>
            <ul className="rise rise-4 mt-10 flex flex-wrap gap-x-7 gap-y-2 text-[0.85rem] text-mute">
              <li className="flex items-center gap-2"><Icon d={icons.lock} className="h-4 w-4" /> No account, no cloud</li>
              <li className="flex items-center gap-2"><Icon d={icons.sync} className="h-4 w-4" /> Real-time Watch ↔ iPhone</li>
              <li className="flex items-center gap-2"><Icon d={icons.book} className="h-4 w-4" /> Research-informed</li>
            </ul>
          </div>
          <div className="rise rise-2 -mb-[120px] origin-top scale-[0.78] sm:mb-0 sm:scale-100">
            <HeroDemo />
          </div>
        </div>
      </section>

      {/* The problem, with evidence */}
      <section className="border-y border-line bg-card">
        <div className="wrap grid gap-12 py-[clamp(72px,9vw,128px)] lg:grid-cols-[1.3fr_1fr] lg:items-end">
          <Reveal>
            <p className="eyebrow">The moment it&apos;s for</p>
            <p className="mt-6 text-[clamp(1.6rem,3.1vw,2.5rem)] font-medium leading-[1.2] tracking-[-0.025em] text-ink-2">
              A freeze can feel like your feet are <span className="serif text-ink">glued to the floor</span>, often on the first step, at a turn, or in a doorway.
              <Cite ids={["nutt2011"]} /> <span className="text-mute-2">An outside rhythm is one of the best-studied ways to help the next step come.</span>
              <Cite ids={["spaulding2013", "keus2014"]} />
            </p>
          </Reveal>
          <Reveal delay={120} className="grid gap-4 sm:grid-cols-2 lg:grid-cols-1">
            <div className="rounded-3xl bg-paper p-6">
              <p className="text-[2.6rem] font-semibold tracking-tight">47%</p>
              <p className="mt-1 text-[0.95rem] leading-relaxed text-mute">
                of 6,620 people with Parkinson&apos;s surveyed reported experiencing freezing.
                <Cite ids={["macht2007"]} />
              </p>
            </div>
            <div className="rounded-3xl bg-paper p-6">
              <p className="text-[2.6rem] font-semibold tracking-tight">Falls</p>
              <p className="mt-1 text-[0.95rem] leading-relaxed text-mute">
                Freezing is a well-documented risk factor for falls in Parkinson&apos;s, which is why fast, on-the-spot help matters.
                <Cite ids={["bloem2004"]} />
              </p>
            </div>
          </Reveal>
        </div>
      </section>

      {/* How it works teaser */}
      <section className="section">
        <div className="wrap">
          <Reveal className="flex flex-wrap items-end justify-between gap-6">
            <div className="max-w-2xl">
              <p className="eyebrow">How it works</p>
              <h2 className="h2 mt-4">
                Sense. Cue. <span className="serif text-mute-2">Understand.</span>
              </h2>
            </div>
            <Link href="/how-it-works" className="btn btn-ghost">
              The full walkthrough →
            </Link>
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

      {/* Rhythm trainer */}
      <section id="rhythm" className="section scroll-mt-16">
        <div className="wrap">
          <Reveal className="panel overflow-hidden p-7 sm:p-12">
            <div className="max-w-2xl">
              <p className="eyebrow">Try it</p>
              <h2 className="h2 mt-4">
                Feel the <span className="serif brand-grad">rhythm.</span>
              </h2>
              <p className="mt-5 text-[1.05rem] leading-relaxed text-mute">
                This is the idea behind every cue. Pick a tempo, press start, and try stepping in time.
              </p>
            </div>
            <div className="mt-12">
              <RhythmTrainer />
            </div>
          </Reveal>
        </div>
      </section>

      {/* Sync playground */}
      <section id="sync" className="section scroll-mt-16">
        <div className="relative overflow-hidden bg-night text-white">
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
                Start on either device, then simulate a freeze. Everything mirrors instantly, just like the real apps.
              </p>
            </Reveal>
            <div className="mt-16">
              <SyncPlayground />
            </div>
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="section">
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

      {/* Research teaser */}
      <section className="section">
        <div className="wrap">
          <Reveal className="grid gap-8 rounded-[32px] bg-gradient-to-br from-indigo to-violet p-8 text-white sm:p-12 lg:grid-cols-[1.3fr_1fr] lg:items-center">
            <div>
              <p className="eyebrow !text-white/70">The evidence</p>
              <h2 className="mt-4 text-[clamp(1.8rem,3.4vw,2.8rem)] font-semibold leading-[1.06] tracking-[-0.03em]">
                Every feature traces back to published research.
              </h2>
              <p className="mt-4 max-w-[34em] text-[1.02rem] leading-relaxed text-white/80">
                What freezing is, why rhythm helps, why it belongs on the wrist and on demand, and what we still don&apos;t know.
              </p>
            </div>
            <div className="lg:justify-self-end">
              <Link href="/research" className="btn bg-white text-ink hover:-translate-y-px">
                Read the research →
              </Link>
            </div>
          </Reveal>
        </div>
      </section>

      {/* FAQ */}
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
                  <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full border border-line text-mute transition group-open:rotate-45 group-open:border-ink group-open:text-ink" aria-hidden="true">
                    +
                  </span>
                </summary>
                <p className="mt-3 max-w-[40em] text-[1rem] leading-relaxed text-mute">{a}</p>
              </details>
            ))}
          </Reveal>
        </div>
      </section>

      {/* CTA */}
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
                <Link href="/safety" className="btn border border-white/20 text-white hover:border-white/50">
                  Safety & privacy
                </Link>
              </div>
            </div>
          </Reveal>
        </div>
      </section>
    </>
  );
}
