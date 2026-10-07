import type { Metadata } from "next";
import Link from "next/link";
import { Cite } from "@/components/Cite";
import { Icon, icons } from "@/components/Icon";
import { Reveal } from "@/components/Reveal";
import { PageHero } from "@/components/SiteChrome";

export const metadata: Metadata = {
  title: "How it works",
  description: "How GaitGuard calibrates to your walk, detects freezing on Apple Watch, delivers rhythmic haptic cues and syncs with iPhone.",
};

const stages = [
  {
    icon: icons.target,
    title: "1. Calibrate to your walk",
    body: "Before the first session, you walk at your normal pace for 30 seconds. GaitGuard records how your wrist moves and sets its detection threshold from your own average and variation, instead of a one-size-fits-all number. You can start calibration from the Watch or from the iPhone.",
    why: "Gait differs a lot from person to person, so thresholds work better when they start from your baseline.",
  },
  {
    icon: icons.watch,
    title: "2. Monitor quietly",
    body: "During a session the Watch reads its accelerometer and gyroscope 50 times a second. A workout session keeps monitoring running when the screen sleeps, and steps, cadence and distance come from the Watch's pedometer.",
    why: "Freezes are brief and unpredictable, so the sensing has to be continuous and on the body.",
    cite: ["bachlin2010"],
  },
  {
    icon: icons.pulse,
    title: "3. Detect a stall",
    body: "GaitGuard looks for two patterns: a start that stalls, and a turn where the wrist rotates but forward motion drops. Detection is simple, transparent motion math that runs entirely on the Watch. There's no AI and nothing leaves your devices.",
    why: "Starting and turning are among the most common moments for freezing.",
    cite: ["nutt2011"],
  },
  {
    icon: icons.wave,
    title: "4. Cue with a rhythm",
    body: "When a stall is detected, the Watch taps a short run of evenly spaced beats on your wrist (four beats at 100 per minute by default). You choose the tempo, number of beats, haptic style and strength. A short cooldown avoids buzzing you over and over.",
    why: "External rhythmic cues are a well-studied strategy for improving stepping in Parkinson's, and a vibrating wrist cue was one of the options in the RESCUE home cueing trial.",
    cite: ["spaulding2013", "nieuwboer2007"],
  },
  {
    icon: icons.sync,
    title: "5. Sync to iPhone in real time",
    body: "Every start, stop, cue, step count and score update reaches the iPhone within a moment over Apple's WatchConnectivity. If the devices are apart, changes queue on the Watch and land as soon as they reconnect, so nothing is lost.",
    why: "Care partners can follow a walk, and you can start, stop or adjust cueing without reaching for your wrist.",
  },
  {
    icon: icons.chart,
    title: "6. Review and share",
    body: "The iPhone keeps a day-by-day history of cues with strength and duration, daily notes, and trends: cues per day, time of day, and how this week compares to last. Export it as a spreadsheet for your clinician or physical therapist.",
    why: "Freezing often depends on time of day, medication timing and setting, so patterns are worth discussing with your care team.",
    cite: ["ginis2018"],
  },
];

export default function HowItWorksPage() {
  return (
    <>
      <PageHero
        eyebrow="How it works"
        title={<>From a stalled step to a <span className="serif brand-grad">steady beat.</span></>}
        intro="GaitGuard runs on Apple Watch, where the freeze happens, and mirrors everything to iPhone. Here's exactly what it does at each step, and why."
      />

      <section className="section">
        <div className="wrap">
          <ol className="relative grid gap-6">
            {stages.map((s, i) => (
              <Reveal as="li" key={s.title} delay={60} className="panel grid gap-6 p-7 sm:p-10 md:grid-cols-[auto_1fr_0.8fr] md:gap-10">
                <span className="flex h-14 w-14 items-center justify-center rounded-2xl bg-indigo/10 text-indigo">
                  <Icon d={s.icon} className="h-7 w-7" />
                </span>
                <div>
                  <h2 className="text-[1.5rem] font-semibold tracking-tight">{s.title}</h2>
                  <p className="mt-3 text-[1.02rem] leading-relaxed text-mute">{s.body}</p>
                </div>
                <div className="rounded-2xl bg-paper p-5">
                  <p className="text-[0.72rem] font-semibold uppercase tracking-[0.14em] text-indigo">Why</p>
                  <p className="mt-2 text-[0.95rem] leading-relaxed text-ink-2">
                    {s.why}
                    {s.cite && <Cite ids={s.cite} />}
                  </p>
                </div>
                <span className="sr-only">Step {i + 1} of {stages.length}</span>
              </Reveal>
            ))}
          </ol>
        </div>
      </section>

      <section className="section">
        <div className="wrap">
          <Reveal className="grid gap-8 rounded-[32px] border border-line bg-card p-8 sm:p-12 lg:grid-cols-[1fr_1fr]">
            <div>
              <p className="eyebrow">About the gait score</p>
              <h2 className="mt-4 text-[clamp(1.6rem,3vw,2.3rem)] font-semibold leading-[1.1] tracking-[-0.03em]">
                A simple daily support indicator, not a clinical measure.
              </h2>
            </div>
            <p className="text-[1rem] leading-relaxed text-mute">
              The score starts at 100 each session. Each cue lowers it, and walking more steps gradually offsets that. It&apos;s a quick way to see how much support a walk needed, shown the same on Watch and iPhone. It isn&apos;t a validated assessment and shouldn&apos;t be used to judge your condition or change treatment.
            </p>
          </Reveal>
          <div className="mt-10 flex flex-wrap gap-3">
            <Link href="/research" className="btn btn-ink">See the research →</Link>
            <Link href="/safety" className="btn btn-ghost">Safety & privacy</Link>
          </div>
        </div>
      </section>
    </>
  );
}
