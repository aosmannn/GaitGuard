import type { MetadataRoute } from "next";

const base = process.env.NEXT_PUBLIC_SITE_URL ?? "https://gaitguard-app.vercel.app";

export default function sitemap(): MetadataRoute.Sitemap {
  return ["", "/how-it-works", "/app", "/research", "/safety", "/faq", "/pilot", "/about"].map((p) => ({
    url: `${base}${p}`,
    changeFrequency: "monthly",
    priority: p === "" ? 1 : 0.7,
  }));
}
