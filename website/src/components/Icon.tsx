export const icons = {
  pulse: "M3 12h4l3-8 4 16 3-8h4",
  wave: "M2 12c2-4 4-4 6 0s4 4 6 0 4-4 6 0",
  chart: "M4 20V10m6 10V4m6 16v-7m6 7H2",
  sync: "M4 12a8 8 0 0 1 14-5.3M20 4v4h-4M20 12a8 8 0 0 1-14 5.3M4 20v-4h4",
  target: "M12 3v3m0 12v3m9-9h-3M6 12H3M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6z",
  moon: "M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z",
  sliders: "M4 6h10m4 0h2M4 12h4m4 0h8M4 18h12M14 4v4M8 10v4M16 16v4",
  lock: "M6 11h12v10H6zM8 11V7a4 4 0 0 1 8 0v4",
  book: "M4 5a2 2 0 0 1 2-2h13v16H6a2 2 0 0 0-2 2zM4 21V5M8 7h7",
  watch: "M8 6h8v12H8zM9 6l1-3h4l1 3M9 18l1 3h4l1-3",
  shield: "M12 3l8 3v6c0 4.5-3.4 8.3-8 9-4.6-.7-8-4.5-8-9V6z",
  phone: "M7 2h10v20H7zM11 18h2",
} as const;

export function Icon({ d, className = "h-5 w-5" }: { d: string; className?: string }) {
  return (
    <svg viewBox="0 0 24 24" className={className} fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d={d} />
    </svg>
  );
}
