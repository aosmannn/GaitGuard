import Link from "next/link";
import { LogoMark } from "./Logo";

export { SiteHeader } from "./SiteHeader";

export const REPO = "https://github.com/pogami/GaitGuardAI";
export const AUTHOR_URL = "https://adamosman.dev";

export function SiteFooter() {
  return (
    <footer className="mt-[var(--section)] border-t border-bone/10 bg-hearth">
      <div className="wrap grid gap-12 py-16 md:grid-cols-[1.6fr_1fr_1fr_1fr]">
        <div>
          <div className="flex items-center gap-2.5">
            <LogoMark size={30} />
            <span className="font-[family-name:var(--font-fraunces)] text-[1.3rem] font-medium">GaitGuard</span>
          </div>
          <p className="mt-5 max-w-[28em] text-[0.92rem] leading-relaxed text-ash">
            A rhythmic haptic cueing prototype for freezing of gait, on Apple Watch and iPhone. An early prototype and a cueing aid, not a medical device. Use with supervision.
          </p>
        </div>
        <nav aria-label="Product" className="grid content-start gap-2.5 text-[0.92rem] text-ash">
          <p className="label mb-1">Product</p>
          <Link href="/how-it-works" className="transition hover:text-bone">How it works</Link>
          <Link href="/app" className="transition hover:text-bone">The app</Link>
          <Link href="/research" className="transition hover:text-bone">Research</Link>
        </nav>
        <nav aria-label="Support" className="grid content-start gap-2.5 text-[0.92rem] text-ash">
          <p className="label mb-1">Help</p>
          <Link href="/safety" className="transition hover:text-bone">Safety & privacy</Link>
          <Link href="/faq" className="transition hover:text-bone">FAQ</Link>
          <Link href="/pilot" className="transition hover:text-bone">Join the pilot</Link>
        </nav>
        <nav aria-label="Project" className="grid content-start gap-2.5 text-[0.92rem] text-ash">
          <p className="label mb-1">Project</p>
          <Link href="/about" className="transition hover:text-bone">About</Link>
          <a href={REPO} target="_blank" rel="noopener noreferrer" className="transition hover:text-bone">GitHub ↗</a>
          <a href={AUTHOR_URL} target="_blank" rel="noopener noreferrer" className="transition hover:text-bone">adamosman.dev ↗</a>
        </nav>
      </div>
      <div className="border-t border-bone/10">
        <div className="wrap flex flex-col gap-2 py-6 text-[0.85rem] text-ash sm:flex-row sm:items-center sm:justify-between">
          <p>
            Made by{" "}
            <a href={AUTHOR_URL} target="_blank" rel="noopener noreferrer" className="font-bold text-bone underline decoration-bone/30 underline-offset-4 transition hover:decoration-ember">
              Adam
            </a>{" "}
            ·{" "}
            <a href={AUTHOR_URL} target="_blank" rel="noopener noreferrer" className="transition hover:text-bone">
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
    <section className="relative overflow-hidden">
      <div className="wrap relative pb-[clamp(40px,6vw,72px)] pt-[clamp(56px,9vw,120px)]">
        <p className="eyebrow rise">{eyebrow}</p>
        <h1 className="display rise rise-1 mt-5 max-w-[16ch]">{title}</h1>
        <p className="rise rise-2 mt-7 max-w-[38em] text-[1.15rem] leading-relaxed text-ash">{intro}</p>
      </div>
    </section>
  );
}
