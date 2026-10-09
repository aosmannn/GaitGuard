import type { Metadata } from "next";
import Link from "next/link";
import { Accordion } from "@/components/Accordion";
import { Button } from "@/components/Button";
import { PageHero } from "@/components/SiteChrome";

export const metadata: Metadata = {
  title: "FAQ",
  description: "Answers about what GaitGuard is, how it works, what it can't do, how it handles your data, and how to join the pilot.",
};

const items = [
  { q: "Is GaitGuard a medical device?", a: "No. GaitGuard is a cueing aid. It does not diagnose, treat, or prevent any condition. It doesn't detect falls or contact anyone, so keep Apple Watch Fall Detection and Emergency SOS turned on if you rely on them." },
  { q: "Has it been proven to work?", a: "Not yet. The idea behind it, rhythmic cueing, is well studied. GaitGuard's own logic is covered by automated tests on simulated signals, but it has not been validated on real patients, so its real-world accuracy is unproven. It can miss a freeze, or cue when it wasn't needed." },
  { q: "How does it know when my walking stalls?", a: "The Watch reads its motion sensor and separates the steady rhythm of walking from fast trembling. It only responds if you were walking a moment ago, the walking rhythm stopped, and trembling-like movement shows up for about a second and a half. See How it works for the full picture." },
  { q: "What do I need?", a: "An iPhone on iOS 17 or later and a paired Apple Watch on watchOS 10 or later." },
  { q: "Does it use AI?", a: "No. It uses your own 30-second calibration walk, and your tick-or-cross answers after each cue, to set its thresholds." },
  { q: "Does it work without my phone?", a: "Yes. The Watch keeps responding and cueing on its own while you walk, then syncs your history to the phone later." },
  { q: "What is the steadiness score?", a: "It's built from how regular your stride is and how much of the last ten minutes was spent frozen. It isn't a count of cues, and it isn't a clinical measure." },
  { q: "Where does my data go?", a: "Your history, notes and settings stay on your iPhone and Apple Watch. There's no account, and the app has no advertising or analytics. You can export your history to CSV yourself. The pilot form on this website stores only what you type into it." },
  { q: "Can it replace physical therapy or my clinician's advice?", a: "No. Rhythmic cueing works best alongside strategies taught by a physical therapist. Talk with your care team about how to use GaitGuard, and use it with someone nearby at first." },
  { q: "Is this a clinical trial?", a: "No. The pilot is an informal product test. There's no ethics-board-reviewed study yet, and we make no medical claims." },
  { q: "When can I get it?", a: "An App Store release is coming. For now we're inviting a small group of testers through the pilot. The project is also open source on GitHub." },
];

export default function FaqPage() {
  return (
    <>
      <PageHero eyebrow="FAQ" title={<>Questions, <span className="serif">answered.</span></>} intro="The short version of what GaitGuard is, what it isn't, and what happens to your information." />
      <section className="section !pt-8">
        <div className="wrap max-w-[920px]">
          <Accordion items={items} />
          <p className="mt-10 text-[0.95rem] text-ash">
            More in <Link href="/safety" className="font-bold text-bone underline decoration-bone/30 underline-offset-4 hover:decoration-ember">safety & privacy</Link>, <Link href="/how-it-works" className="font-bold text-bone underline decoration-bone/30 underline-offset-4 hover:decoration-ember">how it works</Link> and <Link href="/research" className="font-bold text-bone underline decoration-bone/30 underline-offset-4 hover:decoration-ember">the research</Link>.
          </p>
          <div className="mt-10"><Button href="/pilot" arrow>Join the pilot</Button></div>
        </div>
      </section>
    </>
  );
}
