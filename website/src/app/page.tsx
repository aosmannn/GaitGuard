import Link from "next/link";
import { Cite } from "@/components/Cite";
import { PhoneShot, WatchShot } from "@/components/DeviceShot";
import { Icon, icons } from "@/components/Icon";
import { PilotForm } from "@/components/PilotForm";
import { Reveal } from "@/components/Reveal";

const steps = [
  {
    title: "Detects the stall",
    body: "Apple Watch reads your wrist motion and notices when a start or a turn stops turning into steps.",
    icon: icons.pulse,
  },
  {
    title: "Cues a rhythm",
    body: "A short run of evenly spaced haptic taps, at a tempo you choose, gives your next step something to follow.",
    icon: icons.wave,
  },
  {
    title: "Keeps a record",
    body: "Your iPhone shows each session live and keeps a history you can review or share with your care team.",
    icon: icons.chart,
  },
];

const screens = [
  { src: "/screens/summary.png", title: "Summary", body: "Live status, score and today's cues, mirrored from the Watch in real time." },
  { src: "/screens/history.png", title: "History", body: "Every cue by day, with strength, duration and your own notes." },
  { src: "/screens/trends.png", title: "Trends", body: "See how cues change over weeks, and at what time of day they happen." },
];

const faqs = [
  ["Is GaitGuard a medical device?", "No. It's a cueing aid and an early prototype. It doesn't diagnose, treat or prevent any condition, detect falls, or contact emergency services."],
  ["What do I need?", "An iPhone on iOS 17 or later and a paired Apple Watch on watchOS 10 or later. Detection and cueing run on the Watch; the iPhone is the companion."],
  ["Does it use AI?", "No. Detection uses a calibration walk and simple motion thresholds, and runs entirely on your Watch."],
  ["Where does my data go?", "The app keeps your history on your Watch and iPhone. It has no account and no cloud. The pilot form on this site only stores what you type into it."],
];

