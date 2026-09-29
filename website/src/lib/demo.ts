export type CueType = "Start" | "Turn";
export type Cue = { id: number; type: CueType; time: string };

export type DemoState = {
  monitoring: boolean;
  score: number;
  steps: number;
  cadence: number;
  cues: Cue[];
  /** Cue currently shown as a banner on the Watch. */
  flash: Cue | null;
};

export const initialDemo: DemoState = {
  monitoring: false,
  score: 0,
  steps: 0,
  cadence: 0,
  cues: [],
  flash: null,
};

/** Mirrors GaitScoreCalculator.label in the app. */
export function scoreLabel(score: number, monitoring: boolean) {
  if (!monitoring) return "Ready";
  if (score >= 85) return "Steady";
  if (score >= 65) return "Supported";
  if (score >= 40) return "Assisting";
  return "High support";
}

/** Mirrors GGTheme.scoreColor in the app. */
export function scoreColor(score: number, monitoring: boolean) {
  if (!monitoring) return "#7c8cff";
  if (score >= 85) return "#4ade9a";
  if (score >= 65) return "#7c8cff";
  if (score >= 40) return "#ffb547";
  return "#ff6b7a";
}

export function cueColor(type: CueType) {
  return type === "Turn" ? "#b58cff" : "#ffb547";
}

export function clockTime(d = new Date()) {
  return d.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
}
