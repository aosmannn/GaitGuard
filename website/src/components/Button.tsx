"use client";

import { motion } from "motion/react";
import Link from "next/link";
import type { ReactNode } from "react";

type Variant = "signal" | "ghost" | "ink";

const spring = { type: "spring", stiffness: 420, damping: 24 } as const;
const MotionLink = motion.create(Link);

export function Button({
  href,
  variant = "signal",
  arrow = false,
  external = false,
  className = "",
  children,
}: {
  href: string;
  variant?: Variant;
  arrow?: boolean;
  external?: boolean;
  className?: string;
  children: ReactNode;
}) {
  const cls = `btn btn-${variant} ${className}`;
  const inner = (
    <>
      {children}
      {arrow && <span className="arrow" aria-hidden="true">→</span>}
    </>
  );
  if (external) {
    return (
      <motion.a href={href} target="_blank" rel="noopener noreferrer" className={cls} whileHover={{ y: -2 }} whileTap={{ scale: 0.96 }} transition={spring}>
        {inner}
      </motion.a>
    );
  }
  return (
    <MotionLink href={href} className={cls} whileHover={{ y: -2 }} whileTap={{ scale: 0.96 }} transition={spring}>
      {inner}
    </MotionLink>
  );
}

/** Same look for real <button>s (forms). */
export function SubmitButton({ children, disabled }: { children: ReactNode; disabled?: boolean }) {
  return (
    <motion.button type="submit" disabled={disabled} className="btn btn-signal disabled:opacity-60" whileHover={disabled ? undefined : { y: -2 }} whileTap={disabled ? undefined : { scale: 0.96 }} transition={spring}>
      {children}
    </motion.button>
  );
}
