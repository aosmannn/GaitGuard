export function ProductStage() {
  return (
    <div className="relative mx-auto w-full max-w-[940px]" aria-hidden="true">
      <div className="overflow-hidden rounded-[22px] border border-[rgba(35,33,29,0.09)] bg-paper shadow-[0_40px_80px_-44px_rgba(20,90,70,0.34)]">
        <div className="flex items-center gap-3 border-b border-line/70 px-4 py-3">
          <div className="flex gap-1.5">
            <span className="h-2.5 w-2.5 rounded-full bg-[#ff5f57]" />
            <span className="h-2.5 w-2.5 rounded-full bg-[#febc2e]" />
            <span className="h-2.5 w-2.5 rounded-full bg-[#28c840]" />
          </div>
          <p className="text-[13px] font-semibold text-ink">Live walk · Today</p>
          <span className="ml-auto rounded-full bg-accent-tint px-2.5 py-1 text-[11px] font-semibold text-accent-ink">
            Watch connected
          </span>
        </div>

        <div className="grid gap-0 md:grid-cols-[1fr_1.15fr]">
          <div className="flex items-center justify-center bg-gradient-to-b from-[#f4fbf8] to-[#eef7f3] px-6 py-10 md:py-14">
            <WatchFace />
          </div>
          <div className="border-t border-line/70 bg-paper px-5 py-6 md:border-l md:border-t-0 md:px-7 md:py-8">
            <PhonePanel />
          </div>
        </div>
      </div>
    </div>
  );
}

function WatchFace() {
  return (
    <div className="anim-float relative w-[168px] sm:w-[188px]">
      <div className="rounded-[40px] border border-[rgba(35,33,29,0.12)] bg-[#1a1c1e] p-2.5 shadow-[0_24px_48px_-20px_rgba(20,40,35,0.45)]">
        <div className="relative aspect-square overflow-hidden rounded-[32px] bg-[#0c0e10] p-3.5">
          <svg viewBox="0 0 120 120" className="h-full w-full">
            <circle
              cx="60"
              cy="60"
              r="44"
              fill="none"
              stroke="rgba(255,255,255,0.08)"
              strokeWidth="8"
            />
            <circle
              cx="60"
              cy="60"
              r="44"
              fill="none"
              stroke="#2edeb8"
              strokeWidth="8"
              strokeLinecap="round"
              className="ring-spin"
              transform="rotate(-90 60 60)"
            />
            <text
              x="60"
              y="56"
              textAnchor="middle"
              fill="#f7f4ee"
              fontSize="22"
              fontWeight="600"
              fontFamily="var(--font-jakarta), sans-serif"
            >
              92
            </text>
            <text
              x="60"
              y="74"
              textAnchor="middle"
              fill="#8b8375"
              fontSize="9"
              fontFamily="var(--font-jakarta), sans-serif"
            >
              gait score
            </text>
          </svg>
          <div className="absolute bottom-2.5 left-2.5 right-2.5 flex items-center justify-between rounded-xl bg-white/5 px-2.5 py-1.5 text-[10px] text-[#cfc7ba]">
            <span className="inline-flex items-center gap-1.5">
              <span className="h-1.5 w-1.5 rounded-full bg-accent" />
              Cueing
            </span>
            <span>118 spm</span>
          </div>
        </div>
      </div>
      <div className="absolute -left-1 top-[32%] h-9 w-1 rounded-l bg-[#2a2d30]" />
      <div className="absolute -right-1 top-[24%] h-12 w-1 rounded-r bg-[#2a2d30]" />
    </div>
  );
}

function PhonePanel() {
  return (
    <div>
      <p className="text-[12px] font-semibold tracking-wide text-accent-deep">
        GaitGuardAI
      </p>
      <h3 className="mt-1 text-xl font-semibold tracking-tight text-ink">
        Companion dashboard
      </h3>
      <div className="mt-5 grid grid-cols-3 gap-2.5">
        {[
          { label: "Steps", value: "1,284" },
          { label: "Cadence", value: "112" },
          { label: "Events", value: "3" },
        ].map((s) => (
          <div
            key={s.label}
            className="rounded-2xl border border-line bg-card px-3 py-3"
          >
            <p className="text-[11px] text-mute-3">{s.label}</p>
            <p className="mt-0.5 text-lg font-semibold tracking-tight text-ink">
              {s.value}
            </p>
          </div>
        ))}
      </div>
      <div className="mt-4 rounded-2xl border border-line bg-[#f7fbf9] p-4">
        <div className="mb-3 flex items-center justify-between text-[12px]">
          <span className="font-medium text-mute">Event timeline</span>
          <span className="font-semibold text-accent-deep">Today</span>
        </div>
        <div className="flex h-14 items-end gap-1.5">
          {[42, 68, 36, 82, 54, 90, 48, 72, 58, 76].map((h, i) => (
            <div
              key={i}
              className="flex-1 rounded-t-md bg-gradient-to-t from-accent/35 to-accent"
              style={{ height: `${h}%`, opacity: 0.55 + (i % 3) * 0.12 }}
            />
          ))}
        </div>
      </div>
      <div className="mt-4 flex items-center justify-between rounded-2xl border border-line bg-card px-3.5 py-3 text-[12px] text-mute">
        <span>Sensitivity · Medium</span>
        <span className="font-semibold text-ink">Remote ready</span>
      </div>
    </div>
  );
}
