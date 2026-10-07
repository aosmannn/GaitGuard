import Link from "next/link";
import { Logo, LogoMark } from "./Logo";

export const REPO = "https://github.com/pogami/GaitGuardAI";

const nav = [
  { href: "/how-it-works", label: "How it works" },
  { href: "/research", label: "Research" },
  { href: "/safety", label: "Safety & privacy" },
];

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-50 border-b border-line/70 bg-paper/80 backdrop-blur-xl">
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
          <a href={REPO} target="_blank" rel="noopener noreferrer" className="btn btn-ink hidden !min-h-[40px] !px-4 !text-[0.85rem] sm:inline-flex">
            GitHub
          </a>
          <details className="group relative md:hidden">
            <summary className="flex h-10 w-10 cursor-pointer list-none items-center justify-center rounded-full border border-line bg-card" aria-label="Menu">
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
  );
}

export function SiteFooter() {
  return (
    <footer className="border-t border-line">
      <div className="wrap grid gap-10 py-14 md:grid-cols-[1.4fr_1fr_1fr]">
        <div>
          <div className="flex items-center gap-2.5">
            <LogoMark size={28} />
            <span className="font-semibold">GaitGuard</span>
          </div>
          <p className="mt-4 max-w-[28em] text-[0.85rem] leading-relaxed text-mute">
            Rhythmic haptic cueing for freezing of gait, on Apple Watch and iPhone. GaitGuard is a cueing aid, not a medical device. Use with supervision.
          </p>
        </div>
        <nav aria-label="Footer" className="grid gap-2 text-[0.9rem] text-mute">
          <p className="mb-1 text-[0.75rem] font-semibold uppercase tracking-[0.14em] text-mute-2">Product</p>
          <Link href="/how-it-works" className="hover:text-ink">How it works</Link>
          <Link href="/research" className="hover:text-ink">Research</Link>
          <Link href="/safety" className="hover:text-ink">Safety & privacy</Link>
        </nav>
        <div className="grid content-start gap-2 text-[0.9rem] text-mute">
          <p className="mb-1 text-[0.75rem] font-semibold uppercase tracking-[0.14em] text-mute-2">Project</p>
          <a href={REPO} target="_blank" rel="noopener noreferrer" className="hover:text-ink">GitHub</a>
          <p>© {new Date().getFullYear()} GaitGuard · MIT</p>
        </div>
      </div>
    </footer>
  );
}

/** Shared page intro used by the inner pages. */
export function PageHero({ eyebrow, title, intro }: { eyebrow: string; title: React.ReactNode; intro: string }) {
  return (
    <section className="relative overflow-hidden border-b border-line bg-card">
      <div
        className="pointer-events-none absolute inset-0"
        aria-hidden="true"
        style={{ background: "radial-gradient(45% 80% at 90% 0%, rgba(155,107,255,0.14), transparent 70%)" }}
      />
      <div className="wrap relative py-[clamp(64px,9vw,120px)]">
        <p className="eyebrow rise">{eyebrow}</p>
        <h1 className="display rise rise-1 mt-5 max-w-[16ch] text-[clamp(2.5rem,6vw,4.6rem)]">{title}</h1>
        <p className="rise rise-2 mt-6 max-w-[38em] text-[1.12rem] leading-relaxed text-mute">{intro}</p>
      </div>
    </section>
  );
}
