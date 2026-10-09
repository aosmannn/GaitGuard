import Link from "next/link";
import { Accordion } from "@/components/Accordion";
import { Button } from "@/components/Button";
import { Cite } from "@/components/Cite";
import { ParallaxPhones } from "@/components/DeviceShot";
import { PilotForm } from "@/components/PilotForm";
import { Reveal } from "@/components/Reveal";
import { ScrollWords } from "@/components/ScrollWords";
import { TickDial } from "@/components/TickDial";

const steps = [
  {
    n: "01",
    title: "Calibrate",
    body: "Walk for 30 seconds at your normal pace. GaitGuard learns your pace, sets thresholds from your own walk, and can suggest a cue tempo that matches how you walk.",
  },
  {
    n: "02",
    title: "Walk",
    body: "Start from your Watch or your phone and go about your day. When your walking stalls, the Watch responds. It works on its own, so your phone doesn't need to be with you.",
  },
  {
    n: "03",
    title: "Feel the beat",
    body: "A short run of gentle taps at your tempo gives your next step something to follow. Afterwards you tap a tick or a cross: did it help? GaitGuard adapts to your answers.",
  },
];

const features = [
  { title: "A rhythm on your wrist", body: "Choose the tempo (60 to 130 beats per minute), the number of beats, the haptic style and the strength." },
  { title: "Learns your walk", body: "A 30-second calibration walk measures your pace and sets a personal threshold, and can match the cue tempo to your walking pace." },
  { title: "Did it help?", body: "A thumbs up or down on the Watch after every cue. The app becomes a little more or less sensitive, based on you." },
  { title: "Beat while walking", body: "Optional. A soft metronome tap on your wrist while you walk, so the rhythm is already there." },
  { title: "Steadiness score", body: "Built from how regular your stride is and how much of the last ten minutes was spent frozen, not a count of cues." },
  { title: "History and trends", body: "Every cue with its strength and freeze length, daily notes, time-of-day patterns, week, month and 3-month trends, and CSV export." },
  { title: "Guided setup", body: "Feel the beat on your phone, pick your pace, pair your Watch and take the calibration walk, step by step." },
  { title: "Private by default", body: "Your data stays on your phone and Watch. There's no account to create." },
];

const faqs = [
  { q: "Is GaitGuard a medical device?", a: "No. It's a cueing aid. It doesn't diagnose, treat, or prevent any condition, and it doesn't detect falls or contact anyone." },
  { q: "Has it been proven to work?", a: "Not yet. The idea behind it, rhythmic cueing, is well studied. GaitGuard itself has been tested on simulated signals, not on real patients, and its real-world accuracy is unproven." },
  { q: "What do I need?", a: "An iPhone on iOS 17 or later and a paired Apple Watch on watchOS 10 or later." },
  { q: "Does it use AI?", a: "No. It uses your own 30-second calibration walk and your tick-or-cross answers to set its thresholds." },
  { q: "Does it work without my phone?", a: "Yes. The Watch keeps responding and cueing on its own, then syncs your history later." },
];

