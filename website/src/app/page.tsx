import Link from "next/link";
import { Button } from "@/components/Button";
import { Cite } from "@/components/Cite";
import { CountUp } from "@/components/CountUp";
import { ParallaxPhones } from "@/components/PhoneDesign";
import { PilotForm } from "@/components/PilotForm";
import { Reveal } from "@/components/Reveal";
import { ScrollWords } from "@/components/ScrollWords";
import { TickDial } from "@/components/TickDial";

const steps = [
  {
    n: "01",
    title: "It notices the stall",
    body: "Apple Watch reads your wrist motion and spots a start or a turn that stops turning into steps.",
  },
  {
    n: "02",
    title: "It taps out a rhythm",
    body: "A short run of evenly spaced haptic beats, at a tempo you choose, gives your next step something to follow.",
  },
  {
    n: "03",
    title: "It keeps the record",
    body: "Your iPhone shows each walk live and keeps a history you can review, or share with your care team.",
  },
];

export default function HomePage() {
  return (
    <>
      {/* Hero */}
      <section className="relative overflow-hidden">
        <div className="wrap relative grid items-center gap-14 pb-10 pt-10 md:pt-16 lg:grid-cols-[1.1fr_0.9fr] lg:gap-10">
          <div>
            <p className="eyebrow rise">Wearable cueing · Now in pilot testing</p>
            <h1 className="display rise rise-1 mt-6 !text-[clamp(3rem,7.2vw,6rem)]">
              Keep the beat when your steps <span className="serif">stall.</span>
            </h1>
            <p className="rise rise-2 mt-8 max-w-[29em] text-[1.18rem] leading-relaxed text-ash">
              GaitGuard notices a freeze on your wrist and answers with a steady, gentle haptic rhythm. Your iPhone keeps the record.
            </p>
            <div className="rise rise-3 mt-10 flex flex-col gap-3 sm:flex-row">
              <Button href="/pilot" arrow>Join the pilot</Button>
              <Button href="/how-it-works" variant="ghost">How it works</Button>
            </div>
            <p className="rise rise-4 mt-8 text-[0.88rem] text-ash">Early prototype. Not a medical device.</p>
          </div>

          <div className="rise rise-2 flex flex-col items-center">
            <TickDial />
            <p className="mt-6 text-center text-[0.9rem] text-ash">Tap the dial to start a simulated walk.</p>
          </div>
        </div>
      </section>

      {/* Statement */}
      <section className="section">
        <div className="wrap">
          <ScrollWords
            className="max-w-[24em] font-[family-name:var(--font-fraunces)] text-[clamp(1.9rem,4.4vw,3.5rem)] font-normal leading-[1.14] tracking-[-0.02em] text-bone"
            text="A freeze can feel like your feet are glued to the floor. An outside rhythm is one of the best-studied ways to help the next step come. GaitGuard puts that rhythm on your wrist, at the moment it matters."
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
            <Button href="/how-it-works" variant="ghost" arrow>The full method</Button>
          </Reveal>
          <ol className="mt-14 border-t border-bone/15">
            {steps.map((s, i) => (
              <Reveal as="li" key={s.n} delay={i * 60} className="group grid gap-4 border-b border-bone/15 py-9 transition-colors duration-500 hover:bg-hearth/60 md:grid-cols-[7rem_1fr_1.1fr] md:items-baseline md:gap-8">
                <span className="num text-[2.4rem] leading-none text-ember transition-transform duration-500 group-hover:translate-x-2">{s.n}</span>
                <h3 className="display !text-[1.9rem] md:!text-[2.1rem]">{s.title}</h3>
                <p className="text-[1.05rem] leading-relaxed text-ash">{s.body}</p>
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
            <p className="mt-6 text-[1.1rem] leading-relaxed text-ash">
              One dial shows how the walk is going. Start it from either device and the other follows within a moment.
            </p>
          </Reveal>
          <div className="mt-16">
            <ParallaxPhones />
          </div>
          <p className="mt-16 text-center text-[0.82rem] text-ash">Design preview. The app is in active development.</p>
          <div className="mt-6 flex justify-center">
            <Button href="/app" variant="ghost" arrow>Explore the app</Button>
          </div>
        </div>
      </section>

      {/* Facts */}
      <section className="section">
        <div className="wrap">
          <dl className="grid gap-12 border-y border-bone/15 py-14 md:grid-cols-3 md:gap-8">
            <Reveal>
              <dt className="label">Reported freezing</dt>
              <dd className="num mt-3 text-[clamp(3.5rem,7vw,5.5rem)] leading-none text-bone"><CountUp to={47} suffix="%" /></dd>
              <p className="mt-3 max-w-[20em] text-[0.95rem] leading-relaxed text-ash">of 6,620 people with Parkinson&apos;s surveyed.<Cite ids={["macht2007"]} /></p>
            </Reveal>
            <Reveal delay={80}>
              <dt className="label">Calibration walk</dt>
              <dd className="num mt-3 text-[clamp(3.5rem,7vw,5.5rem)] leading-none text-bone"><CountUp to={30} /><span className="ml-2 text-[0.35em] italic text-ash">sec</span></dd>
              <p className="mt-3 max-w-[20em] text-[0.95rem] leading-relaxed text-ash">to tune detection to your own way of walking.</p>
            </Reveal>
            <Reveal delay={160}>
              <dt className="label">Default cue tempo</dt>
              <dd className="num mt-3 text-[clamp(3.5rem,7vw,5.5rem)] leading-none text-bone"><CountUp to={100} /><span className="ml-2 text-[0.35em] italic text-ash">bpm</span></dd>
              <p className="mt-3 max-w-[20em] text-[0.95rem] leading-relaxed text-ash">four beats per cue. Tempo and strength are yours to set.</p>
            </Reveal>
          </dl>
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
                  GaitGuard is an early prototype. We&apos;re looking for people with Parkinson&apos;s, care partners and clinicians to try it and tell us honestly what helps and what doesn&apos;t.
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
    </>
  );
}