export default function HomePage() {
  return (
    <>
      {/* Hero */}
      <section className="bg-paper-2">
        <div className="wrap grid items-center gap-12 pb-0 pt-14 md:pt-20 lg:grid-cols-[1.1fr_1fr] lg:gap-8">
          <div className="pb-14 lg:pb-24">
            <p className="eyebrow rise">Apple Watch + iPhone · Now in pilot testing</p>
            <h1 className="display rise rise-1 mt-4 text-[clamp(2.4rem,4.7vw,3.8rem)]">
              A steady rhythm when your steps stall.
            </h1>
            <p className="rise rise-2 mt-6 max-w-[30em] text-[1.15rem] leading-relaxed text-mute">
              GaitGuard detects freezing of gait on your wrist and responds with a gentle haptic cue. Your iPhone keeps the record.
            </p>
            <div className="rise rise-3 mt-8 flex flex-col gap-3 sm:flex-row">
              <Link href="/pilot" className="btn btn-signal">Join the pilot</Link>
              <Link href="/how-it-works" className="btn btn-ghost">How it works</Link>
            </div>
            <p className="rise rise-4 mt-6 text-[0.85rem] text-mute-2">Early prototype. Not a medical device.</p>
          </div>

          <div className="rise rise-2 relative flex justify-center lg:justify-end">
            <PhoneShot src="/screens/summary.png" alt="GaitGuard iPhone app showing a live monitoring session with a gait score" priority className="w-[min(300px,72vw)] translate-y-0 lg:translate-y-10" />
            <WatchShot src="/screens/watch.png" alt="GaitGuard on Apple Watch showing the gait score" width={WATCH_W} height={WATCH_H} className="absolute bottom-8 left-1/2 w-[34%] max-w-[150px] -translate-x-[135%] lg:bottom-16 lg:left-auto lg:right-[62%] lg:translate-x-0" />
          </div>
        </div>
      </section>

      {/* How it works */}
      <section className="section">
        <div className="wrap">
          <Reveal className="max-w-2xl">
            <h2 className="h2">How it works</h2>
            <p className="mt-4 text-[1.1rem] leading-relaxed text-mute">
              Rhythmic cueing is one of the best-studied ways to help people with Parkinson&apos;s keep walking through a freeze.
              <Cite ids={["spaulding2013", "keus2014"]} /> GaitGuard puts that on your wrist and makes it automatic.
            </p>
          </Reveal>
          <ol className="mt-12 grid gap-10 md:grid-cols-3">
            {steps.map((s, i) => (
              <Reveal as="li" key={s.title} delay={i * 80}>
                <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-indigo/10 text-indigo">
                  <Icon d={s.icon} className="h-5 w-5" />
                </span>
                <h3 className="mt-5 text-[1.2rem] font-semibold tracking-tight">{s.title}</h3>
                <p className="mt-2 text-[1rem] leading-relaxed text-mute">{s.body}</p>
              </Reveal>
            ))}
          </ol>
          <p className="mt-10 text-[0.95rem]">
            <Link href="/how-it-works" className="font-semibold text-indigo hover:underline">See the full method →</Link>
          </p>
        </div>
      </section>

      {/* The app */}
      <section className="section">
        <div className="bg-paper-2">
          <div className="wrap py-[var(--section)]">
            <Reveal className="max-w-2xl">
              <h2 className="h2">The iPhone companion</h2>
              <p className="mt-4 text-[1.1rem] leading-relaxed text-mute">
                Start or stop from either device. Everything you see on the Watch appears on the iPhone within a moment.
              </p>
            </Reveal>
            <ul className="mt-14 grid gap-12 sm:grid-cols-3 sm:gap-8">
              {screens.map((s, i) => (
                <Reveal as="li" key={s.title} delay={i * 80} className="flex flex-col items-center text-center">
                  <PhoneShot src={s.src} alt={`GaitGuard ${s.title} screen`} className="w-full max-w-[260px]" />
                  <h3 className="mt-7 text-[1.15rem] font-semibold tracking-tight">{s.title}</h3>
                  <p className="mt-1.5 max-w-[20em] text-[0.95rem] leading-relaxed text-mute">{s.body}</p>
                </Reveal>
              ))}
            </ul>
            <p className="mt-12 text-center text-[0.8rem] text-mute-2">Screenshots show sample data from a development build.</p>
          </div>
        </div>
      </section>

      {/* Evidence */}
      <section className="section">
        <div className="wrap grid gap-12 lg:grid-cols-[1.2fr_1fr] lg:items-center">
          <Reveal>
            <h2 className="h2">Built on published research</h2>
            <p className="mt-4 max-w-[34em] text-[1.1rem] leading-relaxed text-mute">
              Freezing of gait is common, disabling, and closely linked with falls.
              <Cite ids={["nutt2011", "bloem2004"]} /> We summarize what the evidence supports, and what it doesn&apos;t, on the research page.
            </p>
            <p className="mt-8 text-[0.95rem]">
              <Link href="/research" className="font-semibold text-indigo hover:underline">Read the research →</Link>
            </p>
          </Reveal>
          <Reveal delay={100} className="panel p-8">
            <p className="text-[3rem] font-semibold tracking-tight">47%</p>
            <p className="mt-2 text-[1rem] leading-relaxed text-mute">
              of 6,620 people with Parkinson&apos;s surveyed reported experiencing freezing.
              <Cite ids={["macht2007"]} />
            </p>
          </Reveal>
        </div>
      </section>

      {/* Pilot */}
      <section id="pilot" className="section scroll-mt-20">
        <div className="bg-paper-2">
          <div className="wrap grid gap-12 py-[var(--section)] lg:grid-cols-[1fr_1.1fr]">
            <Reveal>
              <h2 className="h2">Help us test GaitGuard</h2>
              <p className="mt-4 max-w-[30em] text-[1.1rem] leading-relaxed text-mute">
                GaitGuard is an early prototype. We&apos;re looking for people with Parkinson&apos;s, care partners and clinicians to try it and tell us honestly what helps and what doesn&apos;t.
              </p>
              <ul className="mt-8 grid gap-3 text-[1rem] text-ink-2">
                <li className="flex gap-3"><span className="mt-2 h-1.5 w-1.5 shrink-0 rounded-full bg-indigo" />Do cues arrive at the right moment?</li>
                <li className="flex gap-3"><span className="mt-2 h-1.5 w-1.5 shrink-0 rounded-full bg-indigo" />Is the rhythm comfortable to follow?</li>
                <li className="flex gap-3"><span className="mt-2 h-1.5 w-1.5 shrink-0 rounded-full bg-indigo" />Is the iPhone view useful to a care partner?</li>
              </ul>
              <p className="mt-8 text-[0.85rem] leading-relaxed text-mute-2">
                This is an informal product pilot, not a clinical trial. <Link href="/pilot" className="underline underline-offset-4 hover:text-ink">What taking part involves</Link>
              </p>
            </Reveal>
            <Reveal delay={100} className="panel p-7 sm:p-9">
              <h3 className="text-[1.3rem] font-semibold tracking-tight">Join the pilot</h3>
              <p className="mb-7 mt-1.5 text-[0.95rem] text-mute">We&apos;ll only email you about the pilot.</p>
              <PilotForm />
            </Reveal>
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section id="faq" className="section scroll-mt-20 pb-[var(--section)]">
        <div className="wrap grid gap-10 lg:grid-cols-[0.7fr_1.3fr]">
          <Reveal>
            <h2 className="h2">Questions</h2>
          </Reveal>
          <Reveal className="divide-y divide-line border-y border-line">
            {faqs.map(([q, a]) => (
              <details key={q} className="group py-5">
                <summary className="flex cursor-pointer list-none items-center justify-between gap-6 text-[1.05rem] font-medium">
                  {q}
                  <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full border border-line text-mute transition group-open:rotate-45" aria-hidden="true">+</span>
                </summary>
                <p className="mt-3 max-w-[40em] text-[1rem] leading-relaxed text-mute">{a}</p>
              </details>
            ))}
          </Reveal>
        </div>
      </section>
    </>
  );
}

// Watch screenshot dimensions (set when the screenshot is captured).
const WATCH_W = 422;
const WATCH_H = 514;
