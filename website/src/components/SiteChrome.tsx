import Link from "next/link";
import { Logo, LogoMark } from "./Logo";

export const REPO = "https://github.com/pogami/GaitGuardAI";
export const AUTHOR_URL = "https://adamosman.dev";

const nav = [
  { href: "/how-it-works", label: "How it works" },
  { href: "/research", label: "Research" },
  { href: "/safety", label: "Safety & privacy" },
];

export function SiteHeader() {
  return (
    <>
      <header className="sticky top-0 z-50 border-b border-line/80 bg-white/85 backdrop-blur-xl">
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
              <summary className="flex h-10 w-10 cursor-pointer list-none items-center justify-center rounded-full border border-line bg-white" aria-label="Menu">
                <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
                  <path d="M4 7h16M4 12h16M4 17h16" />
                </svg>
              </summary>
              <nav className="absolute right-0 top-12 w-56 rounded-2xl border border-line bg-card p-2 shadow-xl" aria-label="Mobile">
                {[{ href: "/", label: "Home" }, ...nav, { href: "/pilot", label: "Join the pilot" }].map((n) => (
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
    <footer className="border-t border-line bg-paper-2">
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
          <p className="mb-1 text-[0.8rem] font-semibold text-ink">Project</p>
          <Link href="/how-it-works" className="hover:text-ink">How it works</Link>
          <Link href="/research" className="hover:text-ink">Research</Link>
          <Link href="/safety" className="hover:text-ink">Safety & privacy</Link>
          <Link href="/pilot" className="hover:text-ink">Join the pilot</Link>
        </nav>
        <div className="grid content-start gap-2 text-[0.9rem] text-mute">
          <p className="mb-1 text-[0.8rem] font-semibold text-ink">Links</p>
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
            <a href={AUTHOR_URL} target="_blank" rel="noopener noreferrer" className="hover:text-ink">
              adamosman.dev
            </a>
          </p>
          <p>© {new Date().getFullYear()} GaitGuard · MIT</p>
        </div>
      </div>
    </footer>
  );
}

/** Shared page intro used by the inner pages. */
export function PageHero({ eyebrow, title, intro }: { eyebrow: string; title: React.ReactNode; intro: string }) {
  return (
    <section className="border-b border-line bg-paper-2">
      <div className="wrap py-[clamp(56px,8vw,104px)]">
        <p className="eyebrow rise">{eyebrow}</p>
        <h1 className="display rise rise-1 mt-4 max-w-[18ch] text-[clamp(2.3rem,5vw,3.8rem)]">{title}</h1>
        <p className="rise rise-2 mt-5 max-w-[38em] text-[1.1rem] leading-relaxed text-mute">{intro}</p>
      </div>
    </section>
  );
}
