"use client";

import { AnimatePresence, animate, motion } from "motion/react";
import { useCallback, useEffect, useRef, useState } from "react";
import { useReducedMotion } from "@/lib/useReducedMotion";

const N = 60;
const SIZE = 320;
const C = SIZE / 2;
const R = 150;
const BPM = 100;
const TICKS_PER_SEC = (BPM / 60) * 5; // one major tick per beat

type RGB = [number, number, number];
const BONE: RGB = [244, 238, 230];
const AMBER: RGB = [242, 179, 94];
const EMBER: RGB = [255, 122, 77];
const BASE: RGB = [78, 70, 63];

const mix = (a: RGB, b: RGB, t: number): RGB => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t];
const rgb = (c: RGB) => `rgb(${Math.round(c[0])},${Math.round(c[1])},${Math.round(c[2])})`;

/** The gait-score dial from the app: 60 ticks that sweep at the cue tempo. Click it to start a simulated walk. */
export function TickDial({ className = "" }: { className?: string }) {
  const [running, setRunning] = useState(false);
  const reduced = useReducedMotion();
  const [cueing, setCueing] = useState(false);
  const ticks = useRef<(SVGLineElement | null)[]>([]);
  const scoreRef = useRef<HTMLSpanElement>(null);
  const score = useRef(0);
  const cueAt = useRef(0);

  const writeScore = useCallback((v: number) => {
    score.current = v;
    if (scoreRef.current) scoreRef.current.textContent = String(Math.round(v));
  }, []);

  // Tween the score when starting/stopping.
  useEffect(() => {
    const target = running ? 82 : 0;
    if (reduced) {
      writeScore(target);
      return;
    }
    const controls = animate(score.current, target, { duration: running ? 1.8 : 0.5, ease: [0.22, 1, 0.36, 1], onUpdate: writeScore });
    return () => controls.stop();
  }, [running, reduced, writeScore]);

  // Schedule a cue every few seconds while running.
  useEffect(() => {
    if (!running || reduced) return;
    let t2: ReturnType<typeof setTimeout>;
    const fire = () => {
      cueAt.current = performance.now();
      setCueing(true);
      const dip = animate(score.current, 71, { duration: 0.4, onUpdate: writeScore });
      t2 = setTimeout(() => {
        dip.stop();
        setCueing(false);
        animate(score.current, 82, { duration: 2.2, ease: [0.22, 1, 0.36, 1], onUpdate: writeScore });
      }, 1700);
    };
    const first = setTimeout(fire, 3600);
    const loop = setInterval(fire, 9000);
    return () => {
      clearTimeout(first);
      clearInterval(loop);
      clearTimeout(t2);
      setCueing(false);
    };
  }, [running, reduced, writeScore]);

  // Paint loop: writes straight to the DOM so React doesn't re-render 60 times a second.
  useEffect(() => {
    const paint = (now: number) => {
      const t = now / 1000;
      const speed = running ? TICKS_PER_SEC : 0.9;
      const head = reduced ? 41 : (t * speed) % N;
      for (let i = 0; i < N; i++) {
        const el = ticks.current[i];
        if (!el) continue;
        let d = head - i;
        if (d < 0) d += N;
        const reach = running ? 30 : 16;
        const lit = Math.max(0, 1 - d / reach);
        const eased = lit * lit;
        const major = i % 5 === 0;
        let color: RGB;
        if (d < reach * 0.12) color = mix(BONE, AMBER, d / (reach * 0.12));
        else color = mix(AMBER, EMBER, Math.min(1, (d - reach * 0.12) / (reach * 0.88)));
        const strength = (running ? 1 : 0.55) * eased;
        const out = mix(BASE, color, Math.min(1, strength * 1.2));
        const alpha = (major ? 0.62 : 0.4) + strength * 0.55;
        el.setAttribute("stroke", rgb(out));
        el.setAttribute("stroke-opacity", String(Math.min(1, alpha)));
      }
    };
    if (reduced) {
      paint(0);
      return;
    }
    let raf = requestAnimationFrame(function loop(now) {
      paint(now);
      raf = requestAnimationFrame(loop);
    });
    return () => cancelAnimationFrame(raf);
  }, [running, reduced]);

  const lines = Array.from({ length: N }, (_, i) => {
    const a = (i / N) * Math.PI * 2 - Math.PI / 2;
    const len = i % 5 === 0 ? 22 : 12;
    const r2 = (v: number) => Math.round(v * 100) / 100; // identical on server and client
    return { i, x1: r2(C + Math.cos(a) * R), y1: r2(C + Math.sin(a) * R), x2: r2(C + Math.cos(a) * (R - len)), y2: r2(C + Math.sin(a) * (R - len)), major: i % 5 === 0 };
  });

  return (
    <motion.button
      type="button"
      onClick={() => setRunning((r) => !r)}
      aria-pressed={running}
      aria-label={running ? "Stop the simulated walk" : "Start a simulated walk"}
      className={`group relative block aspect-square w-full max-w-[440px] cursor-pointer rounded-full outline-offset-8 ${className}`}
      whileHover={{ scale: 1.015 }}
      whileTap={{ scale: 0.975 }}
      transition={{ type: "spring", stiffness: 300, damping: 22 }}
    >
      <svg viewBox={`0 0 ${SIZE} ${SIZE}`} className="relative h-full w-full" aria-hidden="true">
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
            stroke="rgb(78,70,63)"
            strokeOpacity={l.major ? 0.62 : 0.4}
            strokeWidth={l.major ? 4 : 3}
            strokeLinecap="round"
          />
        ))}
      </svg>

      <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center text-center">
        <AnimatePresence mode="wait" initial={false}>
          {running ? (
            <motion.div key="live" initial={{ opacity: 0, scale: 0.94 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.96 }} transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }} className="flex flex-col items-center">
              <span className="label !text-ash">{cueing ? "Cue delivered" : "Gait score"}</span>
              <span className="num mt-1 text-[clamp(4.5rem,13vw,6.6rem)] leading-none text-bone" ref={scoreRef}>0</span>
              <span className="mt-2 text-[0.95rem] font-semibold text-brass">{cueing ? "A steady beat" : "Steady rhythm"}</span>
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
  );
}
