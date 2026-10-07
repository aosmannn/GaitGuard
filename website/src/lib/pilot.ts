export const ROLES = [
  "I live with Parkinson's",
  "Care partner or family member",
  "Clinician or physical therapist",
  "Researcher",
  "Something else",
] as const;

export const DEVICES = ["iPhone and Apple Watch", "iPhone only", "Neither yet"] as const;

export type PilotSignup = {
  email: string;
  role: (typeof ROLES)[number];
  devices: (typeof DEVICES)[number];
  note: string;
};

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

/** Validates untrusted input and returns a clean signup, or an error message safe to show the user. */
export function parseSignup(input: unknown): { ok: true; value: PilotSignup } | { ok: false; error: string } {
  if (typeof input !== "object" || input === null) return { ok: false, error: "Something went wrong. Please try again." };
  const o = input as Record<string, unknown>;
  const email = typeof o.email === "string" ? o.email.trim().toLowerCase() : "";
  if (!EMAIL.test(email) || email.length > 200) return { ok: false, error: "Please enter a valid email address." };
  const role = ROLES.find((r) => r === o.role);
  if (!role) return { ok: false, error: "Please choose the option that describes you best." };
  const devices = DEVICES.find((d) => d === o.devices);
  if (!devices) return { ok: false, error: "Please tell us which devices you have." };
  if (o.consent !== true) return { ok: false, error: "Please confirm the consent box so we can contact you." };
  const note = typeof o.note === "string" ? o.note.trim().slice(0, 1000) : "";
  return { ok: true, value: { email, role, devices, note } };
}
