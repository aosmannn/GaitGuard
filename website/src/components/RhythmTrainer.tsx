"use client";

import { useEffect, useRef, useState } from "react";

const MIN = 60;
const MAX = 130;

export function RhythmTrainer() {
  const [bpm, setBpm] = useState(100);
  const [playing, setPlaying] = useState(false);
  const [sound, setSound] = useState(true);
  const [beat, setBeat] = useState(0);
  const audio = useRef<AudioContext | null>(null);
  const soundRef = useRef(sound);

  useEffect(() => {
    soundRef.current = sound;
  }, [sound]);

  useEffect(() => {
    if (!playing) return;
    const click = () => {
      setBeat((b) => b + 1);
      if (typeof navigator !== "undefined" && "vibrate" in navigator) navigator.vibrate(35);
      const ctx = audio.current;
      if (!ctx || !soundRef.current) return;
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.frequency.value = 880;
      gain.gain.setValueAtTime(0.0001, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.25, ctx.currentTime + 0.005);
      gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.08);
      osc.connect(gain).connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.09);
    };
    click();
    const t = setInterval(click, 60000 / bpm);
    return () => clearInterval(t);
  }, [playing, bpm]);

  const toggle = () => {
    if (!playing && !audio.current) {
      const Ctx = window.AudioContext ?? (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      if (Ctx) audio.current = new Ctx();
    }
    audio.current?.resume();
    setPlaying((p) => !p);
  };

  const pace = bpm < 85 ? "Slow & deliberate" : bpm < 110 ? "Everyday walking" : "Brisk";

  return (
    <div className="grid items-center gap-10 md:grid-cols-[1fr_1.1fr] md:gap-14">
      <div className="relative mx-auto flex aspect-square w-full max-w-[340px] items-center justify-center">
        <div className="absolute inset-[12%] rounded-full bg-gradient-to-br from-indigo/10 to-violet/10" />
        {playing && (
          <span
            key={beat}
            className="beat-ring absolute h-[38%] w-[38%] rounded-full border-2 border-indigo"
            aria-hidden="true"
          />
        )}
        <button
          type="button"
          onClick={toggle}
          aria-pressed={playing}
          className="relative flex h-[42%] w-[42%] flex-col items-center justify-center rounded-full bg-ink text-white shadow-[0_30px_60px_-24px_rgba(79,85,232,0.8)] transition hover:scale-[1.03]"
        >
          <span key={playing ? beat : -1} className={playing ? "pop" : ""}>
            <span className="block text-[2rem] font-semibold tabular-nums leading-none">{bpm}</span>
          </span>
          <span className="mt-1 text-[0.7rem] font-medium uppercase tracking-[0.14em] text-white/60">
            {playing ? "Tap to stop" : "Tap to start"}
          </span>
        </button>
      </div>

      <div>
        <label htmlFor="bpm" className="flex items-baseline justify-between">
          <span className="text-[0.95rem] font-semibold">Tempo</span>
          <span className="text-[0.9rem] text-mute">
            {bpm} steps per minute · {pace}
          </span>
        </label>
        <input
          id="bpm"
          type="range"
          min={MIN}
          max={MAX}
          step={2}
          value={bpm}
          onChange={(e) => setBpm(Number(e.target.value))}
          className="mt-4 w-full accent-[var(--indigo)]"
        />
        <div className="mt-1 flex justify-between text-[0.75rem] text-mute-2">
          <span>{MIN}</span>
          <span>{MAX}</span>
        </div>

        <label className="mt-7 flex cursor-pointer items-center gap-3 text-[0.95rem]">
          <input
            type="checkbox"
            checked={sound}
            onChange={(e) => setSound(e.target.checked)}
            className="h-5 w-5 accent-[var(--indigo)]"
          />
          Play a click on each beat
        </label>

        <p className="mt-7 rounded-2xl bg-paper-2 px-5 py-4 text-[0.92rem] leading-relaxed text-mute">
          On your wrist, GaitGuard delivers this rhythm as haptic taps instead of sound, and only when it senses a freeze.
          On supported Android phones you&apos;ll feel a buzz here too.
        </p>
      </div>
    </div>
  );
}
