"use client";

import { AnimatePresence, animate, motion } from "motion/react";
import { useCallback, useEffect, useRef, useState } from "react";
import { useReducedMotion } from "@/lib/useReducedMotion";

const N = 60;
const SIZE = 320;
const C = SIZE / 2;
const R = 150;
const TEMPO = 100; // bpm, the app's default cue tempo
const SCORE = 86;

type RGB = [number, number, number];
const SAGE: RGB = [166, 204, 154];
const EMBER: RGB = [255, 122, 77];
const SOOT: RGB = [107, 99, 91];

const mix = (a: RGB, b: RGB, t: number): RGB => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t];
const rgb = (c: RGB) => `rgb(${Math.round(c[0])},${Math.round(c[1])},${Math.round(c[2])})`;

/**
 * The app's tick dial: 60 ticks like a metronome bezel. Filled ticks are the steadiness score,
 * and one ember tick sweeps at the cue tempo. Tap to start a simulated walk. Animation is optional.
 */
export function TickDial({ className = "" }: { className?: string }) {
  const [running, setRunning] = useState(false);
  const [userPaused, setUserPaused] = useState(false);
  const reducedPref = useReducedMotion();
  const still = reducedPref || userPaused;
  const ticks = useRef<(SVGLineElement | null)[]>([]);
  const scoreRef = useRef<HTMLSpanElement>(null);
  const score = useRef(0);

  const writeScore = useCallback((v: number) => {
    score.current = v;
    if (scoreRef.current) scoreRef.current.textContent = String(Math.round(v));
  }, []);

  // Tween the score when starting or stopping.
  useEffect(() => {
    const target = running ? SCORE : 0;
    if (still) {
      writeScore(target);
      return;
    }
    const controls = animate(score.current, target, { duration: running ? 1.6 : 0.5, ease: [0.22, 1, 0.36, 1], onUpdate: writeScore });
    return () => controls.stop();
  }, [running, still, writeScore]);

  // Paint loop: writes straight to the DOM so React doesn't re-render every frame.
  useEffect(() => {
    const paint = (now: number) => {
      const t = now / 1000;
      const revsPerSec = running ? Math.max(0.1, TEMPO / 60 / 8) : 0.05;
      const sweep = still ? 0 : ((t * revsPerSec) % 1) * N;
      const filled = running ? Math.round((score.current / 100) * N) : 0;
      for (let i = 0; i < N; i++) {
        const el = ticks.current[i];
        if (!el) continue;
        let d = Math.abs(i - sweep);
        d = Math.min(d, N - d);
        const heat = Math.max(0, 1 - d / 5);
        const major = i % 5 === 0;
        const base: RGB = i < filled ? SAGE : SOOT;
        const baseAlpha = i < filled ? 0.95 : major ? 0.7 : 0.4;
        const out = heat > 0.02 ? mix(base, EMBER, Math.min(1, heat * 1.15)) : base;
        el.setAttribute("stroke", rgb(out));
        el.setAttribute("stroke-opacity", String(Math.min(1, baseAlpha + heat * 0.3)));
        el.setAttribute("stroke-width", String((major ? 4 : 3) + heat * 0.8));
      }
    };
    if (still) {
      paint(0);
      return;
    }
    let raf = requestAnimationFrame(function loop(now) {
      paint(now);
      raf = requestAnimationFrame(loop);
    });
    return () => cancelAnimationFrame(raf);
  }, [running, still]);

  const lines = Array.from({ length: N }, (_, i) => {
    const a = (i / N) * Math.PI * 2 - Math.PI / 2;
    const len = i % 5 === 0 ? 22 : 12;
    const r2 = (v: number) => Math.round(v * 100) / 100; // identical on server and client
    return { i, x1: r2(C + Math.cos(a) * R), y1: r2(C + Math.sin(a) * R), x2: r2(C + Math.cos(a) * (R - len)), y2: r2(C + Math.sin(a) * (R - len)), major: i % 5 === 0 };
  });

  return (
    <div className={`flex w-full max-w-[440px] flex-col items-center ${className}`}>
      <motion.button
        type="button"
        onClick={() => setRunning((r) => !r)}
        aria-pressed={running}
        aria-label={running ? "Stop the simulated walk" : "Start a simulated walk"}
        className="group relative block aspect-square w-full cursor-pointer rounded-full outline-offset-8"
        whileHover={{ scale: 1.015 }}
        whileTap={{ scale: 0.975 }}
        transition={{ type: "spring", stiffness: 300, damping: 22 }}
      >
        <svg viewBox={`0 0 ${SIZE} ${SIZE}`} className="h-full w-full" aria-hidden="true">
          {lines.map((l) => (
            <line
              key={l.i}
              ref={(el) => {
                ticks.current[l.i] = el;
              }}
              x1={l.x1}
              y1={l.y1}
              x2={l.x2}
              y2={l.y2}
              stroke="rgb(107,99,91)"
              strokeOpacity={l.major ? 0.7 : 0.4}
              strokeWidth={l.major ? 4 : 3}
              strokeLinecap="round"
            />
          ))}
        </svg>

        <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center text-center">
          <AnimatePresence mode="wait" initial={false}>
            {running ? (
              <motion.div key="live" initial={{ opacity: 0, scale: 0.94 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.96 }} transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }} className="flex flex-col items-center">
                <span className="label !text-ash">Steadiness</span>
                <span className="num mt-1 text-[clamp(4.5rem,13vw,6.6rem)] leading-none text-bone" ref={scoreRef}>0</span>
                <span className="mt-2 text-[0.95rem] font-semibold text-sage">Steady</span>
              </motion.div>
            ) : (
              <motion.div key="idle" initial={{ opacity: 0, scale: 0.94 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.96 }} transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }} className="flex flex-col items-center">
                <svg width="46" height="52" viewBox="0 0 46 52" aria-hidden="true" className="transition-transform duration-500 group-hover:scale-110">
                  <path d="M6 5.2c0-2.4 2.6-3.9 4.7-2.7l31.4 20.8c1.9 1.3 1.9 4.2 0 5.4L10.7 49.5C8.6 50.7 6 49.2 6 46.8z" fill="#ff7a4d" />
                </svg>
                <span className="mt-3 text-[0.78rem] font-bold tracking-[0.2em] text-bone">START</span>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </motion.button>

      <div className="mt-6 flex flex-col items-center gap-2 text-center">
        <p className="text-[0.9rem] text-ash">{running ? "Tap the dial to stop." : "Tap the dial to try a simulated walk."}</p>
        {!reducedPref && (
          <button type="button" onClick={() => setUserPaused((p) => !p)} aria-pressed={userPaused} className="text-[0.85rem] font-bold text-bone underline decoration-bone/30 underline-offset-4 transition hover:decoration-ember">
            {userPaused ? "Play animation" : "Pause animation"}
          </button>
        )}
      </div>
    </div>
  );
}
