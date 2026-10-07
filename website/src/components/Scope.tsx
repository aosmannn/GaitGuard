"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { useReducedMotion } from "@/lib/useReducedMotion";

type Phase = "walking" | "freeze" | "cueing";

const WINDOW = 7; // seconds of trace on screen
const THRESHOLD = 0.35; // freeze when stride amplitude stays below this
const DETECT_AFTER = 0.9; // seconds below threshold before a freeze is declared
const BEATS = 4;
const BEAT_GAP = 0.6; // 100 bpm
const LOOP_EVERY = 10; // auto-trigger a freeze this often (seconds of walking)

const PHASE_LABEL: Record<Phase, string> = {
  walking: "Walking",
  freeze: "Freeze detected",
  cueing: "Cue delivered",
};

type Beat = { t: number };

/**
 * A simulated wrist-accelerometer trace. Walking is a clean ~1.8 Hz stride; a freeze collapses the
 * amplitude into a fast tremor; after detection a four-beat haptic cue plays and the stride recovers.
 * It is an illustration of the idea, not recorded patient data.
 */
export function Scope() {
  const reduced = useReducedMotion();
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const wrapRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<() => void>(() => {});
  const [ui, setUi] = useState<{ phase: Phase; cues: number; cadence: number | null }>({
    phase: "walking",
    cues: 0,
    cadence: 108,
  });

  const draw = useCallback(
    (ctx: CanvasRenderingContext2D, w: number, h: number, pts: { t: number; y: number }[], now: number, beats: Beat[], phase: Phase) => {
      ctx.clearRect(0, 0, w, h);
      const mid = h * 0.5;
      const amp = h * 0.36;
      const x = (t: number) => ((t - (now - WINDOW)) / WINDOW) * w;

      // graticule
      ctx.lineWidth = 1;
      ctx.strokeStyle = "rgba(160,170,255,0.08)";
      for (let i = 0; i <= WINDOW * 2; i++) {
        const gx = Math.round((i / (WINDOW * 2)) * w) + 0.5;
        ctx.beginPath();
        ctx.moveTo(gx, 0);
        ctx.lineTo(gx, h);
        ctx.stroke();
      }
      for (let i = 0; i <= 8; i++) {
        const gy = Math.round((i / 8) * h) + 0.5;
        ctx.beginPath();
        ctx.moveTo(0, gy);
        ctx.lineTo(w, gy);
        ctx.stroke();
      }
      ctx.strokeStyle = "rgba(160,170,255,0.2)";
      ctx.beginPath();
      ctx.moveTo(0, mid + 0.5);
      ctx.lineTo(w, mid + 0.5);
      ctx.stroke();

      // threshold band
      ctx.setLineDash([5, 5]);
      ctx.strokeStyle = "rgba(255,181,71,0.45)";
      for (const s of [-1, 1]) {
        ctx.beginPath();
        ctx.moveTo(0, mid + s * THRESHOLD * amp);
        ctx.lineTo(w, mid + s * THRESHOLD * amp);
        ctx.stroke();
      }
      ctx.setLineDash([]);

      // cue beats
      for (const b of beats) {
        const bx = x(b.t);
        if (bx < 0 || bx > w) continue;
        const age = now - b.t;
        ctx.fillStyle = "rgba(255,181,71,0.12)";
        ctx.fillRect(bx - 1, 0, 2, h);
        ctx.strokeStyle = `rgba(255,181,71,${Math.max(0, 0.7 - age * 0.9)})`;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(bx, mid, 6 + Math.min(age, 0.8) * 46, 0, Math.PI * 2);
        ctx.stroke();
        ctx.fillStyle = "#ffb547";
        ctx.beginPath();
        ctx.arc(bx, 14, 4, 0, Math.PI * 2);
        ctx.fill();
      }

      // trace
      if (pts.length > 1) {
        ctx.lineWidth = 2.2;
        ctx.lineJoin = "round";
        const grad = ctx.createLinearGradient(0, 0, w, 0);
        grad.addColorStop(0, "rgba(124,140,255,0)");
        grad.addColorStop(0.25, "rgba(124,140,255,0.9)");
        grad.addColorStop(1, phase === "freeze" ? "#ff6b7a" : "#9db0ff");
        ctx.strokeStyle = grad;
        ctx.shadowColor = phase === "freeze" ? "rgba(255,107,122,0.6)" : "rgba(124,140,255,0.7)";
        ctx.shadowBlur = 10;
        ctx.beginPath();
        pts.forEach((p, i) => {
          const px = x(p.t);
          const py = mid - p.y * amp;
          if (i === 0) ctx.moveTo(px, py);
          else ctx.lineTo(px, py);
        });
        ctx.stroke();
        ctx.shadowBlur = 0;
      }
    },
    [],
  );

  useEffect(() => {
    const canvas = canvasRef.current;
    const wrap = wrapRef.current;
    if (!canvas || !wrap) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let w = 0;
    let h = 0;
    const resize = () => {
      const r = wrap.getBoundingClientRect();
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      w = r.width;
      h = r.height;
      canvas.width = Math.round(w * dpr);
      canvas.height = Math.round(h * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    };
    resize();
    const ro = new ResizeObserver(resize);
    ro.observe(wrap);

    // Static frame for reduced motion: a walking trace that has just been cued.
    if (reduced) {
      const pts: { t: number; y: number }[] = [];
      for (let t = 0; t <= WINDOW; t += 0.02) {
        const rec = t < 2.2 ? 1 : t < 3.6 ? 0.12 : Math.min(1, 0.12 + (t - 3.6) * 0.6);
        pts.push({ t, y: rec * Math.sin(2 * Math.PI * 1.8 * t) + (t >= 2.2 && t < 3.6 ? 0.12 * Math.sin(2 * Math.PI * 6.5 * t) : 0) });
      }
      draw(ctx, w, h, pts, WINDOW, [{ t: 3.7 }, { t: 4.3 }, { t: 4.9 }, { t: 5.5 }], "cueing");
      return () => ro.disconnect();
    }

    const pts: { t: number; y: number }[] = [];
    const beats: Beat[] = [];
    let phase: Phase = "walking";
    let now = WINDOW;
    let last = performance.now();
    let amp = 1;
    let gaitPhase = 2 * Math.PI * 1.8 * WINDOW;
    // Start with a full screen of steady walking so the trace never begins empty.
    for (let t = 0; t < WINDOW; t += 0.02) {
      const ph = 2 * Math.PI * 1.8 * t;
      pts.push({ t, y: (Math.sin(ph) + 0.28 * Math.sin(ph * 2 + 0.7)) * 0.82 });
    }
    let lowFor = 0;
    let walkFor = 0;
    let cueStart = 0;
    let beatsFired = 0;
    let cues = 0;
    let raf = 0;
    let lastUi = 0;

    const startFreeze = () => {
      if (phase !== "walking") return;
      phase = "freeze";
      lowFor = 0;
    };
    triggerRef.current = startFreeze;

    const frame = (tNow: number) => {
      const dt = Math.min(0.05, (tNow - last) / 1000);
      last = tNow;
      now += dt;

      // target amplitude by phase
      const target = phase === "freeze" || (phase === "cueing" && now - cueStart < BEATS * BEAT_GAP + 0.2) ? 0.1 : 1;
      amp += (target - amp) * Math.min(1, dt * (target > amp ? 1.6 : 6));

      gaitPhase += dt * 2 * Math.PI * 1.8;
      const tremor = (1 - Math.min(1, amp)) * 0.16 * Math.sin(now * 2 * Math.PI * 6.5);
      const y = amp * (Math.sin(gaitPhase) + 0.28 * Math.sin(gaitPhase * 2 + 0.7)) * 0.82 + tremor + (Math.random() - 0.5) * 0.03;
      pts.push({ t: now, y });
      while (pts.length && pts[0].t < now - WINDOW) pts.shift();
      while (beats.length && beats[0].t < now - WINDOW) beats.shift();

      if (phase === "walking") {
        walkFor += dt;
        if (walkFor > LOOP_EVERY) {
          walkFor = 0;
          startFreeze();
        }
      } else if (phase === "freeze") {
        lowFor = amp < THRESHOLD ? lowFor + dt : 0;
        if (lowFor > DETECT_AFTER) {
          phase = "cueing";
          cueStart = now;
          beatsFired = 0;
        }
      } else if (phase === "cueing") {
        while (beatsFired < BEATS && now - cueStart >= beatsFired * BEAT_GAP) {
          beats.push({ t: cueStart + beatsFired * BEAT_GAP });
          beatsFired++;
          if (beatsFired === 1) cues++;
          if (typeof navigator !== "undefined" && "vibrate" in navigator) navigator.vibrate(30);
        }
        if (beatsFired >= BEATS && amp > 0.85) {
          phase = "walking";
          walkFor = 0;
        }
      }

      draw(ctx, w, h, pts, now, beats, phase);

      if (tNow - lastUi > 200) {
        lastUi = tNow;
        setUi((u) => {
          const cadence = phase === "walking" ? 106 + Math.round(Math.sin(now / 2) * 3) : null;
          return u.phase === phase && u.cues === cues && u.cadence === cadence ? u : { phase, cues, cadence };
        });
      }
      raf = requestAnimationFrame(frame);
    };
    raf = requestAnimationFrame(frame);

    const onVis = () => {
      last = performance.now();
    };
    document.addEventListener("visibilitychange", onVis);
    return () => {
      cancelAnimationFrame(raf);
      ro.disconnect();
      document.removeEventListener("visibilitychange", onVis);
      triggerRef.current = () => {};
    };
  }, [reduced, draw]);

  const status =
    ui.phase === "walking" ? "bg-good text-good" : ui.phase === "freeze" ? "bg-danger text-danger" : "bg-cue text-cue";

  return (
    <figure className="fig" aria-label="Simulated wrist accelerometer trace showing a walking rhythm, a freeze, and a haptic cue">
      <div className="overflow-hidden rounded-[6px] border border-ink/80 bg-night text-white shadow-[0_40px_80px_-50px_rgba(16,17,25,0.7)]">
        <div className="flex items-center justify-between border-b border-white/10 px-4 py-2.5">
          <span className="label truncate !text-white/50">CH1 · wrist accel · 50 Hz</span>
          <span className="flex shrink-0 items-center gap-2 whitespace-nowrap mono text-[0.7rem] uppercase tracking-[0.12em]" role="status" aria-live="polite">
            <span className={`blink h-2 w-2 rounded-full ${status.split(" ")[0]}`} />
            <span className={status.split(" ")[1]}>{PHASE_LABEL[ui.phase]}</span>
          </span>
        </div>

        <div ref={wrapRef} className="relative h-[250px] sm:h-[290px]">
          <canvas ref={canvasRef} className="absolute inset-0 h-full w-full" aria-hidden="true" />
          <span className="label absolute right-3 top-2 !text-cue/80">threshold</span>
        </div>

        <div className="grid grid-cols-3 divide-x divide-white/10 border-t border-white/10">
          <div className="px-4 py-3">
            <p className="label !text-white/40">State</p>
            <p className="mono mt-1 text-[0.95rem]">{PHASE_LABEL[ui.phase]}</p>
          </div>
          <div className="px-4 py-3">
            <p className="label !text-white/40">Cadence</p>
            <p className="mono mt-1 text-[0.95rem] tabular-nums">{ui.cadence ? `${ui.cadence} spm` : "—"}</p>
          </div>
          <div className="px-4 py-3">
            <p className="label !text-white/40">Cues</p>
            <p className="mono mt-1 text-[0.95rem] tabular-nums">{ui.cues}</p>
          </div>
        </div>
      </div>
      <span className="tick-b" aria-hidden="true" />

      <figcaption className="mt-5 flex flex-wrap items-center justify-between gap-3">
        <span className="label">Fig. 1 · Simulated signal, for illustration</span>
        <button
          type="button"
          onClick={() => triggerRef.current()}
          disabled={reduced || ui.phase !== "walking"}
          className="mono inline-flex min-h-[40px] items-center gap-2 rounded-[10px] border border-ink/80 bg-card px-4 text-[0.78rem] uppercase tracking-[0.1em] transition hover:bg-ink hover:text-white disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:bg-card disabled:hover:text-ink"
        >
          <span className="h-1.5 w-1.5 rounded-full bg-danger" aria-hidden="true" />
          Trigger a freeze
        </button>
      </figcaption>
    </figure>
  );
}
