"use client";

import { useId, useState } from "react";
import { DEVICES, ROLES } from "@/lib/pilot";

type State = { status: "idle" | "sending" | "done" | "error"; message?: string };

const field =
  "mt-2 w-full rounded-xl border border-[#c9c9d0] bg-white px-4 py-3 text-[1rem] text-ink outline-none transition placeholder:text-mute-2 focus:border-indigo focus:ring-4 focus:ring-indigo/15";

export function PilotForm() {
  const id = useId();
  const [state, setState] = useState<State>({ status: "idle" });

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const form = e.currentTarget;
    const data = new FormData(form);
    setState({ status: "sending" });
    try {
      const res = await fetch("/api/pilot", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: data.get("email"),
          role: data.get("role"),
          devices: data.get("devices"),
          note: data.get("note"),
          consent: data.get("consent") === "on",
          company: data.get("company"),
        }),
      });
      const json = (await res.json().catch(() => null)) as { ok?: boolean; error?: string } | null;
      if (res.ok && json?.ok) {
        form.reset();
        setState({ status: "done" });
      } else {
        setState({ status: "error", message: json?.error ?? "Something went wrong. Please try again." });
      }
    } catch {
      setState({ status: "error", message: "Couldn't reach the server. Check your connection and try again." });
    }
  }

  if (state.status === "done") {
    return (
      <div role="status" className="rounded-2xl border border-good/40 bg-good/10 p-8">
        <p className="text-[0.85rem] font-semibold text-good">Received</p>
        <h3 className="mt-3 text-[1.5rem] font-semibold tracking-tight text-ink">You&apos;re on the list.</h3>
        <p className="mt-2 max-w-[34em] text-[1rem] leading-relaxed text-ink-2">
          Thank you. We&apos;ll email you when there&apos;s a pilot build to try. Nothing else will be sent, and you can ask to be removed at any time.
        </p>
        <button type="button" onClick={() => setState({ status: "idle" })} className="mt-5 text-[0.9rem] font-medium text-indigo underline underline-offset-4">
          Add another person
        </button>
      </div>
    );
  }

  const busy = state.status === "sending";

  return (
    <form onSubmit={onSubmit} noValidate className="grid gap-5" aria-describedby={`${id}-err`}>
      <div>
        <label htmlFor={`${id}-email`} className="text-[0.85rem] font-semibold text-ink">Email</label>
        <input id={`${id}-email`} name="email" type="email" autoComplete="email" required placeholder="you@example.com" className={field} />
      </div>

      <div className="grid gap-5 sm:grid-cols-2">
        <div>
          <label htmlFor={`${id}-role`} className="text-[0.85rem] font-semibold text-ink">I am…</label>
          <select id={`${id}-role`} name="role" required defaultValue="" className={field}>
            <option value="" disabled>Choose one</option>
            {ROLES.map((r) => <option key={r}>{r}</option>)}
          </select>
        </div>
        <div>
          <label htmlFor={`${id}-dev`} className="text-[0.85rem] font-semibold text-ink">I have…</label>
          <select id={`${id}-dev`} name="devices" required defaultValue="" className={field}>
            <option value="" disabled>Choose one</option>
            {DEVICES.map((d) => <option key={d}>{d}</option>)}
          </select>
        </div>
      </div>

      <div>
        <label htmlFor={`${id}-note`} className="text-[0.85rem] font-semibold text-ink">Anything we should know? <span className="normal-case tracking-normal">(optional)</span></label>
        <textarea id={`${id}-note`} name="note" rows={3} maxLength={1000} placeholder="Where freezing happens for you, what you'd want from the app, questions…" className={field} />
      </div>

      {/* Honeypot, hidden from people */}
      <div className="absolute -left-[9999px] h-0 w-0 overflow-hidden" aria-hidden="true">
        <label>Company<input name="company" tabIndex={-1} autoComplete="off" /></label>
      </div>

      <label className="flex cursor-pointer items-start gap-3 text-[0.9rem] leading-relaxed text-ink-2">
        <input type="checkbox" name="consent" required className="mt-1 h-5 w-5 shrink-0 accent-[var(--indigo)]" />
        <span>
          I&apos;m happy to be emailed about the GaitGuard pilot. I understand it&apos;s an early prototype and not a medical device, and that this form isn&apos;t a clinical study.
        </span>
      </label>

      <div id={`${id}-err`} aria-live="polite">
        {state.status === "error" && (
          <p className="rounded-xl border border-danger/40 bg-danger/10 px-4 py-3 text-[0.92rem] text-ink">{state.message}</p>
        )}
      </div>

      <button type="submit" disabled={busy} className={`btn btn-signal w-full sm:w-auto sm:justify-self-start disabled:opacity-60`}>
        {busy ? "Sending…" : "Join the pilot"}
      </button>
    </form>
  );
}
