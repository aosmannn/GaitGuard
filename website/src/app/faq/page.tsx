import type { Metadata } from "next";
import Link from "next/link";
import { Accordion } from "@/components/Accordion";
import { Button } from "@/components/Button";
import { PageHero } from "@/components/SiteChrome";

export const metadata: Metadata = {
  title: "FAQ",
  description: "Answers about what GaitGuard is, what you need to use it, how it handles your data, and how to join the pilot.",
};

const items = [
  {
    q: "Is GaitGuard a medical device?",
    a: "No. GaitGuard is a cueing aid and an early prototype. It doesn't diagnose, treat or prevent any condition. It doesn't detect falls or contact emergency services, and it hasn't been reviewed by the FDA or any regulator.",
  },
  {
    q: "What do I need to use it?",
    a: "An iPhone on iOS 17 or later and a paired Apple Watch on watchOS 10 or later. Detection and cueing run on the Watch; the iPhone is the companion.",
  },
  {
    q: "Does it use AI?",
    a: "No. Detection uses a 30-second calibration walk and simple, transparent motion thresholds that run entirely on your Watch.",
  },
  {
    q: "Does it work away from my iPhone?",
    a: "Yes. The Watch detects and cues on its own. When the two reconnect, history and settings catch up automatically.",
  },
  {
    q: "Where does my data go?",
    a: "The app keeps your history on your Watch and iPhone. It has no account and no cloud, and it only leaves your devices if you export it. The pilot form on this website stores only what you type into it.",
  },
  {
    q: "Is this a clinical trial?",
    a: "No. The pilot is an informal product test. There's no ethics-board-reviewed study yet, and we make no medical claims. The research page explains what the published evidence does and doesn't support.",
  },
  {
    q: "Can it replace physical therapy or my clinician's advice?",
    a: "No. Rhythmic cueing works best alongside strategies taught by a physical therapist. Use GaitGuard with supervision, and share your history with your care team.",
  },
  {
    q: "When can I get it?",
    a: "An App Store release is planned. For now we're inviting a small group of testers through the pilot. The project is also open source on GitHub.",
  },
];

export default function FaqPage() {
  return (
    <>
      <PageHero eyebrow="FAQ" title={<>Questions, <span className="serif">answered.</span></>} intro="The short version of what GaitGuard is, what it isn't, and what happens to your information." />
      <section className="section !pt-8">
        <div className="wrap max-w-[920px]">
          <Accordion items={items.map((i) => ({ q: i.q, a: i.a }))} />
          <p className="mt-10 text-[0.95rem] text-ash">
            More in <Link href="/safety" className="font-bold text-bone underline decoration-bone/30 underline-offset-4 hover:decoration-ember">safety & privacy</Link> and <Link href="/research" className="font-bold text-bone underline decoration-bone/30 underline-offset-4 hover:decoration-ember">the research</Link>.
          </p>
          <div className="mt-10"><Button href="/pilot" arrow>Join the pilot</Button></div>
        </div>
      </section>
    </>
  );
}
