export function WatchMock() {
  return (
    <div
      className="animate-float relative mx-auto w-[188px] select-none"
      aria-hidden="true"
    >
      <div className="absolute -inset-8 rounded-full bg-[radial-gradient(circle,rgba(46,222,184,0.22),transparent_65%)] animate-soft-pulse" />
      <div className="relative rounded-[42px] border border-white/10 bg-gradient-to-b from-[#1a2438] to-[#0b1220] p-3 shadow-[0_30px_80px_rgba(0,0,0,0.55)]">
        <div className="mx-auto mb-2 h-3 w-10 rounded-full bg-white/10" />
        <div className="relative aspect-square overflow-hidden rounded-[32px] bg-[#060b14] p-4">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_40%,rgba(46,222,184,0.12),transparent_60%)]" />
          <svg viewBox="0 0 120 120" className="relative h-full w-full">
            <circle
              cx="60"
              cy="60"
              r="46"
              fill="none"
              stroke="rgba(148,175,210,0.12)"
              strokeWidth="8"
            />
            <circle
              cx="60"
              cy="60"
              r="46"
              fill="none"
              stroke="url(#tealGrad)"
              strokeWidth="8"
              strokeLinecap="round"
              className="ring-track"
              transform="rotate(-90 60 60)"
            />
            <defs>
              <linearGradient id="tealGrad" x1="0" y1="0" x2="1" y2="1">
                <stop offset="0%" stopColor="#2edeb8" />
                <stop offset="100%" stopColor="#1aa88a" />
              </linearGradient>
            </defs>
            <text
              x="60"
              y="56"
              textAnchor="middle"
              fill="#e8eef7"
              fontSize="22"
              fontFamily="var(--font-sora), sans-serif"
              fontWeight="600"
            >
              92
            </text>
            <text
              x="60"
              y="74"
              textAnchor="middle"
              fill="#8b9bb4"
              fontSize="9"
              fontFamily="var(--font-manrope), sans-serif"
            >
              gait score
            </text>
          </svg>
          <div className="absolute bottom-3 left-3 right-3 flex items-center justify-between rounded-xl bg-white/5 px-2.5 py-1.5 text-[10px] text-[#b6c3d6]">
            <span className="inline-flex items-center gap-1.5">
              <span className="h-1.5 w-1.5 rounded-full bg-teal animate-haptic" />
              Cueing
            </span>
            <span>118 spm</span>
          </div>
        </div>
        <div className="mx-auto mt-2 h-1.5 w-8 rounded-full bg-white/10" />
      </div>
      <div className="absolute -left-1 top-1/3 h-10 w-1 rounded-l bg-[#2a3548]" />
      <div className="absolute -right-1 top-1/4 h-14 w-1 rounded-r bg-[#2a3548]" />
    </div>
  );
}

export function PhoneMock() {
  return (
    <div
      className="relative mx-auto w-[220px] select-none sm:w-[240px]"
      aria-hidden="true"
    >
      <div className="rounded-[36px] border border-white/10 bg-gradient-to-b from-[#1c2740] to-[#0a1220] p-2.5 shadow-[0_40px_100px_rgba(0,0,0,0.55)]">
        <div className="overflow-hidden rounded-[28px] bg-[#060b14]">
          <div className="flex items-center justify-between px-4 pb-2 pt-3 text-[10px] text-[#8b9bb4]">
            <span>9:41</span>
            <span className="h-1.5 w-16 rounded-full bg-white/15" />
            <span>●●</span>
          </div>
          <div className="space-y-3 px-4 pb-5">
            <div>
              <p className="font-display text-[11px] tracking-wide text-teal">
                GaitGuardAI
              </p>
              <p className="font-display text-lg font-semibold text-text">
                Live session
              </p>
            </div>
            <div className="grid grid-cols-3 gap-2">
              {[
                { label: "Steps", value: "1,284" },
                { label: "Cadence", value: "112" },
                { label: "Events", value: "3" },
              ].map((stat) => (
                <div
                  key={stat.label}
                  className="rounded-xl border border-white/8 bg-white/[0.03] px-2 py-2"
                >
                  <p className="text-[9px] text-muted">{stat.label}</p>
                  <p className="font-display text-sm font-semibold text-text">
                    {stat.value}
                  </p>
                </div>
              ))}
            </div>
            <div className="rounded-2xl border border-teal/20 bg-teal-dim p-3">
              <div className="mb-2 flex items-center justify-between text-[10px]">
                <span className="text-soft">Event timeline</span>
                <span className="text-teal">Today</span>
              </div>
              <div className="flex h-16 items-end gap-1.5">
                {[40, 65, 35, 80, 50, 90, 45, 70, 55, 75].map((h, i) => (
                  <div
                    key={i}
                    className="flex-1 rounded-t bg-gradient-to-t from-teal/30 to-teal"
                    style={{ height: `${h}%`, opacity: 0.45 + (i % 3) * 0.15 }}
                  />
                ))}
              </div>
            </div>
            <div className="flex items-center justify-between rounded-xl border border-white/8 bg-white/[0.03] px-3 py-2 text-[10px] text-soft">
              <span>Watch connected</span>
              <span className="text-teal">● Online</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
