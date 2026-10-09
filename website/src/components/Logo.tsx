/** GaitGuard mark: a "G" drawn as a stride ring, with a bone cue dot leaving the opening. Ember tile, per the app palette. */
export function LogoMark({ size = 32, className = "" }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64" className={className} aria-hidden="true">
      <defs>
        <linearGradient id="gg-bg" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#ff8a5c" />
          <stop offset="1" stopColor="#ff6a3a" />
        </linearGradient>
      </defs>
      <rect width="64" height="64" rx="18" fill="url(#gg-bg)" />
      <path
        d="M44.3 21.7 A16 16 0 1 0 47.5 36.1 L35 36.1"
        fill="none"
        stroke="#12100e"
        strokeWidth="5.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <circle cx="49.5" cy="19.5" r="3.6" fill="#f4eee6" />
    </svg>
  );
}

export function Logo({ size = 30 }: { size?: number }) {
  return (
    <span className="flex items-center gap-2.5">
      <LogoMark size={size} />
      <span className="font-[family-name:var(--font-fraunces)] text-[1.2rem] font-medium tracking-tight">GaitGuard</span>
    </span>
  );
}
