"use client";

import { useEffect, useRef, useState } from "react";
import { Phone, Watch } from "./Devices";
import { clockTime, initialDemo, type CueType, type DemoState } from "@/lib/demo";

type Dir = "toWatch" | "toPhone";
type LogItem = { id: number; dir: Dir; text: string };

export function SyncPlayground() {
  const [s, setS] = useState<DemoState>(initialDemo);
  const [log, setLog] = useState<LogItem[]>([]);
  const nextId = useRef(1);
  const flashTimer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);

  const push = (dir: Dir, text: string) => {
    const id = nextId.current++;
    setLog((l) => [{ id, dir, text }, ...l].slice(0, 4));
  };

  const toggle = (from: "phone" | "watch") => {
    const starting = !s.monitoring;
    setS((p) =>
      starting
        ? { ...p, monitoring: true, score: 90, cadence: 104 }
        : { ...p, monitoring: false, score: 0, cadence: 0, flash: null },
    );
    push(
      from === "phone" ? "toWatch" : "toPhone",
      `${starting ? "Start" : "Stop"} from ${from === "phone" ? "iPhone" : "Watch"}`,
    );
  };

  const freeze = () => {
    if (!s.monitoring) return;
    const id = nextId.current;
    const type: CueType = s.cues.length % 2 ? "Turn" : "Start";
    setS((p) => ({
      ...p,
      score: Math.max(35, p.score - 12),
      cues: [{ id, type, time: clockTime() }, ...p.cues].slice(0, 3),
      flash: { id, type, time: "" },
    }));
    push("toPhone", `${type} cue delivered`);
    clearTimeout(flashTimer.current);
    flashTimer.current = setTimeout(() => setS((p) => ({ ...p, flash: null })), 1800);
  };

  const reset = () => {
    setS(initialDemo);
    setLog([]);
  };

  // Live walk while monitoring: steps, cadence and a slow score recovery.
  useEffect(() => {
    if (!s.monitoring) return;
    const t = setInterval(() => {
      setS((p) => ({
        ...p,
        steps: p.steps + 3,
        cadence: 104 + Math.round(Math.random() * 8),
        score: Math.min(96, p.score + 1),
      }));
    }, 1000);
    return () => clearInterval(t);
  }, [s.monitoring]);

  useEffect(() => () => clearTimeout(flashTimer.current), []);

  const latest = log[0];

  return (
    <div>
      <div className="flex justify-center">
      <div className="-mb-[176px] flex origin-top scale-[0.68] flex-row items-center gap-4 sm:mb-0 sm:scale-100 lg:gap-6">
        <Phone s={s} onToggle={() => toggle("phone")} />

        <div className="hidden w-[200px] flex-col items-center gap-3 lg:flex" aria-hidden="true">
          <div className="relative h-[3px] w-full rounded-full bg-white/10">
            {latest && (
              <span
                key={latest.id}
                className={`absolute -top-[5px] h-[13px] w-[13px] -translate-x-1/2 rounded-full bg-indigo-soft shadow-[0_0_14px_#7c8cff] ${
                  latest.dir === "toWatch" ? "travel" : "travel-rev"
                }`}
              />
            )}
          </div>
          <p className="text-[0.68rem] font-semibold uppercase tracking-[0.18em] text-white/40">WatchConnectivity</p>
        </div>

        <Watch s={s} onToggle={() => toggle("watch")} />
      </div>
      </div>

      <div className="mx-auto mt-12 flex max-w-[720px] flex-col gap-5">
        <div className="flex flex-wrap items-center justify-center gap-3">
          <button type="button" onClick={() => toggle("phone")} className="btn bg-white text-night hover:-translate-y-px">
            {s.monitoring ? "Stop" : "Start"} from iPhone
          </button>
          <button type="button" onClick={() => toggle("watch")} className="btn border border-white/15 text-white hover:border-white/40">
            {s.monitoring ? "Stop" : "Start"} from Watch
          </button>
          <button
            type="button"
            onClick={freeze}
            disabled={!s.monitoring}
            className="btn border border-cue-soft/40 text-cue-soft transition hover:bg-cue-soft/10 disabled:cursor-not-allowed disabled:opacity-35"
          >
            Simulate a freeze
          </button>
          {log.length > 0 && (
            <button type="button" onClick={reset} className="text-sm font-medium text-white/50 underline-offset-4 hover:text-white hover:underline">
              Reset
            </button>
          )}
        </div>

        <ol className="min-h-[132px] space-y-2" aria-live="polite" aria-label="Sync log">
          {log.length === 0 && (
            <li className="rounded-2xl border border-dashed border-white/12 px-5 py-4 text-center text-[0.9rem] text-white/45">
              Press start on either device. Watch the other one follow.
            </li>
          )}
          {log.map((item) => (
            <li
              key={item.id}
              className="drop-in flex flex-wrap items-center gap-x-3 gap-y-1 rounded-2xl bg-white/[0.05] px-5 py-3 text-[0.9rem]"
            >
              <span className="font-mono text-[0.75rem] text-indigo-soft">
                {item.dir === "toWatch" ? "iPhone → Watch" : "Watch → iPhone"}
              </span>
              <span className="text-white/85">{item.text}</span>
              <span className="ml-auto text-[0.75rem] text-good">✓ mirrored</span>
            </li>
          ))}
        </ol>
      </div>
    </div>
  );
}
