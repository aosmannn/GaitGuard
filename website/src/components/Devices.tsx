import { cueColor, scoreColor, scoreLabel, type DemoState } from "@/lib/demo";

const C = 2 * Math.PI * 42;

export function Ring({
  score,
  monitoring,
  size,
  caption = "GAIT SCORE",
}: {
  score: number;
  monitoring: boolean;
  size: "phone" | "watch";
  caption?: string;
}) {
  const color = scoreColor(score, monitoring);
  const big = size === "phone";
  return (
    <svg viewBox="0 0 100 100" className="h-full w-full" aria-hidden="true">
      <circle cx="50" cy="50" r="42" fill="none" stroke="rgba(255,255,255,0.08)" strokeWidth={big ? 7 : 8} />
      <circle
        cx="50"
        cy="50"
        r="42"
        fill="none"
        stroke={color}
        strokeWidth={big ? 7 : 8}
        strokeLinecap="round"
        strokeDasharray={C}
        strokeDashoffset={C * (1 - (monitoring ? score : 0) / 100)}
        transform="rotate(-90 50 50)"
        style={{
          transition: "stroke-dashoffset 0.9s cubic-bezier(.22,1,.36,1), stroke 0.6s ease",
          filter: `drop-shadow(0 0 5px ${color}88)`,
        }}
      />
      <text x="50" y={big ? 36 : 38} textAnchor="middle" fill="#9ea3bd" fontSize={big ? 5.2 : 6.5} fontWeight="600" letterSpacing="1">
        {caption}
      </text>
      <text
        x="50"
        y={monitoring ? (big ? 60 : 62) : big ? 57 : 58}
        textAnchor="middle"
        fill={monitoring ? "#f4f5fb" : "#7c8cff"}
        fontSize={monitoring ? (big ? 26 : 28) : big ? 15 : 17}
        fontWeight="700"
      >
        {monitoring ? score : "Ready"}
      </text>
      <text x="50" y={big ? 71 : 74} textAnchor="middle" fill={color} fontSize={big ? 6 : 7.5} fontWeight="600">
        {monitoring ? scoreLabel(score, true) : big ? "Cueing paused" : "Tap start"}
      </text>
    </svg>
  );
}

