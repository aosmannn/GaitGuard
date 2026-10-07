import { ImageResponse } from "next/og";

export const size = { width: 1200, height: 630 };
export const contentType = "image/png";
export const alt = "GaitGuard: keep the beat when your steps stall";

export default function OG() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          padding: 80,
          background: "radial-gradient(60% 80% at 90% 10%, #e4dcff 0%, #f5f6fa 60%)",
          color: "#0e1024",
          fontFamily: "sans-serif",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 20 }}>
          <svg width="72" height="72" viewBox="0 0 64 64">
            <defs>
              <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
                <stop offset="0" stopColor="#4f55e8" />
                <stop offset="1" stopColor="#9b6bff" />
              </linearGradient>
            </defs>
            <rect width="64" height="64" rx="16" fill="url(#g)" />
            <path d="M44.3 21.7 A16 16 0 1 0 47.5 36.1 L35 36.1" fill="none" stroke="#fff" strokeWidth="5.5" strokeLinecap="round" strokeLinejoin="round" />
            <circle cx="49.5" cy="19.5" r="3.6" fill="#ffb547" />
          </svg>
          <span style={{ fontSize: 40, fontWeight: 700 }}>GaitGuard</span>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
          <span style={{ fontSize: 76, fontWeight: 700, letterSpacing: -3, lineHeight: 1.02 }}>Keep the beat when your steps stall.</span>
          <span style={{ fontSize: 30, color: "#5b6078" }}>Rhythmic haptic cueing for freezing of gait · Apple Watch + iPhone</span>
        </div>
      </div>
    ),
    { ...size },
  );
}
