import { readFile } from "node:fs/promises";
import path from "node:path";
import { ImageResponse } from "next/og";

export const size = { width: 1200, height: 630 };
export const contentType = "image/png";
export const alt = "GaitGuard: a steady beat for every step";

export default async function OG() {
  const buf = await readFile(path.join(process.cwd(), "public/brand/gaitguard-logo-1024.png"));
  const logo = `data:image/png;base64,${buf.toString("base64")}`;
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
          background: "radial-gradient(60% 80% at 85% 0%, #3a1f14 0%, #12100e 62%)",
          color: "#f4eee6",
          fontFamily: "sans-serif",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 20 }}>
          <img src={logo} width={84} height={84} alt="" style={{ borderRadius: 19 }} />
          <span style={{ fontSize: 40, fontWeight: 700 }}>GaitGuard</span>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
          <span style={{ fontSize: 80, fontWeight: 600, letterSpacing: -3, lineHeight: 1.02 }}>A steady beat for every step.</span>
          <span style={{ fontSize: 30, color: "#a39a90" }}>For people with Parkinson\u2019s · iPhone + Apple Watch · A cueing aid, not a medical device</span>
        </div>
      </div>
    ),
    { ...size },
  );
}
