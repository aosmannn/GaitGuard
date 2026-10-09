import type { Metadata } from "next";
import Link from "next/link";
import { PilotForm } from "@/components/PilotForm";
import { Reveal } from "@/components/Reveal";
import { PageHero } from "@/components/SiteChrome";

export const metadata: Metadata = {
  title: "Join the pilot",
  description: "Help test GaitGuard, an early rhythmic haptic cueing prototype for freezing of gait on Apple Watch and iPhone.",
};

const steps = [
  ["Sign up", "Tell us who you are and which devices you have. It takes about a minute."],
  ["Get a build", "We plan to invite testers to an early build through Apple's TestFlight, in small groups."],
  ["Walk, with supervision", "Try it on ordinary walks with a care partner or clinician nearby. Calibrate first, then adjust the cue to feel right."],
  ["Tell us what happened", "Short feedback notes: did cues come at the right time, was the rhythm comfortable, what was missing?"],
];

const asks = [
  ["What we ask of you", "A few walks, honest feedback, and supervised use. You can stop at any time."],
  ["What you get", "Early access, a direct line to the developer, and real influence over what gets built."],
  ["What this isn't", "A clinical trial. There's no ethics-board-reviewed study yet and no medical claims. GaitGuard is a cueing aid, not a medical device."],
  ["Your information", "This form collects only what you type. It's used to contact you about the pilot, and you can ask to be removed at any time."],
];

export default function PilotPage() {
  return (
    <>
      <PageHero
        eyebrow="Pilot program"
        title={<>Be among the first to <span className="serif brand-grad">test it.</span></>}
        intro="GaitGuard is an early prototype. The most useful thing right now is hearing from people who would actually use it, and from the people who walk beside them."
      />

      <section className="section">
        <div className="wrap grid gap-12 lg:grid-cols-[1fr_1.05fr]">
          <div>
            <Reveal>
              <p className="eyebrow">How it works</p>
              <h2 className="h2 mt-4">Four steps.</h2>
            </Reveal>
            <ol className="mt-10 border-t border-line">
              {steps.map(([t, b], i) => (
                <Reveal as="li" key={t} delay={i * 60} className="grid grid-cols-[3rem_1fr] gap-3 border-b border-line py-6">
                  <span className="text-[0.9rem] font-semibold text-indigo">{i + 1}</span>
                  <div>
                    <h3 className="text-[1.15rem] font-semibold tracking-tight">{t}</h3>
                    <p className="mt-1.5 text-[0.98rem] leading-relaxed text-mute">{b}</p>
                  </div>
                </Reveal>
              ))}
            </ol>
          </div>

          <Reveal delay={100} className="panel self-start p-7 sm:p-9 lg:sticky lg:top-28">
            <h2 className="text-[1.4rem] font-semibold tracking-tight">Join the pilot</h2>
            <p className="mb-7 mt-2 text-[0.95rem] text-mute">We&apos;ll only email you about the pilot.</p>
            <PilotForm />
          </Reveal>
        </div>
      </section>

      <section className="section pb-[var(--section)]">
        <div className="wrap">
          <ul className="grid gap-4 md:grid-cols-2">
            {asks.map(([t, b], i) => (
              <Reveal as="li" key={t} delay={(i % 2) * 80} className="panel p-7">
                <p className="text-[0.95rem] font-semibold text-ink">{t}</p>
                <p className="mt-3 text-[1.02rem] leading-relaxed text-ink-2">{b}</p>
              </Reveal>
            ))}
          </ul>
          <p className="mt-8 text-[0.9rem] text-mute">
            Read about <Link href="/safety" className="underline underline-offset-4 hover:text-ink">safety and privacy</Link> or the <Link href="/research" className="underline underline-offset-4 hover:text-ink">research behind the idea</Link>.
          </p>
        </div>
      </section>
    </>
  );
}
