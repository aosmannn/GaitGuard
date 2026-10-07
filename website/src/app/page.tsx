import Link from "next/link";
import { Cite } from "@/components/Cite";
import { PilotForm } from "@/components/PilotForm";
import { Scope } from "@/components/Scope";
import { Icon, icons } from "@/components/Icon";
import { Reveal } from "@/components/Reveal";
import { RhythmTrainer } from "@/components/RhythmTrainer";
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
    title: "Records the pattern",
    body: "Your iPhone mirrors the session live and keeps a timeline of every cue, so you and your care team can see what's changing.",
    icon: icons.chart,
  },
];

const spec = [
  ["Sensing", "Wrist accelerometer and gyroscope, sampled at 50 Hz on Apple Watch."],
  ["Detection", "Threshold-based and transparent. No machine learning, tuned by a 30-second calibration walk."],
  ["Cue", "2–8 evenly spaced haptic beats at 60–130 per minute. Style and strength are adjustable."],
  ["Sync", "Watch ↔ iPhone in real time over WatchConnectivity. Changes queue offline and catch up."],
  ["Background", "Runs as a workout session, so monitoring continues when the Watch screen sleeps."],
  ["Record", "Per-cue history with strength and duration, daily notes, trends, and CSV export."],
  ["Platform", "watchOS 10+ and iOS 17+. Detection and cueing run on the Watch alone."],
  ["Privacy", "No account, no cloud, no analytics. Data stays on your Watch and iPhone."],
];

