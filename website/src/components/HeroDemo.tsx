"use client";

import { useEffect, useRef, useState } from "react";
import { Phone, Watch } from "./Devices";
import { clockTime, type Cue, type DemoState } from "@/lib/demo";
import { useReducedMotion } from "@/lib/useReducedMotion";

const STATIC: DemoState = {
  monitoring: true,
  score: 92,
  steps: 1284,
  cadence: 108,
  cues: [
    { id: 2, type: "Turn", time: "9:38 AM" },
    { id: 1, type: "Start", time: "9:31 AM" },
  ],
  flash: null,
};

/** Self-playing walk: both devices render from the same state object, like the real apps. */
export function HeroDemo() {
  const reduced = useReducedMotion();
  const [s, setS] = useState<DemoState>({ ...STATIC, cues: [], steps: 1180, score: 88 });
  const tick = useRef(0);

  useEffect(() => {
    if (reduced) return;
    let flashTimer: ReturnType<typeof setTimeout> | undefined;
    const t = setInterval(() => {
      const n = ++tick.current;
      const isCue = n % 7 === 0;
      const cue: Cue | null = isCue
        ? { id: n, type: (n / 7) % 2 ? "Start" : "Turn", time: clockTime() }
        : null;
      setS((p) => ({
        ...p,
        steps: p.steps + 2 + (n % 2),
        cadence: 106 + Math.round(Math.sin(n / 2.2) * 5),
        score: cue ? Math.max(70, p.score - 9) : Math.min(95, p.score + 1),
        cues: cue ? [cue, ...p.cues].slice(0, 3) : p.cues,
        flash: cue ?? p.flash,
      }));
      if (cue) {
        clearTimeout(flashTimer);
        flashTimer = setTimeout(() => setS((p) => ({ ...p, flash: null })), 1800);
      }
    }, 1100);
    return () => {
      clearInterval(t);
      clearTimeout(flashTimer);
    };
  }, [reduced]);

  const state = reduced ? STATIC : s;

  return (
    <div
      className="relative flex items-end justify-center"
      role="img"
      aria-label="The GaitGuard iPhone and Apple Watch apps showing the same live gait score and cue history."
    >
      <Phone s={state} />
      <Watch s={state} className="float -ml-14 mb-10 sm:-ml-10" />
    </div>
  );
}
