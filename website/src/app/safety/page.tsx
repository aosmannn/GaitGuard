import type { Metadata } from "next";
import { Icon, icons } from "@/components/Icon";
import { Reveal } from "@/components/Reveal";
import { PageHero } from "@/components/SiteChrome";

export const metadata: Metadata = {
  title: "Safety & privacy",
  description: "What GaitGuard is and isn't, how to use it safely, and how your data stays on your own iPhone and Apple Watch.",
};

const safety = [
  ["A cueing aid, not a medical device", "GaitGuard does not diagnose, treat, or prevent any condition."],
  ["No fall detection, no calls", "It does not detect falls or contact anyone. Keep Apple Watch Fall Detection and Emergency SOS turned on if you rely on them."],
  ["It can get it wrong", "It can miss a freeze, or cue when it wasn't needed. Talk with your care team about how to use it."],
  ["Not yet proven", "Its detection logic has been tested on simulated signals, not on real patients. Real-world accuracy is unproven, and we make no claims about accuracy or results."],
  ["Use it with someone nearby at first", "Try it with a care partner or clinician close by, especially for turns, stairs or crowded places."],
  ["Stop if it doesn't feel right", "If cues startle you, feel uncomfortable, or seem to make walking harder, stop using GaitGuard and talk to your clinician."],
];

const privacy = [
  { icon: icons.lock, title: "No account", body: "There's nothing to sign up for. GaitGuard works the moment you open it." },
  { icon: icons.phone, title: "Stays on your devices", body: "Your history, notes, settings and calibration live on your iPhone and Apple Watch." },
  { icon: icons.sync, title: "Direct device-to-device", body: "Your Watch and iPhone sync with each other through Apple's WatchConnectivity." },
  { icon: icons.shield, title: "No ads or trackers", body: "The app has no advertising and no analytics. It uses a workout session on the Watch so monitoring continues when the screen sleeps." },
  { icon: icons.chart, title: "You decide what to share", body: "Your history only leaves your phone if you export it yourself, for example to send to your physical therapist." },
  { icon: icons.target, title: "No AI", body: "It uses your own calibration walk and your tick-or-cross answers to set its thresholds." },
];

export default function SafetyPage() {
  return (
    <>
      <PageHero
        eyebrow="Safety & privacy"
        title={<>Clear about what it is. <span className="serif">Private</span> by default.</>}
        intro="GaitGuard is built to help in a hard moment, not to replace care. And what happens on your walk stays on your devices."
      />

      <section className="section !pt-10">
        <div className="wrap">
          <Reveal className="max-w-2xl">
            <p className="eyebrow">Using GaitGuard safely</p>
            <h2 className="h2 mt-4">Six things to know first.</h2>
          </Reveal>
          <ul className="mt-12 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {safety.map(([t, b], i) => (
              <Reveal as="li" key={t} delay={(i % 3) * 80} className="panel p-7">
                <span className="text-[0.85rem] font-bold text-amber">{i + 1}</span>
                <h3 className="display mt-3 !text-[1.35rem]">{t}</h3>
                <p className="mt-3 text-[1rem] leading-relaxed text-ash">{b}</p>
              </Reveal>
            ))}
          </ul>
        </div>
      </section>

      <section className="section">
        <div className="border-y border-bone/10 bg-hearth py-[clamp(72px,9vw,112px)]">
          <div className="wrap">
            <Reveal className="max-w-2xl">
              <p className="eyebrow">Privacy</p>
              <h2 className="h2 mt-4">Your walk is <span className="serif">your business.</span></h2>
            </Reveal>
            <ul className="mt-12 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
              {privacy.map((p, i) => (
                <Reveal as="li" key={p.title} delay={(i % 3) * 80} className="rounded-2xl border border-bone/10 bg-char p-7">
                  <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-ember/10 text-ember">
                    <Icon d={p.icon} />
                  </span>
                  <h3 className="display mt-5 !text-[1.3rem]">{p.title}</h3>
                  <p className="mt-2 text-[0.98rem] leading-relaxed text-ash">{p.body}</p>
                </Reveal>
              ))}
            </ul>
            <p className="mt-10 max-w-[46em] text-[0.9rem] leading-relaxed text-ash">
              This website is separate from the app. If you join the pilot, the form stores only the details you type, to contact you about the pilot. You can ask to be removed at any time.
            </p>
          </div>
        </div>
      </section>
    </>
  );
}
