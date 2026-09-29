import type { Metadata, Viewport } from "next";
import { Geist, Instrument_Serif } from "next/font/google";
import "./globals.css";

const geist = Geist({
  variable: "--font-geist",
  subsets: ["latin"],
  display: "swap",
});

const serif = Instrument_Serif({
  variable: "--font-serif",
  subsets: ["latin"],
  weight: "400",
  style: ["italic", "normal"],
  display: "swap",
});

const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ?? "https://gaitguardai.vercel.app";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: "GaitGuard: rhythmic cueing for freezing of gait",
    template: "%s · GaitGuard",
  },
  description:
    "GaitGuard detects freezing-of-gait moments on Apple Watch and answers with a rhythmic haptic cue, while your iPhone mirrors every moment live. Not a medical device.",
  applicationName: "GaitGuard",
  openGraph: {
    type: "website",
    locale: "en_US",
    url: siteUrl,
    siteName: "GaitGuard",
    title: "GaitGuard: keep the beat when your steps stall",
    description:
      "Apple Watch freeze detection with rhythmic haptic cueing, mirrored live on iPhone. Not a medical device.",
  },
  twitter: {
    card: "summary_large_image",
    title: "GaitGuard",
    description:
      "Keep the beat when your steps stall. Apple Watch + iPhone. Not a medical device.",
  },
  robots: { index: true, follow: true },
};

export const viewport: Viewport = {
  themeColor: "#f5f6fa",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" className={`${geist.variable} ${serif.variable} h-full`}>
      <body className="min-h-full antialiased">{children}</body>
    </html>
  );
}
