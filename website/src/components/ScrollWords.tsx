"use client";

import { motion, useScroll, useTransform, type MotionValue } from "motion/react";
import { useRef } from "react";

function Word({ word, i, n, progress }: { word: string; i: number; n: number; progress: MotionValue<number> }) {
  const start = i / n;
  const end = Math.min(1, start + 1.6 / n);
  const opacity = useTransform(progress, [start, end], [0.22, 1]);
  return (
    <motion.span style={{ opacity }} className="inline-block whitespace-pre">
      {word}{" "}
    </motion.span>
  );
}

/** A statement whose words light up as you scroll through it. */
export function ScrollWords({ text, className = "" }: { text: string; className?: string }) {
  const ref = useRef<HTMLParagraphElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start 0.85", "end 0.45"] });
  const words = text.split(" ");
  return (
    <p ref={ref} className={className} aria-label={text}>
      <span aria-hidden="true">
        {words.map((w, i) => (
          <Word key={i} word={w} i={i} n={words.length} progress={scrollYProgress} />
        ))}
      </span>
    </p>
  );
}
