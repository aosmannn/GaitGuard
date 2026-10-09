"use client";

import { motion, type HTMLMotionProps } from "motion/react";
import type { ReactNode } from "react";

const ease = [0.22, 1, 0.36, 1] as const;

type Props = {
  children: ReactNode;
  className?: string;
  delay?: number; // ms
  as?: "div" | "li" | "section" | "p" | "h2";
  y?: number;
};

const tags = { div: motion.div, li: motion.li, section: motion.section, p: motion.p, h2: motion.h2 } as const;

/** Fades and rises into view once. Respects reduced motion automatically via the global MotionConfig-free CSS media rule. */
export function Reveal({ children, className = "", delay = 0, as = "div", y = 24 }: Props) {
  const Tag = tags[as] as React.ComponentType<HTMLMotionProps<"div">>;
  return (
    <Tag
      className={className}
      initial={{ opacity: 0, y }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "0px 0px -12% 0px" }}
      transition={{ duration: 0.9, delay: delay / 1000, ease }}
    >
      {children}
    </Tag>
  );
}
