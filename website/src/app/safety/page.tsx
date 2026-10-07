import type { Metadata } from "next";
import { Icon, icons } from "@/components/Icon";
import { Reveal } from "@/components/Reveal";
import { PageHero } from "@/components/SiteChrome";

export const metadata: Metadata = {
  title: "Safety & privacy",
  description: "What GaitGuard is and isn't, how to use it safely, and how your data stays on your own Apple Watch and iPhone.",
};

const safety = [
  ["Not a medical device", "GaitGuard is a cueing aid and prototype. It doesn't diagnose, treat, cure or prevent any condition, and hasn't been reviewed by the FDA or any regulator."],
  ["Use with supervision first", "Try GaitGuard with a care partner or clinician nearby before relying on it, especially for turns, stairs, or crowded places. Freezing is linked with falls."],
  ["No fall detection or emergency calls", "GaitGuard doesn't detect falls or contact anyone. Keep Apple Watch Fall Detection and Emergency SOS turned on if you rely on them."],
  ["It won't catch every freeze", "Wrist-only detection can miss freezes and sometimes cue when you don't need it. Calibrate, and adjust sensitivity in Settings."],
  ["Pair it with your care team", "Cueing works best alongside strategies taught by a physical therapist. Share your GaitGuard history with them."],
  ["Stop if it doesn't feel right", "If cues startle you, feel uncomfortable, or seem to make walking harder, stop using GaitGuard and talk to your clinician."],
];

const privacy = [
  { icon: icons.lock, title: "No account", body: "There's nothing to sign up for. GaitGuard works the moment you open it." },
  { icon: icons.phone, title: "Stays on your devices", body: "Cue history, notes, settings and calibration live on your Apple Watch and iPhone. GaitGuard has no server and sends nothing to us." },
  { icon: icons.sync, title: "Direct device-to-device sync", body: "Watch and iPhone talk directly through Apple's WatchConnectivity. No cloud in between." },
  { icon: icons.shield, title: "No tracking or ads", body: "No analytics, advertising or third-party SDKs. GaitGuard uses HealthKit only to run a workout session so monitoring continues in the background." },
  { icon: icons.chart, title: "You decide what to share", body: "Data leaves your phone only if you export your history yourself, for example to send to your physical therapist." },
  { icon: icons.target, title: "No AI, no guesswork", body: "Detection is transparent motion math tuned by your own calibration walk, running entirely on your Watch." },
];

export default function SafetyPage() {
  return (
    <>
      <PageHero
        eyebrow="Safety & privacy"
        title={<>Clear about what it is. <span className="serif brand-grad">Private</span> by default.</>}
        intro="GaitGuard is designed to help in a hard moment, not to replace care. And what happens on your walk stays on your devices."
      />

      <section className="section">
        <div className="wrap">
          <Reveal className="max-w-2xl">
            <p className="eyebrow">Using GaitGuard safely</p>
            <h2 className="h2 mt-4">Six things to know first.</h2>
          </Reveal>
          <ul className="mt-12 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {safety.map(([t, b], i) => (
              <Reveal as="li" key={t} delay={(i % 3) * 80} className="panel p-7">
                <span className="font-mono text-[0.8rem] text-cue">0{i + 1}</span>
                <h3 className="mt-3 text-[1.15rem] font-semibold tracking-tight">{t}</h3>
                <p className="mt-2 text-[0.98rem] leading-relaxed text-mute">{b}</p>
              </Reveal>
            ))}
          </ul>
        </div>
      </section>

      <section className="section pb-[var(--section)]">
        <div className="relative overflow-hidden bg-night py-[clamp(80px,10vw,130px)] text-white">
          <div className="pointer-events-none absolute inset-0" aria-hidden="true" style={{ background: "radial-gradient(40% 60% at 15% 0%, rgba(124,140,255,0.22), transparent 70%)" }} />
          <div className="wrap relative">
            <Reveal className="max-w-2xl">
              <p className="eyebrow !text-indigo-soft">Privacy</p>
              <h2 className="h2 mt-4">Your walk is nobody else&apos;s business.</h2>
            </Reveal>
            <ul className="mt-12 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
              {privacy.map((p, i) => (
                <Reveal as="li" key={p.title} delay={(i % 3) * 80} className="rounded-3xl border border-white/10 bg-white/[0.04] p-7">
                  <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-indigo-soft/15 text-indigo-soft">
                    <Icon d={p.icon} />
                  </span>
                  <h3 className="mt-5 text-[1.1rem] font-semibold">{p.title}</h3>
                  <p className="mt-2 text-[0.96rem] leading-relaxed text-white/65">{p.body}</p>
                </Reveal>
              ))}
            </ul>
          </div>
        </div>
      </section>
    </>
  );
}
