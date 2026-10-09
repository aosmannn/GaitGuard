"use client";

import { AnimatePresence, motion } from "motion/react";
import { useState } from "react";

export function Accordion({ items }: { items: { q: string; a: React.ReactNode }[] }) {
  const [open, setOpen] = useState<number | null>(0);
  return (
    <div className="divide-y divide-bone/10 border-y border-bone/10">
      {items.map((it, i) => {
        const isOpen = open === i;
        return (
          <div key={it.q}>
            <button type="button" onClick={() => setOpen(isOpen ? null : i)} aria-expanded={isOpen} className="group flex w-full items-center justify-between gap-6 py-6 text-left">
              <span className="font-[family-name:var(--font-fraunces)] text-[1.35rem] font-medium tracking-tight text-bone transition-colors group-hover:text-brass">{it.q}</span>
              <motion.span animate={{ rotate: isOpen ? 45 : 0 }} transition={{ type: "spring", stiffness: 400, damping: 26 }} className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full border border-bone/20 text-[1.2rem] text-bone" aria-hidden="true">
                +
              </motion.span>
            </button>
            <AnimatePresence initial={false}>
              {isOpen && (
                <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: "auto", opacity: 1 }} exit={{ height: 0, opacity: 0 }} transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }} className="overflow-hidden">
                  <div className="max-w-[44em] pb-7 text-[1.02rem] leading-relaxed text-ash">{it.a}</div>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        );
      })}
    </div>
  );
}
