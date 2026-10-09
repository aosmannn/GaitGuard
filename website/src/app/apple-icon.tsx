import { ImageResponse } from "next/og";

export const size = { width: 180, height: 180 };
export const contentType = "image/png";

export default function AppleIcon() {
  return new ImageResponse(
    (
      <div style={{ width: "100%", height: "100%", display: "flex", background: "linear-gradient(135deg, #ff8a5c, #ff6a3a)" }}>
        <svg width="180" height="180" viewBox="0 0 64 64">
          <path d="M44.3 21.7 A16 16 0 1 0 47.5 36.1 L35 36.1" fill="none" stroke="#12100e" strokeWidth="5.5" strokeLinecap="round" strokeLinejoin="round" />
          <circle cx="49.5" cy="19.5" r="3.6" fill="#f4eee6" />
        </svg>
      </div>
    ),
    { ...size },
  );
}
