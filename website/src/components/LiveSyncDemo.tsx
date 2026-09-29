"use client";

import { useEffect, useMemo, useRef, useState, useSyncExternalStore } from "react";

type Cue = { id: number; type: "Start" | "Turn"; time: string };

const CUE_EVERY = 5; // ticks between simulated freeze cues

function scoreLabel(score: number) {
  if (score >= 85) return "Steady";
  if (score >= 65) return "Supported";
  if (score >= 40) return "Assisting";
  return "High support";
}

function scoreColor(score: number) {
  if (score >= 85) return "#4ade9a";
  if (score >= 65) return "#7c8cff";
  if (score >= 40) return "#ffb547";
  return "#ff6b7a";
}

/**
 * One shared state object drives both the Watch and the iPhone mock, which is
 * exactly how the real apps behave: every change is mirrored on both surfaces.
 */
function subscribeReducedMotion(cb: () => void) {
  const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
  mq.addEventListener("change", cb);
  return () => mq.removeEventListener("change", cb);
}

export function LiveSyncDemo() {
  const reduced = useSyncExternalStore(
    subscribeReducedMotion,
    () => window.matchMedia("(prefers-reduced-motion: reduce)").matches,
    () => false,
  );
  const [tick, setTick] = useState(0);
  const tickRef = useRef(0);
  const [cues, setCues] = useState<Cue[]>([]);
  const [flash, setFlash] = useState<Cue | null>(null);

  useEffect(() => {
    if (reduced) return;
    let clear: ReturnType<typeof setTimeout> | undefined;
    const t = setInterval(() => {
      const next = ++tickRef.current;
      setTick(next);
      if (next % CUE_EVERY === 0) {
        const cue: Cue = {
          id: next,
          type: (next / CUE_EVERY) % 2 ? "Start" : "Turn",
          time: new Date().toLocaleTimeString([], { hour: "numeric", minute: "2-digit" }),
        };
        setCues((c) => [cue, ...c].slice(0, 3));
        setFlash(cue);
        clearTimeout(clear);
        clear = setTimeout(() => setFlash(null), 1800);
      }
    }, 1200);
    return () => {
      clearInterval(t);
      clearTimeout(clear);
    };
  }, [reduced]);

  const steps = 1240 + tick * 3;
  const cadence = 108 + Math.round(Math.sin(tick / 2) * 5);
  const assistCount = reduced ? 3 : cues.length + 2;
  const score = useMemo(() => {
    if (reduced) return 92;
    const sinceCue = tick % CUE_EVERY;
    const dip = flash ? 9 : 0;
    return Math.max(0, Math.min(100, 92 - dip + Math.min(sinceCue, 3)));
  }, [tick, flash, reduced]);

  const color = scoreColor(score);
  const circumference = 2 * Math.PI * 44;
  const shownCues: Cue[] = reduced
    ? [
        { id: 1, type: "Turn", time: "9:42 AM" },
        { id: 2, type: "Start", time: "9:31 AM" },
      ]
    : cues;

  return (
    <div
      className="relative mx-auto flex w-full max-w-[860px] flex-col items-center justify-center gap-8 sm:flex-row sm:gap-10"
      role="img"
      aria-label="Animated demo: the Apple Watch and iPhone show the same gait score and cue events in real time."
    >
      {/* iPhone */}
      <div className="relative w-[270px] shrink-0 sm:w-[290px]">
        <div className="rounded-[44px] border border-white/10 bg-[#05060c] p-2.5 shadow-[0_50px_100px_-40px_rgba(124,140,255,0.55)]">
          <div className="relative overflow-hidden rounded-[36px] bg-[#0a0b14] px-4 pb-5 pt-9">
            <div className="absolute left-1/2 top-2.5 h-5 w-20 -translate-x-1/2 rounded-full bg-black" />
            <div className="flex items-center justify-between">
              <span className="inline-flex items-center gap-1.5 rounded-full bg-[#4ade9a]/12 px-2.5 py-1 text-[10px] font-semibold text-good">
                <span className="relative h-1.5 w-1.5 rounded-full bg-good pulse-dot text-good" />
                Watch connected
              </span>
              <span className="text-[10px] text-text-3">Live</span>
            </div>

            <div className="relative mx-auto mt-4 h-[150px] w-[150px]">
              <Ring score={score} color={color} circumference={circumference} big />
            </div>

            <div className="mt-4 rounded-2xl bg-white/[0.04] p-3">
              <div className="flex items-center justify-between text-[10px] text-text-3">
                <span>Today&apos;s support</span>
                <span className="font-semibold text-cue">{assistCount} cues</span>
              </div>
              <div className="mt-2 grid grid-cols-2 gap-2 text-center">
                <Stat label="Steps" value={steps.toLocaleString()} />
                <Stat label="Cadence" value={`${cadence} spm`} />
              </div>
            </div>

            <ul className="mt-3 space-y-1.5" aria-hidden="true">
              {shownCues.length === 0 && (
                <li className="rounded-xl bg-white/[0.03] px-3 py-2 text-[10px] text-text-3">
                  Waiting for the next cue…
                </li>
              )}
              {shownCues.map((c) => (
                <li
                  key={c.id}
                  className="anim-slide flex items-center justify-between rounded-xl bg-white/[0.04] px-3 py-2 text-[11px]"
                >
                  <span className="flex items-center gap-2 font-medium text-text">
                    <span
                      className="h-2 w-2 rounded-full"
                      style={{ background: c.type === "Turn" ? "#b58cff" : "#ffb547" }}
                    />
                    {c.type} cue
                  </span>
                  <span className="text-text-3">{c.time}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>

      {/* sync link */}
      <div className="hidden flex-col items-center gap-2 sm:flex" aria-hidden="true">
        <span className="text-[10px] font-semibold uppercase tracking-[0.18em] text-text-3">Synced</span>
        <div className="relative h-px w-16 bg-gradient-to-r from-accent/0 via-accent to-accent/0">
          <span
            key={tick}
            className="absolute -top-[3px] h-[7px] w-[7px] rounded-full bg-accent"
            style={{ animation: reduced ? "none" : "sync-dot 1.2s linear" }}
          />
        </div>
      </div>

      {/* Watch */}
      <div className="anim-float relative w-[150px] shrink-0 sm:w-[176px]">
        <div className="rounded-[42px] border border-white/10 bg-[#171a26] p-2.5 shadow-[0_40px_80px_-30px_rgba(181,140,255,0.5)]">
          <div className="relative aspect-[4/5] overflow-hidden rounded-[34px] bg-black p-3">
            {flash && (
              <div className="anim-slide absolute left-1/2 top-2 z-10 -translate-x-1/2 rounded-full bg-cue px-2.5 py-1 text-[9px] font-bold text-black">
                Cue · {flash.type}
              </div>
            )}
            <div className="mt-3 flex items-center justify-between text-[9px] font-semibold text-text-2">
              <span>Synced</span>
              <span className="h-1.5 w-1.5 rounded-full bg-good" />
            </div>
            <div className="mx-auto mt-2 h-[92px] w-[92px]">
              <Ring score={score} color={color} circumference={circumference} />
            </div>
            <div className="mt-3 rounded-full bg-danger/85 py-1.5 text-center text-[10px] font-extrabold tracking-wider text-white">
              STOP
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-[13px] font-semibold tabular-nums text-text">{value}</p>
      <p className="text-[9px] text-text-3">{label}</p>
    </div>
  );
}

function Ring({
  score,
  color,
  circumference,
  big,
}: {
  score: number;
  color: string;
  circumference: number;
  big?: boolean;
}) {
  return (
    <svg viewBox="0 0 100 100" className="h-full w-full -rotate-90">
      <circle cx="50" cy="50" r="44" fill="none" stroke="rgba(255,255,255,0.08)" strokeWidth={big ? 8 : 9} />
      <circle
        cx="50"
        cy="50"
        r="44"
        fill="none"
        stroke={color}
        strokeWidth={big ? 8 : 9}
        strokeLinecap="round"
        strokeDasharray={circumference}
        strokeDashoffset={circumference * (1 - score / 100)}
        style={{ transition: "stroke-dashoffset 0.8s ease, stroke 0.8s ease", filter: `drop-shadow(0 0 6px ${color}66)` }}
      />
      <g transform="rotate(90 50 50)" textAnchor="middle" fill="#f4f5fb">
        <text x="50" y={big ? 48 : 52} fontSize={big ? 26 : 28} fontWeight="700">
          {score}
        </text>
        <text x="50" y={big ? 62 : 66} fontSize={big ? 7 : 8} fill={color} fontWeight="600">
          {scoreLabel(score)}
        </text>
      </g>
    </svg>
  );
}
