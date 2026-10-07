/** GaitGuard mark: a "G" drawn as a stride ring, with an amber pulse leaving the opening (the cue). */
export function LogoMark({ size = 32, className = "" }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64" className={className} aria-hidden="true">
      <defs>
        <linearGradient id="gg-bg" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#4f55e8" />
          <stop offset="1" stopColor="#9b6bff" />
        </linearGradient>
      </defs>
      <rect width="64" height="64" rx="16" fill="url(#gg-bg)" />
      <path
        d="M44.3 21.7 A16 16 0 1 0 47.5 36.1 L35 36.1"
        fill="none"
        stroke="#fff"
        strokeWidth="5.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <circle cx="49.5" cy="19.5" r="3.6" fill="#ffb547" />
    </svg>
  );
}

export function Logo({ size = 30 }: { size?: number }) {
  return (
    <span className="flex items-center gap-2.5">
      <LogoMark size={size} />
      <span className="text-[1.05rem] font-semibold tracking-tight">GaitGuard</span>
    </span>
  );
}
