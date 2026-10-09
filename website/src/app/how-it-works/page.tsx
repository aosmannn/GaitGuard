import type { Metadata } from "next";
import { Button } from "@/components/Button";
import { Cite } from "@/components/Cite";
import { Reveal } from "@/components/Reveal";
import { PageHero } from "@/components/SiteChrome";

export const metadata: Metadata = {
  title: "How it works",
  description: "How GaitGuard learns your walk, responds when your walking stalls, and taps a steady rhythm on your wrist. In plain language, with an honest note on what hasn't been proven.",
};

const stages = [
  {
    title: "It learns your walk",
    body: "You start with a 30-second calibration walk. GaitGuard checks that you actually walked, measures your pace, and sets your own thresholds from it. It can also suggest a cue tempo that matches how you walk.",
    why: "People walk differently, so a personal baseline works better than one number for everyone.",
  },
  {
    title: "The Watch listens to your movement",
    body: "The Watch's motion sensor is read 50 times a second, with gravity removed. Every half second it studies the last three seconds and separates two kinds of movement: the steady rhythm of walking, and fast trembling.",
    why: "Freezing is brief and unpredictable, so the sensing has to be continuous and on the body.",
    cite: ["bachlin2010"],
  },
  {
    title: "It waits for walking first",
    body: "GaitGuard only treats something as a possible freeze if you were walking a moment ago, the walking rhythm has stopped, and trembling-like movement shows up for about a second and a half. It's designed so that gesturing, eating or sitting still shouldn't trigger it.",
    why: "Starting and stopping are common moments for freezing, but everyday movement shouldn't cause a cue.",
    cite: ["nutt2011"],
  },
  {
    title: "Turns are handled separately",
    body: "For turns, it only cues when you turn about 70 degrees and your stride slows down while you do. A smooth turn while you're still walking is ignored.",
    why: "Turning is one of the most common moments for freezing, and it's easy to cue too often if you aren't careful.",
    cite: ["nutt2011"],
  },
  {
    title: "The Watch taps a rhythm",
    body: "When it responds, the Watch plays a short run of haptic taps at your tempo: 100 beats per minute and four beats by default, all adjustable. If \"repeat while frozen\" is on, it repeats a few times while the freeze continues. Afterwards it measures how long the freeze lasted and updates your History.",
    why: "External rhythmic cues are a well-studied strategy for helping people with Parkinson's keep stepping.",
    cite: ["spaulding2013", "nieuwboer2007"],
  },
  {
    title: "It adapts to you",
    body: "After every cue you can tap a tick or a cross on your Watch: did it help? The app becomes slightly more or less sensitive from your answers. There are also modes: Everyday, Exercise (calmer), High alert (more sensitive, and it also cues when walking simply stalls) and Custom.",
    why: "You know your own walking best, so the app learns from you.",
  },
  {
    title: "The steadiness score",
    body: "The score you see on the dial is built from how regular your stride is and how much of the last ten minutes was spent frozen. It is not a count of cues.",
    why: "It's a quick way to see how a walk is going. It isn't a clinical measure.",
  },
  {
    title: "It looks after the battery",
    body: "The Watch warns you at 20% battery, and stops monitoring and tells you at 10%.",
    why: "A cue that can't arrive is worse than no cue, so you're told in advance.",
  },
];

export default function HowItWorksPage() {
  return (
    <>
      <PageHero
        eyebrow="How it works"
        title={<>How it responds when your walking <span className="serif">stalls.</span></>}
        intro="GaitGuard runs on your Apple Watch, where the walking happens, and mirrors everything to your iPhone. Here is what it does, step by step, in plain language."
      />

      <section className="section !pt-6">
        <div className="wrap">
          <Reveal className="rounded-[22px] border border-amber/30 bg-amber/[0.06] p-7 sm:p-9">
            <p className="eyebrow !text-amber">Honest status</p>
            <p className="mt-3 max-w-[48em] text-[1.08rem] leading-relaxed text-ink-2">
              The logic below is covered by automated tests on simulated signals. It has <strong className="font-bold text-bone">not been validated on real patients</strong>, and its real-world accuracy is unproven. GaitGuard can miss a freeze and can cue when it wasn&apos;t needed.
            </p>
          </Reveal>
        </div>
      </section>

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
          <div className="flex flex-wrap gap-3">
            <Button href="/app" arrow>See the app</Button>
            <Button href="/research" variant="ghost">The research</Button>
            <Button href="/safety" variant="ghost">Safety & privacy</Button>
          </div>
        </div>
      </section>
    </>
  );
}
