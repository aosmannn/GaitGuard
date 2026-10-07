import Link from "next/link";
import { Logo, LogoMark } from "./Logo";

export const REPO = "https://github.com/pogami/GaitGuardAI";
export const AUTHOR_URL = "https://adamosman.dev";

const nav = [
  { href: "/how-it-works", label: "Method" },
  { href: "/research", label: "Research" },
  { href: "/safety", label: "Safety & privacy" },
  { href: "/pilot", label: "Pilot" },
];

export function SiteHeader() {
  return (
    <>
      <div className="border-b border-white/10 bg-night text-white">
        <div className="wrap flex h-9 items-center justify-between gap-4 text-[0.7rem]">
          <p className="mono flex min-w-0 items-center gap-2 uppercase tracking-[0.12em] text-white/70">
            <span className="blink h-1.5 w-1.5 shrink-0 rounded-full bg-cue" aria-hidden="true" />
            <span className="truncate">Prototype v0.9 · Pilot open</span>
          </p>
          <Link href="/pilot" className="mono shrink-0 uppercase tracking-[0.12em] text-cue-soft hover:text-white">
            Join →
          </Link>
        </div>
      </div>
      <header className="sticky top-0 z-50 border-b border-line bg-paper/85 backdrop-blur-xl">
        <div className="wrap flex h-16 items-center justify-between gap-6">
          <Link href="/" aria-label="GaitGuard home">
            <Logo />
          </Link>
          <nav className="hidden items-center gap-8 text-[0.9rem] text-mute md:flex" aria-label="Primary">
            {nav.map((n) => (
              <Link key={n.href} href={n.href} className="transition hover:text-ink">
                {n.label}
              </Link>
            ))}
          </nav>
          <div className="flex items-center gap-2">
            <Link href="/pilot" className="btn btn-ink hidden !min-h-[40px] !px-4 !text-[0.85rem] sm:inline-flex">
              Join the pilot
            </Link>
            <details className="group relative md:hidden">
              <summary className="flex h-10 w-10 cursor-pointer list-none items-center justify-center rounded-[10px] border border-line bg-card" aria-label="Menu">
                <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
                  <path d="M4 7h16M4 12h16M4 17h16" />
                </svg>
              </summary>
              <nav className="absolute right-0 top-12 w-56 rounded-2xl border border-line bg-card p-2 shadow-xl" aria-label="Mobile">
                {[{ href: "/", label: "Home" }, ...nav].map((n) => (
                  <Link key={n.href} href={n.href} className="block rounded-xl px-4 py-3 text-[0.95rem] hover:bg-paper-2">
                    {n.label}
                  </Link>
                ))}
                <a href={REPO} target="_blank" rel="noopener noreferrer" className="block rounded-xl px-4 py-3 text-[0.95rem] hover:bg-paper-2">
                  GitHub
                </a>
              </nav>
            </details>
          </div>
        </div>
      </header>
    </>
  );
}

export function SiteFooter() {
  return (
    <footer className="border-t border-line bg-card">
      <div className="wrap grid gap-10 py-14 md:grid-cols-[1.5fr_1fr_1fr]">
        <div>
          <div className="flex items-center gap-2.5">
            <LogoMark size={28} />
            <span className="font-semibold">GaitGuard</span>
          </div>
          <p className="mt-4 max-w-[30em] text-[0.85rem] leading-relaxed text-mute">
            A rhythmic haptic cueing prototype for freezing of gait, on Apple Watch and iPhone. GaitGuard is an early prototype and a cueing aid, not a medical device. Use with supervision.
          </p>
        </div>
        <nav aria-label="Footer" className="grid content-start gap-2 text-[0.9rem] text-mute">
          <p className="label mb-1">Project</p>
          <Link href="/how-it-works" className="hover:text-ink">Method</Link>
          <Link href="/research" className="hover:text-ink">Research</Link>
          <Link href="/safety" className="hover:text-ink">Safety & privacy</Link>
          <Link href="/pilot" className="hover:text-ink">Join the pilot</Link>
        </nav>
        <div className="grid content-start gap-2 text-[0.9rem] text-mute">
          <p className="label mb-1">Links</p>
          <a href={REPO} target="_blank" rel="noopener noreferrer" className="hover:text-ink">Source on GitHub ↗</a>
        </div>
      </div>
      <div className="border-t border-line">
        <div className="wrap flex flex-col gap-2 py-5 text-[0.82rem] text-mute sm:flex-row sm:items-center sm:justify-between">
          <p>
            Made by{" "}
            <a href={AUTHOR_URL} target="_blank" rel="noopener noreferrer" className="font-semibold text-ink underline decoration-line underline-offset-4 hover:decoration-indigo">
              Adam
            </a>
            {" · "}
            <a href={AUTHOR_URL} target="_blank" rel="noopener noreferrer" className="mono hover:text-ink">
              adamosman.dev
            </a>
          </p>
          <p className="mono">© {new Date().getFullYear()} GaitGuard · MIT</p>
        </div>
      </div>
    </footer>
  );
}

/** Shared page intro used by the inner pages. */
export function PageHero({ eyebrow, title, intro }: { eyebrow: string; title: React.ReactNode; intro: string }) {
  return (
    <section className="relative overflow-hidden border-b border-line">
      <div className="paper-grid pointer-events-none absolute inset-0" aria-hidden="true" />
      <div className="wrap relative py-[clamp(64px,9vw,120px)]">
        <p className="eyebrow rise">{eyebrow}</p>
        <h1 className="display rise rise-1 mt-5 max-w-[17ch] text-[clamp(2.5rem,6vw,4.6rem)]">{title}</h1>
        <p className="rise rise-2 mt-6 max-w-[38em] text-[1.12rem] leading-relaxed text-mute">{intro}</p>
      </div>
    </section>
  );
}