const questions = [
  ["Does the cue arrive at the right moment?", "Too early feels like noise; too late misses the point. We want to know how detection feels on real walks."],
  ["Is the rhythm comfortable to follow?", "Tempo, number of beats and haptic style are all adjustable. Which settings do people settle on?"],
  ["Is the iPhone view useful?", "Does a care partner learn something from live status, history and trends, or is it clutter?"],
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
      <section className="relative overflow-hidden border-b border-line">
        <div className="paper-grid pointer-events-none absolute inset-0" aria-hidden="true" />
        <div className="wrap relative grid items-center gap-14 pb-20 pt-14 md:pt-20 lg:grid-cols-[1.1fr_1fr] lg:gap-12 lg:pb-24">
          <div>
            <p className="eyebrow rise">GaitGuard · wearable cueing prototype</p>
            <h1 className="display rise rise-1 mt-6 text-[clamp(2.6rem,5.2vw,4.5rem)]">
              A metronome for the moment your steps <span className="serif brand-grad pr-1">stop.</span>
            </h1>
            <p className="rise rise-2 mt-7 max-w-[31em] text-[1.12rem] leading-relaxed text-mute">
              People with Parkinson&apos;s can freeze mid-stride. GaitGuard watches your wrist for that stall and answers with a steady haptic rhythm, a cue studied for decades. We&apos;re testing whether it can work on a watch.
            </p>
            <div className="rise rise-3 mt-9 flex flex-col gap-3 sm:flex-row">
              <Link href="/pilot" className="btn btn-signal">Join the pilot</Link>
              <Link href="/how-it-works" className="btn btn-ghost">Read the method</Link>
            </div>
            <p className="rise rise-4 mono mt-8 text-[0.74rem] uppercase tracking-[0.1em] text-mute-2">
              Early prototype · not a medical device · App Store release planned
            </p>
          </div>
          <div className="rise rise-2">
            <Scope />
          </div>
        </div>
      </section>

      {/* Status strip */}
      <section className="border-b border-line bg-card" aria-label="Project status">
        <dl className="wrap grid grid-cols-2 divide-x divide-line md:grid-cols-4">
          {[
            ["Status", "Pilot testing open"],
            ["Platform", "Apple Watch + iPhone"],
            ["Detection", "On-device, no AI"],
            ["Your data", "Stays on your devices"],
          ].map(([k, v]) => (
            <div key={k} className="px-5 py-5 first:pl-0">
              <dt className="label">{k}</dt>
              <dd className="mono mt-1.5 text-[0.88rem] text-ink">{v}</dd>
            </div>
          ))}
        </dl>
      </section>

      {/* The problem, with evidence */}
      <section className="section">
        <div className="wrap grid gap-12 lg:grid-cols-[1.3fr_1fr] lg:items-end">
          <Reveal>
            <p className="eyebrow">01 · The problem</p>
            <p className="mt-6 text-[clamp(1.6rem,3.1vw,2.5rem)] font-medium leading-[1.2] tracking-[-0.025em] text-ink-2">
              A freeze can feel like your feet are <span className="serif text-ink">glued to the floor</span>, often on the first step, at a turn, or in a doorway.
              <Cite ids={["nutt2011"]} /> <span className="text-mute-2">An outside rhythm is one of the best-studied ways to help the next step come.</span>
              <Cite ids={["spaulding2013", "keus2014"]} />
            </p>
          </Reveal>
          <Reveal delay={120} className="grid gap-4 sm:grid-cols-2 lg:grid-cols-1">
            <div className="panel p-6">
              <p className="mono text-[2.6rem] font-medium tracking-tight">47%</p>
              <p className="mt-1 text-[0.95rem] leading-relaxed text-mute">
                of 6,620 people with Parkinson&apos;s surveyed reported experiencing freezing.
                <Cite ids={["macht2007"]} />
              </p>
            </div>
            <div className="panel p-6">
              <p className="mono text-[2.6rem] font-medium tracking-tight">Falls</p>
              <p className="mt-1 text-[0.95rem] leading-relaxed text-mute">
                Freezing is a well-documented risk factor for falls in Parkinson&apos;s, which is why fast, on-the-spot help matters.
                <Cite ids={["bloem2004"]} />
              </p>
            </div>
          </Reveal>
        </div>
      </section>

      {/* Method */}
      <section className="section">
        <div className="wrap">
          <Reveal className="flex flex-wrap items-end justify-between gap-6">
            <div className="max-w-2xl">
              <p className="eyebrow">02 · Method</p>
              <h2 className="h2 mt-4">
                Sense. Cue. <span className="serif text-mute-2">Record.</span>
              </h2>
            </div>
            <Link href="/how-it-works" className="btn btn-ghost">Full method →</Link>
          </Reveal>
          <ol className="mt-12 grid border-y border-line md:grid-cols-3 md:divide-x md:divide-line">
            {steps.map((s, i) => (
              <Reveal as="li" key={s.n} delay={i * 90} className="py-8 md:px-8 md:first:pl-0 md:last:pr-0">
                <div className="flex items-center justify-between">
                  <span className="mono text-[0.8rem] text-indigo">{s.n}</span>
                  <Icon d={s.icon} className="h-6 w-6 text-mute-2" />
                </div>
                <h3 className="mt-8 text-[1.3rem] font-semibold tracking-tight">{s.title}</h3>
                <p className="mt-3 text-[1rem] leading-relaxed text-mute">{s.body}</p>
              </Reveal>
            ))}
          </ol>
        </div>
      </section>

      {/* Spec sheet */}
      <section className="section">
        <div className="wrap grid gap-12 lg:grid-cols-[0.8fr_1.4fr]">
          <Reveal>
            <p className="eyebrow">03 · Spec sheet</p>
            <h2 className="h2 mt-4">What&apos;s in the prototype.</h2>
            <p className="mt-5 max-w-[24em] text-[1.02rem] leading-relaxed text-mute">
              Plain facts about what it senses, how it decides, and where your data lives.
            </p>
          </Reveal>
          <Reveal delay={100}>
            <dl className="border-t border-ink/80">
              {spec.map(([k, v]) => (
                <div key={k} className="grid gap-1 border-b border-line py-4 sm:grid-cols-[9rem_1fr] sm:gap-6">
                  <dt className="label pt-1 !text-ink-2">{k}</dt>
                  <dd className="text-[0.98rem] leading-relaxed text-ink-2">{v}</dd>
                </div>
              ))}
            </dl>
          </Reveal>
        </div>
      </section>

      {/* Rhythm trainer */}
      <section id="rhythm" className="section scroll-mt-24">
        <div className="wrap">
          <Reveal className="panel overflow-hidden p-7 sm:p-12">
            <div className="max-w-2xl">
              <p className="eyebrow">04 · Try it</p>
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
      <section id="sync" className="section scroll-mt-24">
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
              <p className="eyebrow !text-indigo-soft">05 · Companion</p>
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

      {/* Pilot */}
      <section id="pilot" className="section scroll-mt-24">
        <div className="wrap grid gap-12 lg:grid-cols-[1fr_1.1fr]">
          <Reveal>
            <p className="eyebrow">06 · Pilot program</p>
            <h2 className="h2 mt-4">
              Help us find out if it <span className="serif brand-grad">works.</span>
            </h2>
            <p className="mt-5 max-w-[30em] text-[1.05rem] leading-relaxed text-mute">
              GaitGuard is early. We&apos;re looking for people with Parkinson&apos;s, care partners and clinicians to try it and tell us honestly what helps and what doesn&apos;t.
            </p>
            <ol className="mt-10 grid gap-6">
              {questions.map(([q, a], i) => (
                <li key={q} className="grid grid-cols-[2.2rem_1fr] gap-3">
                  <span className="mono text-[0.8rem] text-indigo">Q{i + 1}</span>
                  <div>
                    <h3 className="text-[1.05rem] font-semibold tracking-tight">{q}</h3>
                    <p className="mt-1 text-[0.95rem] leading-relaxed text-mute">{a}</p>
                  </div>
                </li>
              ))}
            </ol>
            <p className="mt-8 text-[0.85rem] leading-relaxed text-mute-2">
              This is an informal product pilot, not a clinical trial. See <Link href="/pilot" className="underline underline-offset-4 hover:text-ink">what taking part involves</Link>.
            </p>
          </Reveal>
          <Reveal delay={100} className="panel p-7 sm:p-9">
            <h3 className="text-[1.35rem] font-semibold tracking-tight">Join the pilot</h3>
            <p className="mb-7 mt-2 text-[0.95rem] text-mute">Takes a minute. We&apos;ll only email you about the pilot.</p>
            <PilotForm />
          </Reveal>
        </div>
      </section>

      {/* Evidence teaser */}
      <section className="section">
        <div className="wrap">
          <Reveal className="grid gap-8 rounded-[22px] bg-ink p-8 text-white sm:p-12 lg:grid-cols-[1.3fr_1fr] lg:items-center">
            <div>
              <p className="eyebrow !text-cue-soft">The evidence</p>
              <h2 className="mt-4 text-[clamp(1.8rem,3.4vw,2.8rem)] font-semibold leading-[1.06] tracking-[-0.03em]">
                Every feature traces back to published research.
              </h2>
              <p className="mt-4 max-w-[34em] text-[1.02rem] leading-relaxed text-white/70">
                What freezing is, why rhythm helps, why it belongs on the wrist, and what we still don&apos;t know.
              </p>
            </div>
            <div className="lg:justify-self-end">
              <Link href="/research" className="btn bg-white text-ink hover:-translate-y-px">Read the research →</Link>
            </div>
          </Reveal>
        </div>
      </section>

      {/* FAQ */}
      <section id="faq" className="section scroll-mt-24 pb-[var(--section)]">
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
                  <span className="mono flex h-8 w-8 shrink-0 items-center justify-center rounded-[8px] border border-line text-mute transition group-open:rotate-45 group-open:border-ink group-open:text-ink" aria-hidden="true">
                    +
                  </span>
                </summary>
                <p className="mt-3 max-w-[40em] text-[1rem] leading-relaxed text-mute">{a}</p>
              </details>
            ))}
          </Reveal>
        </div>
      </section>
    </>
  );
}