export function Phone({
  s,
  onToggle,
  className = "",
}: {
  s: DemoState;
  onToggle?: () => void;
  className?: string;
}) {
  return (
    <div className={`relative w-[272px] shrink-0 ${className}`}>
      <div className="rounded-[48px] bg-[#1b1d2b] p-[9px] shadow-[0_60px_100px_-40px_rgba(30,30,90,0.55),inset_0_0_0_1px_rgba(255,255,255,0.08)]">
        <div className="relative h-[560px] overflow-hidden rounded-[40px] bg-[#0a0b14] text-left">
          <div
            className="pointer-events-none absolute inset-x-0 top-0 h-64 transition-opacity duration-700"
            style={{
              background: "radial-gradient(80% 100% at 50% 0%, rgba(124,140,255,0.28), transparent 70%)",
              opacity: s.monitoring ? 1 : 0.45,
            }}
          />
          <div className="relative flex items-center justify-between px-7 pt-3.5 text-[10px] font-semibold text-white">
            <span>9:41</span>
            <span className="h-[22px] w-[74px] rounded-full bg-black" />
            <span className="flex gap-1">
              <span className="h-2 w-3 rounded-[2px] bg-white/80" />
            </span>
          </div>

          <div className="relative px-4 pt-4">
            <p className="text-[21px] font-bold tracking-tight text-white">GaitGuard</p>

            <div className="mt-3 rounded-[22px] border border-white/10 bg-[#131522] p-3.5">
              <div className="flex items-center justify-between">
                <span className="inline-flex items-center gap-1.5 rounded-full bg-[#4ade9a]/15 px-2 py-[3px] text-[9px] font-semibold text-[#4ade9a]">
                  <span className="h-1.5 w-1.5 rounded-full bg-[#4ade9a]" />
                  Watch connected
                </span>
                {s.monitoring && <span className="text-[9px] font-medium text-[#9ea3bd]">● Live</span>}
              </div>
              <div className="mx-auto mt-2 h-[132px] w-[132px]">
                <Ring score={s.score} monitoring={s.monitoring} size="phone" />
              </div>
              <button
                type="button"
                onClick={onToggle}
                tabIndex={onToggle ? 0 : -1}
                aria-label={onToggle ? (s.monitoring ? "Stop monitoring from iPhone" : "Start monitoring from iPhone") : undefined}
                className="mt-2 flex w-full items-center justify-center gap-1.5 rounded-[13px] py-2.5 text-[11px] font-bold text-white transition-colors"
                style={{
                  background: s.monitoring ? "rgba(255,107,122,0.88)" : "linear-gradient(135deg,#7c8cff,#b58cff)",
                  cursor: onToggle ? "pointer" : "default",
                }}
              >
                {s.monitoring ? "■ Stop Monitoring" : "▶ Start Monitoring"}
              </button>
            </div>

            <div className="mt-2.5 rounded-[18px] border border-white/10 bg-[#131522] px-3.5 py-3">
              <div className="flex items-center justify-between">
                <span className="text-[11px] font-bold text-white">Today&apos;s Support</span>
                <span className="text-[10px] font-semibold text-[#ffb547]">{s.cues.length} {s.cues.length === 1 ? "cue" : "cues"}</span>
              </div>
              <div className="mt-2 grid grid-cols-2 text-center">
                <div>
                  <p className="text-[14px] font-bold tabular-nums text-white">{s.steps.toLocaleString()}</p>
                  <p className="text-[8.5px] text-[#9ea3bd]">Steps</p>
                </div>
                <div>
                  <p className="text-[14px] font-bold tabular-nums text-white">{s.cadence || "--"}</p>
                  <p className="text-[8.5px] text-[#9ea3bd]">Cadence (spm)</p>
                </div>
              </div>
            </div>

            <ul className="mt-2.5 space-y-1.5">
              {s.cues.length === 0 && (
                <li className="rounded-[14px] border border-dashed border-white/10 px-3 py-2.5 text-[10px] text-[#6b7088]">
                  Cues appear here the moment they happen
                </li>
              )}
              {s.cues.slice(0, 3).map((c) => (
                <li key={c.id} className="drop-in flex items-center gap-2.5 rounded-[14px] bg-[#131522] px-3 py-2">
                  <span
                    className="flex h-6 w-6 items-center justify-center rounded-full text-[10px]"
                    style={{ background: `${cueColor(c.type)}26`, color: cueColor(c.type) }}
                  >
                    {c.type === "Turn" ? "↻" : "→"}
                  </span>
                  <span className="text-[11px] font-semibold text-white">{c.type} cue</span>
                  <span className="ml-auto text-[9.5px] text-[#9ea3bd]">{c.time}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}

export function Watch({
  s,
  onToggle,
  className = "",
}: {
  s: DemoState;
  onToggle?: () => void;
  className?: string;
}) {
  return (
    <div className={`relative w-[178px] shrink-0 ${className}`}>
      {/* crown + button */}
      <span className="absolute -right-[5px] top-[30%] h-10 w-[7px] rounded-r-md bg-[#2b2e40]" />
      <span className="absolute -right-[4px] top-[52%] h-12 w-[5px] rounded-r bg-[#2b2e40]" />
      <div className="rounded-[46px] bg-[#1b1d2b] p-[9px] shadow-[0_50px_90px_-40px_rgba(90,40,160,0.55),inset_0_0_0_1px_rgba(255,255,255,0.08)]">
        <div
          className="relative aspect-[41/50] overflow-hidden rounded-[38px] p-3 transition-colors duration-700"
          style={{
            background: s.monitoring
              ? "linear-gradient(180deg, rgba(124,140,255,0.38), #05050a 70%)"
              : "linear-gradient(180deg, #151727, #05050a 70%)",
          }}
        >
          {s.flash && (
            <div
              key={s.flash.id}
              className="drop-in absolute left-1/2 top-2.5 z-10 -translate-x-1/2 whitespace-nowrap rounded-full bg-[#ffb547] px-2.5 py-1 text-[9px] font-bold text-black"
            >
              Cue · {s.flash.type}
            </div>
          )}
          <div className="flex items-center justify-between pl-1 pt-1 text-[9px] font-semibold text-[#9ea3bd]">
            <span className="flex items-center gap-1">
              <span className="h-1.5 w-1.5 rounded-full bg-[#4ade9a]" /> Synced
            </span>
            <span className="text-white">9:41</span>
          </div>
          <div className="mx-auto mt-1.5 h-[104px] w-[104px]">
            <Ring score={s.score} monitoring={s.monitoring} size="watch" caption="SCORE" />
          </div>
          <button
            type="button"
            onClick={onToggle}
            tabIndex={onToggle ? 0 : -1}
            aria-label={onToggle ? (s.monitoring ? "Stop monitoring from Watch" : "Start monitoring from Watch") : undefined}
            className="mt-2 w-full rounded-full py-2 text-[11px] font-extrabold tracking-wider text-white transition-colors"
            style={{ background: s.monitoring ? "rgba(255,107,122,0.9)" : "#7c8cff", cursor: onToggle ? "pointer" : "default" }}
          >
            {s.monitoring ? "STOP" : "START"}
          </button>
          <div className="mt-2 flex justify-center gap-1">
            <span className="h-1.5 w-1.5 rounded-full bg-white" />
            <span className="h-1 w-1 rounded-full bg-white/30" />
            <span className="h-1 w-1 rounded-full bg-white/30" />
          </div>
        </div>
      </div>
    </div>
  );
}
