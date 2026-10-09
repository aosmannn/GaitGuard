import type { Metadata } from "next";
import { Button } from "@/components/Button";
import { Cite } from "@/components/Cite";
import { Reveal } from "@/components/Reveal";
import { PageHero } from "@/components/SiteChrome";

export const metadata: Metadata = {
  title: "How it works",
  description: "How GaitGuard calibrates to your walk, detects freezing on Apple Watch, delivers rhythmic haptic cues and syncs with iPhone.",
};

const stages = [
  {
    title: "Calibrate to your walk",
    body: "Before the first session you walk at your normal pace for 30 seconds. GaitGuard records how your wrist moves and sets its detection threshold from your own average and variation, instead of a one-size-fits-all number. You can start calibration from the Watch or from the iPhone.",
    why: "Gait differs a lot from person to person, so thresholds work better when they start from your baseline.",
  },
  {
    title: "Monitor quietly",
    body: "During a session the Watch reads its accelerometer and gyroscope 50 times a second. A workout session keeps monitoring running when the screen sleeps, and steps, cadence and distance come from the Watch's pedometer.",
    why: "Freezes are brief and unpredictable, so the sensing has to be continuous and on the body.",
    cite: ["bachlin2010"],
  },
  {
    title: "Detect a stall",
    body: "GaitGuard looks for two patterns: a start that stalls, and a turn where the wrist rotates but forward motion drops. Detection is simple, transparent motion math that runs entirely on the Watch. There's no AI, and nothing leaves your devices.",
    why: "Starting and turning are among the most common moments for freezing.",
    cite: ["nutt2011"],
  },
  {
    title: "Cue with a rhythm",
    body: "When a stall is detected, the Watch taps a short run of evenly spaced beats on your wrist: four beats at 100 per minute by default. You choose the tempo, number of beats, haptic style and strength. A short cooldown avoids buzzing you over and over.",
    why: "External rhythmic cues are a well-studied strategy for improving stepping in Parkinson's, and a vibrating wrist cue was one of the options in the RESCUE home cueing trial.",
    cite: ["spaulding2013", "nieuwboer2007"],
  },
  {
    title: "Sync to iPhone, live",
    body: "Every start, stop, cue, step count and score update reaches the iPhone within a moment over Apple's WatchConnectivity. If the devices are apart, changes queue on the Watch and land as soon as they reconnect, so nothing is lost.",
    why: "Care partners can follow a walk, and you can start, stop or adjust cueing without reaching for your wrist.",
  },
  {
    title: "Review and share",
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
        title={<>From a stalled step to a <span className="serif">steady beat.</span></>}
        intro="GaitGuard runs on Apple Watch, where the freeze happens, and mirrors everything to iPhone. Here is exactly what it does at each step, and why."
      />

      <section className="section !pt-10">
        <div className="wrap">
          <ol className="relative">
            <span className="absolute bottom-0 left-[1.15rem] top-2 hidden w-px bg-gradient-to-b from-ember/60 via-bone/15 to-transparent md:block" aria-hidden="true" />
            {stages.map((s, i) => (
              <Reveal as="li" key={s.title} className="relative grid gap-5 py-10 md:grid-cols-[3.6rem_1.4fr_1fr] md:gap-10">
                <span className="num relative z-10 flex h-[2.3rem] w-[2.3rem] items-center justify-center rounded-full border border-ember/60 bg-char text-[1rem] text-ember">{i + 1}</span>
                <div>
                  <h2 className="display !text-[clamp(1.8rem,3.2vw,2.5rem)]">{s.title}</h2>
                  <p className="mt-4 text-[1.05rem] leading-relaxed text-ash">{s.body}</p>
                </div>
                <div className="self-start rounded-2xl border border-bone/10 bg-hearth p-6">
                  <p className="label !text-ember">Why</p>
                  <p className="mt-3 text-[0.98rem] leading-relaxed text-ink-2">
                    {s.why}
                    {s.cite && <Cite ids={s.cite} />}
                  </p>
                </div>
              </Reveal>
            ))}
          </ol>
        </div>
      </section>

      <section className="section">
        <div className="wrap">
          <Reveal className="grid gap-8 rounded-[24px] border border-bone/10 bg-hearth p-8 sm:p-12 lg:grid-cols-2">
            <div>
              <p className="eyebrow">About the gait score</p>
              <h2 className="display mt-4 !text-[clamp(1.8rem,3vw,2.5rem)]">A simple support indicator, not a clinical measure.</h2>
            </div>
            <p className="text-[1.02rem] leading-relaxed text-ash">
              The score starts at 100 each session. Each cue lowers it, and walking more steps gradually offsets that. It is a quick way to see how much support a walk needed, shown the same on Watch and iPhone. It isn&apos;t a validated assessment and shouldn&apos;t be used to judge your condition or change treatment.
            </p>
          </Reveal>
          <div className="mt-10 flex flex-wrap gap-3">
            <Button href="/research" arrow>See the research</Button>
            <Button href="/safety" variant="ghost">Safety & privacy</Button>
          </div>
        </div>
      </section>
    </>
  );
}
