"use client";

import { AnimatePresence, motion } from "motion/react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { Button } from "./Button";
import { Logo } from "./Logo";

export const NAV = [
  { href: "/how-it-works", label: "How it works" },
  { href: "/app", label: "The app" },
  { href: "/research", label: "Research" },
  { href: "/safety", label: "Safety" },
  { href: "/pilot", label: "Pilot" },
];

export function SiteHeader() {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [hovered, setHovered] = useState<string | null>(null);

  useEffect(() => {
    const on = () => setScrolled(window.scrollY > 12);
    const raf = requestAnimationFrame(on);
    window.addEventListener("scroll", on, { passive: true });
    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener("scroll", on);
    };
  }, []);
  useEffect(() => {
    document.documentElement.style.overflow = open ? "hidden" : "";
    return () => {
      document.documentElement.style.overflow = "";
    };
  }, [open]);

  const active = NAV.find((n) => pathname === n.href || pathname.startsWith(n.href + "/"))?.href;

  return (
    <>
      <header className={`sticky top-0 z-50 border-b transition-colors duration-300 ${scrolled ? "border-bone/10 bg-char/85 backdrop-blur-xl" : "border-transparent bg-char"}`}>
        <div className="wrap flex h-[72px] items-center justify-between gap-6">
          <Link href="/" aria-label="GaitGuard home" className="shrink-0">
            <Logo />
          </Link>

          <nav aria-label="Primary" className="hidden items-center gap-9 lg:flex" onMouseLeave={() => setHovered(null)}>
            {NAV.map((n) => {
              const isActive = active === n.href;
              return (
                <Link key={n.href} href={n.href} onMouseEnter={() => setHovered(n.href)} aria-current={isActive ? "page" : undefined} className={`relative py-2 text-[0.95rem] font-semibold transition-colors duration-200 ${isActive || hovered === n.href ? "text-bone" : "text-ash"}`}>
                  {n.label}
                  {isActive && <motion.span layoutId="nav-underline" className="absolute inset-x-0 -bottom-[1px] h-[2px] rounded-full bg-ember" transition={{ type: "spring", stiffness: 420, damping: 36 }} />}
                </Link>
              );
            })}
          </nav>

          <div className="flex items-center gap-3">
            <div className="hidden lg:block">
              <Button href="/pilot" className="!min-h-[44px] !px-5 !text-[0.9rem]">Join the pilot</Button>
            </div>
            <button type="button" onClick={() => setOpen((o) => !o)} aria-expanded={open} aria-label={open ? "Close menu" : "Open menu"} className="relative flex h-11 w-11 items-center justify-center rounded-full border border-bone/20 lg:hidden">
              <motion.span className="absolute h-[2px] w-5 rounded bg-bone" animate={{ rotate: open ? 45 : 0, y: open ? 0 : -4 }} transition={{ duration: 0.3 }} />
              <motion.span className="absolute h-[2px] w-5 rounded bg-bone" animate={{ rotate: open ? -45 : 0, y: open ? 0 : 4 }} transition={{ duration: 0.3 }} />
            </button>
          </div>
        </div>
      </header>

      <AnimatePresence>
        {open && (
          <motion.div id="mobile-menu" className="fixed inset-0 z-40 flex flex-col bg-char px-[var(--pad)] pb-10 pt-[96px] lg:hidden" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.3 }}>
            <nav aria-label="Mobile" className="flex flex-col">
              {[{ href: "/", label: "Home" }, ...NAV].map((n, i) => (
                <motion.div key={n.href} initial={{ opacity: 0, y: 18 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.06 + i * 0.05, duration: 0.5, ease: [0.22, 1, 0.36, 1] }}>
                  <Link href={n.href} onClick={() => setOpen(false)} className={`block border-b border-bone/10 py-4 font-[family-name:var(--font-fraunces)] text-[2rem] font-medium tracking-tight ${pathname === n.href ? "text-ember" : "text-bone"}`}>
                    {n.label}
                  </Link>
                </motion.div>
              ))}
            </nav>
            <motion.div className="mt-auto" initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.4 }}>
              <Button href="/pilot" className="w-full">Join the pilot</Button>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
