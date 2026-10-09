import type { Metadata } from "next";
import { Button } from "@/components/Button";
import { Icon, icons } from "@/components/Icon";
import { PhoneDesign } from "@/components/PhoneDesign";
import { Reveal } from "@/components/Reveal";
import { PageHero } from "@/components/SiteChrome";

export const metadata: Metadata = {
  title: "The app",
  description: "The GaitGuard app for iPhone and Apple Watch: a single dial for the walk, live sync between devices, and a calm history of every cue.",
};

const screens = [
  { name: "Home", body: "One dial for the whole walk. Tap it to start, or start from your Watch. During a walk it shows your gait score, steps and cadence." },
  { name: "History", body: "Every cue by day with strength and duration, plus daily notes for medication, sleep or anything else worth remembering." },
  { name: "Trends", body: "Cues per day, the time of day they cluster, and how this week compares with last. Export to a spreadsheet for your care team." },
  { name: "Settings", body: "Tempo, number of beats, haptic style and strength. Detection sensitivity. A test cue. Calibration. All of it applies on the Watch instantly." },
];

const details = [
  { icon: icons.sync, title: "Live on both devices", body: "Start, stop, score and cues match on Watch and iPhone within a moment. Out of range? Changes queue and catch up." },
  { icon: icons.wave, title: "A rhythm you set", body: "Choose the tempo, the number of beats and how the haptic feels. Send a test cue from your phone." },
  { icon: icons.target, title: "Tuned to you", body: "A 30-second calibration walk sets detection to your own baseline. Start it from either device." },
  { icon: icons.lock, title: "Stays on your devices", body: "No account and no cloud. Your history lives on your Watch and iPhone, and you decide what to export." },
];

export default function AppPage() {
  return (
    <>
      <PageHero
        eyebrow="The app"
        title={<>Calm on the wrist. <span className="serif">Clear on the phone.</span></>}
        intro="The Watch does the sensing and the cueing. The iPhone shows how the walk is going and keeps the record. Both are built around one idea: a dial that tells you at a glance how steady things are."
      />

      <section className="section !pt-8">
        <div className="wrap grid items-start gap-14 lg:grid-cols-[0.9fr_1.1fr]">
          <div className="lg:sticky lg:top-28">
            <Reveal>
              <div className="mx-auto grid max-w-[640px] grid-cols-2 gap-5 sm:gap-8">
                <PhoneDesign src="/design/app-home-ready.png" alt="GaitGuard home screen before a walk" />
                <PhoneDesign src="/design/app-home-walking.png" alt="GaitGuard home screen during a walk, gait score 82" className="mt-12" />
              </div>
              <p className="mt-10 text-center text-[0.85rem] text-ash">Design preview. The app is in active development and details will change.</p>
            </Reveal>
          </div>

          <div>
            <ol className="border-t border-bone/15">
              {screens.map((s, i) => (
                <Reveal as="li" key={s.name} className="grid gap-3 border-b border-bone/15 py-9 sm:grid-cols-[5rem_1fr] sm:gap-6">
                  <span className="num text-[1.2rem] text-ember">0{i + 1}</span>
                  <div>
                    <h2 className="display !text-[2rem]">{s.name}</h2>
                    <p className="mt-3 max-w-[32em] text-[1.03rem] leading-relaxed text-ash">{s.body}</p>
                  </div>
                </Reveal>
              ))}
            </ol>
          </div>
        </div>
      </section>

      <section className="section">
        <div className="wrap">
          <Reveal className="max-w-2xl">
            <h2 className="h2">Small things, <span className="serif">done carefully.</span></h2>
          </Reveal>
          <ul className="mt-14 grid gap-5 sm:grid-cols-2">
            {details.map((d, i) => (
              <Reveal as="li" key={d.title} delay={(i % 2) * 80} className="panel p-8 transition-colors duration-500 hover:border-ember/40">
                <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-ember/10 text-ember">
                  <Icon d={d.icon} />
                </span>
                <h3 className="display mt-6 !text-[1.5rem]">{d.title}</h3>
                <p className="mt-3 text-[1rem] leading-relaxed text-ash">{d.body}</p>
              </Reveal>
            ))}
          </ul>
          <div className="mt-12 flex flex-wrap gap-3">
            <Button href="/pilot" arrow>Join the pilot</Button>
            <Button href="/how-it-works" variant="ghost">How it works</Button>
          </div>
        </div>
      </section>
    </>
  );
}
