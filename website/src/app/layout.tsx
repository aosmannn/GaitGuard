import type { Metadata, Viewport } from "next";
import { DM_Sans, Fraunces } from "next/font/google";
import "./globals.css";
import { SiteFooter, SiteHeader } from "@/components/SiteChrome";
import { SmoothScroll } from "@/components/SmoothScroll";

const dmSans = DM_Sans({
  variable: "--font-dmsans",
  subsets: ["latin"],
  display: "swap",
});

const fraunces = Fraunces({
  variable: "--font-fraunces",
  subsets: ["latin"],
  axes: ["opsz"],
  style: ["normal", "italic"],
  display: "swap",
});

const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ?? "https://gaitguard-app.vercel.app";

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
  themeColor: "#12100e",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" className={`${dmSans.variable} ${fraunces.variable} h-full`}>
      <body className="min-h-full bg-char text-bone antialiased">
        <a
          href="#main"
          className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-[60] focus:rounded-full focus:bg-ink focus:px-4 focus:py-2 focus:text-sm focus:font-semibold focus:text-white"
        >
          Skip to content
        </a>
        <SmoothScroll />
        <SiteHeader />
        <main id="main">{children}</main>
        <SiteFooter />
      </body>
    </html>
  );
}
