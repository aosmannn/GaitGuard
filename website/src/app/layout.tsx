import type { Metadata } from "next";
import { Plus_Jakarta_Sans } from "next/font/google";
import "./globals.css";

const jakarta = Plus_Jakarta_Sans({
  variable: "--font-jakarta",
  subsets: ["latin"],
  display: "swap",
  weight: ["400", "500", "600", "700"],
});

const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ?? "https://gaitguardai.vercel.app";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: "GaitGuardAI — Rhythmic cueing for freezing of gait",
    template: "%s · GaitGuardAI",
  },
  description:
    "GaitGuardAI is an iOS + Apple Watch cueing aid that detects freezing-of-gait moments and delivers rhythmic haptic pulses. Companion iPhone for analytics and remote control. Not a medical device.",
  applicationName: "GaitGuardAI",
  openGraph: {
    type: "website",
    locale: "en_US",
    url: siteUrl,
    siteName: "GaitGuardAI",
    title: "GaitGuardAI — Rhythmic cueing for freezing of gait",
    description:
      "Watch-based freeze detection with rhythmic haptic cueing. iPhone companion for live analytics. Not a medical device — use with supervision.",
  },
  twitter: {
    card: "summary_large_image",
    title: "GaitGuardAI",
    description:
      "iOS + Apple Watch cueing aid for freezing of gait. Not a medical device.",
  },
  robots: { index: true, follow: true },
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" className={`${jakarta.variable} h-full`}>
      <body className="min-h-full antialiased">{children}</body>
    </html>
  );
}