export default function HomePage() {
  return (
    <>
      {/* Hero */}
      <section className="relative overflow-hidden">
        <div className="wrap relative grid items-center gap-14 pb-10 pt-10 md:pt-16 lg:grid-cols-[1.1fr_0.9fr] lg:gap-10">
          <div>
            <p className="eyebrow rise">For people with Parkinson&apos;s · iPhone and Apple Watch</p>
            <h1 className="display rise rise-1 mt-6 !text-[clamp(3rem,7vw,5.8rem)]">
              A steady beat for <span className="serif">every step.</span>
            </h1>
            <p className="rise rise-2 mt-8 max-w-[29em] text-[1.2rem] leading-relaxed text-ash">
              When your steps start to freeze, your Apple Watch taps a gentle rhythm on your wrist to help you keep moving.
            </p>
            <div className="rise rise-3 mt-10 flex flex-col gap-3 sm:flex-row">
              <Button href="/pilot" arrow>Join the pilot</Button>
              <Button href="/how-it-works" variant="ghost">How it works</Button>
            </div>
            <p className="rise rise-4 mt-8 max-w-[34em] text-[0.9rem] leading-relaxed text-ash">
              A cueing aid, not a medical device. App Store release coming.{" "}
              <Link href="#safety" className="font-bold text-bone underline decoration-bone/30 underline-offset-4 hover:decoration-ember">What it does and doesn&apos;t do</Link>
            </p>
          </div>

          <div className="rise rise-2 flex flex-col items-center">
            <TickDial />
          </div>
        </div>
      </section>

      {/* Why */}
      <section className="section">
        <div className="wrap">
          <ScrollWords
            className="max-w-[24em] font-[family-name:var(--font-fraunces)] text-[clamp(1.9rem,4.4vw,3.5rem)] font-normal leading-[1.14] tracking-[-0.02em] text-bone"
            text="Freezing can feel like your feet are glued to the floor. A steady outside rhythm is one of the best-studied ways to help the next step come. GaitGuard puts that rhythm on your wrist."
          />
          <p className="mt-8 text-[0.85rem] text-ash">
            Sources <Cite ids={["nutt2011"]} /> <Cite ids={["spaulding2013", "keus2014"]} />
          </p>
        </div>
      </section>

      {/* How it works */}
      <section className="section">
        <div className="wrap">
          <Reveal className="flex flex-wrap items-end justify-between gap-6">
            <h2 className="h2 max-w-[14ch]">How it <span className="serif">works</span></h2>
            <Button href="/how-it-works" variant="ghost" arrow>In more detail</Button>
          </Reveal>
          <ol className="mt-14 border-t border-bone/15">
            {steps.map((s, i) => (
              <Reveal as="li" key={s.n} delay={i * 60} className="group grid gap-4 border-b border-bone/15 py-10 transition-colors duration-500 hover:bg-hearth/60 md:grid-cols-[7rem_1fr_1.3fr] md:items-baseline md:gap-8">
                <span className="num text-[2.4rem] leading-none text-ember transition-transform duration-500 group-hover:translate-x-2">{s.n}</span>
                <h3 className="display !text-[2rem] md:!text-[2.3rem]">{s.title}</h3>
                <p className="text-[1.08rem] leading-relaxed text-ash">{s.body}</p>
              </Reveal>
            ))}
          </ol>
        </div>
      </section>

      {/* The app */}
      <section className="section overflow-hidden">
        <div className="wrap">
          <Reveal className="mx-auto max-w-2xl text-center">
            <p className="eyebrow">The app</p>
            <h2 className="h2 mt-4">Calm on the wrist. <span className="serif">Clear on the phone.</span></h2>
            <p className="mt-6 text-[1.12rem] leading-relaxed text-ash">
              One dial shows how the walk is going. Start it from either device and the other follows.
            </p>
          </Reveal>
          <div className="mt-16">
            <ParallaxPhones />
          </div>
          <p className="mt-16 text-center text-[0.82rem] text-ash">Screenshots from a development build, showing demo data.</p>
          <div className="mt-6 flex justify-center">
            <Button href="/app" variant="ghost" arrow>See every screen</Button>
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="section">
        <div className="wrap">
          <Reveal className="max-w-2xl">
            <h2 className="h2">What&apos;s <span className="serif">inside.</span></h2>
          </Reveal>
          <ul className="mt-14 grid gap-x-12 gap-y-12 sm:grid-cols-2 lg:grid-cols-4">
            {features.map((f, i) => (
              <Reveal as="li" key={f.title} delay={(i % 4) * 70} className="border-t border-bone/15 pt-6">
                <h3 className="display !text-[1.45rem]">{f.title}</h3>
                <p className="mt-3 text-[1rem] leading-relaxed text-ash">{f.body}</p>
              </Reveal>
            ))}
          </ul>
        </div>
      </section>

      {/* Story */}
      <section className="section">
        <div className="wrap grid gap-10 lg:grid-cols-[0.8fr_1.2fr]">
          <Reveal>
            <p className="eyebrow">Why I built this</p>
            <h2 className="h2 mt-4">Built for <span className="serif">my mom.</span></h2>
          </Reveal>
          <Reveal delay={100} className="grid gap-5 text-[1.18rem] leading-relaxed text-ash">
            <p>My mom was diagnosed with Parkinson&apos;s, and I wanted to do something for her.</p>
            <p>So I read the research. I learned how freezing of gait works, and how a steady outside rhythm can help the next step come. Then I put my skills into building something around it.</p>
            <p>GaitGuard is that attempt: for her, and for everyone else who deals with this.</p>
            <p className="font-bold text-bone">Adam, founder</p>
          </Reveal>
        </div>
      </section>

      {/* Safety */}
      <section id="safety" className="section scroll-mt-24">
        <div className="wrap">
          <Reveal className="rounded-[24px] border border-amber/30 bg-amber/[0.06] p-8 sm:p-12">
            <p className="eyebrow !text-amber">Please read</p>
            <h2 className="display mt-4 !text-[clamp(2rem,4vw,3rem)]">What GaitGuard is, and what it isn&apos;t.</h2>
            <ul className="mt-9 grid gap-x-12 gap-y-6 text-[1.05rem] leading-relaxed text-ink-2 md:grid-cols-2">
              <li><strong className="font-bold text-bone">A cueing aid, not a medical device.</strong> It does not diagnose, treat, or prevent any condition.</li>
              <li><strong className="font-bold text-bone">It does not detect falls or contact anyone.</strong> Keep Apple Watch Fall Detection and Emergency SOS turned on if you rely on them.</li>
              <li><strong className="font-bold text-bone">It can miss a freeze, or cue when it wasn&apos;t needed.</strong> Talk with your care team about how to use it.</li>
              <li><strong className="font-bold text-bone">Not yet proven.</strong> It has not been tested on real patients, and we make no claims about accuracy or results.</li>
            </ul>
            <p className="mt-8 text-[0.95rem]"><Link href="/safety" className="font-bold text-bone underline decoration-bone/30 underline-offset-4 hover:decoration-ember">Safety and privacy in full</Link></p>
          </Reveal>
        </div>
      </section>

      {/* Pilot */}
      <section id="pilot" className="section scroll-mt-24">
        <div className="wrap">
          <Reveal className="relative overflow-hidden rounded-[28px] border border-bone/10 bg-hearth p-8 sm:p-14">
            <div className="relative grid gap-12 lg:grid-cols-[1fr_1.05fr]">
              <div>
                <p className="eyebrow">Pilot program</p>
                <h2 className="h2 mt-4">Help us find out if it <span className="serif">works.</span></h2>
                <p className="mt-6 max-w-[28em] text-[1.08rem] leading-relaxed text-ash">
                  We&apos;re looking for people with Parkinson&apos;s, care partners and clinicians to try GaitGuard and tell us honestly what helps and what doesn&apos;t.
                </p>
                <p className="mt-6 text-[0.88rem] leading-relaxed text-ash">
                  An informal product pilot, not a clinical trial.{" "}
                  <Link href="/pilot" className="font-bold text-bone underline decoration-bone/30 underline-offset-4 transition hover:decoration-ember">What taking part involves</Link>
                </p>
              </div>
              <div className="rounded-[22px] bg-char p-6 sm:p-8">
                <p className="mb-6 text-[0.92rem] text-ash">We&apos;ll only email you about the pilot.</p>
                <PilotForm />
              </div>
            </div>
          </Reveal>
        </div>
      </section>

      {/* FAQ */}
      <section id="faq" className="section scroll-mt-24">
        <div className="wrap grid gap-10 lg:grid-cols-[0.7fr_1.3fr]">
          <Reveal>
            <h2 className="h2">Questions</h2>
            <p className="mt-5 text-[0.95rem]"><Link href="/faq" className="font-bold text-bone underline decoration-bone/30 underline-offset-4 hover:decoration-ember">All questions</Link></p>
          </Reveal>
          <Reveal delay={80}>
            <Accordion items={faqs} />
          </Reveal>
        </div>
      </section>
    </>
  );
}
