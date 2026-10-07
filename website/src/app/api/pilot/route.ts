import { appendFile, mkdir } from "node:fs/promises";
import path from "node:path";
import { parseSignup } from "@/lib/pilot";

/**
 * Pilot sign-ups.
 *
 * - If PILOT_WEBHOOK_URL is set, the validated signup is POSTed there (Formspree, a Google Apps Script,
 *   Zapier, a Supabase edge function, etc.), which is the way to run this in production.
 * - Otherwise it is appended to data/pilot-signups.jsonl, which works on a local machine only.
 */
export async function POST(request: Request) {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return Response.json({ ok: false, error: "Something went wrong. Please try again." }, { status: 400 });
  }

  // Honeypot: real people never fill this hidden field.
  if (typeof body === "object" && body !== null && (body as Record<string, unknown>).company) {
    return Response.json({ ok: true });
  }

  const parsed = parseSignup(body);
  if (!parsed.ok) return Response.json({ ok: false, error: parsed.error }, { status: 400 });

  const record = { ...parsed.value, receivedAt: new Date().toISOString() };

  try {
    const hook = process.env.PILOT_WEBHOOK_URL;
    if (hook) {
      const res = await fetch(hook, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(record),
      });
      if (!res.ok) throw new Error(`webhook ${res.status}`);
    } else {
      const dir = path.join(process.cwd(), "data");
      await mkdir(dir, { recursive: true });
      await appendFile(path.join(dir, "pilot-signups.jsonl"), JSON.stringify(record) + "\n", "utf8");
    }
    return Response.json({ ok: true });
  } catch (err) {
    console.error("[pilot] could not store signup:", err);
    return Response.json(
      { ok: false, error: "Sign-ups aren't switched on right now. Please try again soon." },
      { status: 503 },
    );
  }
}
