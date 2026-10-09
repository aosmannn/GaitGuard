import type { Metadata } from "next";
import { Cite } from "@/components/Cite";
import { Reveal } from "@/components/Reveal";
import { PageHero } from "@/components/SiteChrome";
import { references, refUrl } from "@/lib/research";

export const metadata: Metadata = {
  title: "Research",
  description: "The published evidence behind GaitGuard: what freezing of gait is, why rhythmic cueing helps, why on-demand wrist cues, and what is still unknown.",
};

const sections = [
  {
    eyebrow: "01 · The problem",
    title: "What freezing of gait is",
    body: (
      <>
        Freezing of gait is a brief, episodic inability to move the feet forward despite the intention to walk. It most often strikes when starting to walk, turning, approaching a doorway or a narrow space, or under time pressure, and it can feel as though the feet are stuck to the floor.
        <Cite ids={["nutt2011"]} /> In a survey of 6,620 people with Parkinson&apos;s, 47% reported freezing.
        <Cite ids={["macht2007"]} /> Freezing is closely linked with falls, which makes it one of the most disabling symptoms of the disease.
        <Cite ids={["bloem2004"]} />
      </>
    ),
    app: "GaitGuard focuses on the two moments research highlights most: starting and turning.",
  },
  {
    eyebrow: "02 · The approach",
    title: "Why an outside rhythm helps",
    body: (
      <>
        &ldquo;Cueing&rdquo; means giving the brain an external signal to time each step to, such as a beat, a line on the floor, or a tap. A meta-analysis of cueing studies found that rhythmic auditory cues improved walking speed, stride length and cadence in people with Parkinson&apos;s.
        <Cite ids={["spaulding2013"]} /> The European Physiotherapy Guideline for Parkinson&apos;s recommends cueing strategies as part of gait training.
        <Cite ids={["keus2014"]} /> In the RESCUE trial, three weeks of home cueing training improved gait and posture, with a modest reduction in freezing severity. Participants could choose an auditory, visual, or vibrating wristband cue.
        <Cite ids={["nieuwboer2007"]} />
      </>
    ),
    app: "Every GaitGuard cue is a rhythm: evenly spaced beats at a tempo you pick, close to your natural cadence.",
  },
  {
    eyebrow: "03 · The design",
    title: "Why on the wrist, and only when needed",
    body: (
      <>
        Continuous cueing can become tiring, and people may come to rely on it. Researchers have therefore explored on-demand cueing, where a wearable detects a freeze and delivers a cue only at that moment.
        <Cite ids={["bachlin2010", "ginis2018"]} /> Early systems used body-worn motion sensors to detect freezes in real time and trigger a cue.
        <Cite ids={["bachlin2010"]} /> A haptic cue on the wrist is private and silent, works in noisy places, and doesn&apos;t require headphones.
      </>
    ),
    app: "GaitGuard uses the Apple Watch's built-in motion sensors to cue on demand, with a cooldown so it doesn't buzz constantly.",
  },
  {
    eyebrow: "04 · The context",
    title: "Why patterns matter",
    body: (
      <>
        Freezing varies with medication timing, attention, environment and fatigue, so the same person may freeze often one day and rarely the next.
        <Cite ids={["nutt2011", "ginis2018"]} /> Tracking when and where freezes happen gives people and clinicians something concrete to discuss.
      </>
    ),
    app: "GaitGuard's history, daily notes, time-of-day trends and CSV export are built for exactly that conversation.",
  },
];

export default function ResearchPage() {
  return (
    <>
      <PageHero
        eyebrow="Research"
        title={<>Built on what&apos;s <span className="serif brand-grad">known.</span> Honest about what isn&apos;t.</>}
        intro="GaitGuard didn't invent rhythmic cueing. It puts a well-studied idea on the wrist and makes it automatic. Here's the evidence each part of the app is based on."
      />

      <section className="section">
        <div className="wrap grid gap-6">
          {sections.map((s) => (
            <Reveal key={s.title} className="panel grid gap-8 p-7 sm:p-10 lg:grid-cols-[1.5fr_1fr] lg:gap-12">
              <div>
                <p className="eyebrow">{s.eyebrow}</p>
                <h2 className="mt-3 text-[clamp(1.5rem,2.6vw,2rem)] font-semibold tracking-[-0.025em]">{s.title}</h2>
                <p className="mt-4 text-[1.02rem] leading-[1.75] text-ink-2">{s.body}</p>
              </div>
              <div className="self-start rounded-2xl bg-indigo/[0.07] p-6">
                <p className="text-[0.72rem] font-semibold uppercase tracking-[0.14em] text-indigo">In GaitGuard</p>
                <p className="mt-2 text-[1rem] leading-relaxed text-ink-2">{s.app}</p>
              </div>
            </Reveal>
          ))}

          <Reveal className="rounded-2xl border border-cue/30 bg-[#fff8ea] p-7 sm:p-10">
            <p className="eyebrow !text-[#a8620a]">05 · The limits</p>
            <h2 className="mt-3 text-[clamp(1.5rem,2.6vw,2rem)] font-semibold tracking-[-0.025em]">What we don&apos;t know yet</h2>
            <ul className="mt-5 grid gap-4 text-[1rem] leading-relaxed text-ink-2 md:grid-cols-2">
              <li><strong className="font-semibold">GaitGuard itself hasn&apos;t been clinically tested.</strong> The research above supports the approach, not this specific app.</li>
              <li><strong className="font-semibold">Detection isn&apos;t perfect.</strong> Wrist-only sensing will miss some freezes and occasionally cue when you don&apos;t need it. Calibration and sensitivity settings help.</li>
              <li><strong className="font-semibold">Most cueing evidence is auditory.</strong> Vibrating (haptic) cues are less studied than sound-based ones.</li>
              <li><strong className="font-semibold">Cueing works best with training.</strong> Studies pair cues with strategies taught by physical therapists. Use GaitGuard alongside that care, not instead of it.<Cite ids={["keus2014"]} /></li>
            </ul>
          </Reveal>
        </div>
      </section>

      <section id="references" className="section scroll-mt-20 pb-[var(--section)]">
        <div className="wrap max-w-[900px]">
          <h2 className="text-[1.6rem] font-semibold tracking-tight">References</h2>
          <ol className="mt-8 grid gap-5">
            {references.map((r, i) => (
              <li key={r.id} id={`ref-${r.id}`} className="grid scroll-mt-24 grid-cols-[2rem_1fr] text-[0.95rem] leading-relaxed target:rounded-xl target:bg-indigo/10">
                <span className="text-mute-2">{i + 1}.</span>
                <span className="text-mute">
                  {r.authors}. <a href={refUrl(r)} target="_blank" rel="noopener noreferrer" className="font-medium text-ink underline decoration-line underline-offset-4 hover:decoration-indigo">{r.title}</a>. <em>{r.source}</em>, {r.year}.
                </span>
              </li>
            ))}
          </ol>
          <p className="mt-8 text-[0.85rem] text-mute-2">Links open a PubMed search for each title. This page summarizes research for general information and isn&apos;t medical advice.</p>
        </div>
      </section>
    </>
  );
}
