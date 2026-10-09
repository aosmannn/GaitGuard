import type { Metadata } from "next";
import { Button } from "@/components/Button";
import { Reveal } from "@/components/Reveal";
import { AUTHOR_URL, PageHero, REPO } from "@/components/SiteChrome";

export const metadata: Metadata = {
  title: "About",
  description: "GaitGuard is an independent, open-source prototype made by Adam. What it is, what it's for, and how to follow along.",
};

const principles = [
  ["Honest about limits", "GaitGuard is a prototype and a cueing aid, not a medical device. We say what the evidence supports and what it doesn't."],
  ["Private by default", "No account, no cloud, no tracking in the app. Your walking data stays on your own devices."],
  ["Built with the people who'd use it", "The pilot exists because the most useful feedback comes from people who walk with freezing, and the people beside them."],
  ["Open", "The code is open source, so anyone can see exactly how detection and cueing work."],
];

export default function AboutPage() {
  return (
    <>
      <PageHero
        eyebrow="About"
        title={<>An independent project, <span className="serif">built in the open.</span></>}
        intro="GaitGuard is a prototype for helping people keep walking through freezing episodes, using the Apple Watch they may already own."
      />

      <section className="section !pt-10">
        <div className="wrap">
          <Reveal className="max-w-[44rem]">
            <p className="eyebrow">Why I&apos;m building this</p>
            <h2 className="display mt-4 !text-[clamp(2rem,4.4vw,3.2rem)]">It started with <span className="serif">my mom.</span></h2>
            <div className="mt-8 grid gap-5 text-[1.12rem] leading-relaxed text-ash">
              <p>My mom was diagnosed with Parkinson&apos;s, and I wanted to do something for her.</p>
              <p>So I started reading the research. I learned how freezing of gait works, and how a steady outside rhythm can help the next step come. Then I put my skills into building something around it.</p>
              <p>GaitGuard is that attempt: for her, and for everyone else who deals with this.</p>
            </div>
            <p className="mt-8 text-[0.95rem] font-bold text-bone">Adam</p>
          </Reveal>
        </div>
      </section>

      <section className="section">
        <div className="wrap grid gap-14 lg:grid-cols-[1fr_1.1fr]">
          <Reveal>
            <h2 className="h2">Four <span className="serif">principles.</span></h2>
            <p className="mt-6 max-w-[28em] text-[1.05rem] leading-relaxed text-ash">What we hold ourselves to while the app is still early.</p>
          </Reveal>
          <ol className="border-t border-bone/15">
            {principles.map(([t, b], i) => (
              <Reveal as="li" key={t} className="grid gap-3 border-b border-bone/15 py-8 sm:grid-cols-[4rem_1fr]">
                <span className="num text-[1.2rem] text-ember">0{i + 1}</span>
                <div>
                  <h3 className="display !text-[1.6rem]">{t}</h3>
                  <p className="mt-2 text-[1rem] leading-relaxed text-ash">{b}</p>
                </div>
              </Reveal>
            ))}
          </ol>
        </div>
      </section>

      <section className="section">
        <div className="wrap">
          <Reveal className="rounded-[24px] border border-bone/10 bg-hearth p-8 sm:p-12">
            <p className="eyebrow">Made by</p>
            <h2 className="display mt-4 !text-[clamp(2.2rem,5vw,3.6rem)]">Adam</h2>
            <p className="mt-5 max-w-[34em] text-[1.05rem] leading-relaxed text-ash">
              To see more of my work or get in touch, visit my site.
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <Button href={AUTHOR_URL} external arrow>adamosman.dev</Button>
              <Button href={REPO} external variant="ghost">Source on GitHub</Button>
              <Button href="/pilot" variant="ghost">Join the pilot</Button>
            </div>
          </Reveal>
        </div>
      </section>
    </>
  );
}
