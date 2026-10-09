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
    default: "GaitGuard: a steady beat for every step",
    template: "%s · GaitGuard",
  },
  description:
    "GaitGuard is an iPhone and Apple Watch app for people with Parkinson's who experience freezing of gait. When steps start to freeze, your Watch taps a gentle rhythm on your wrist. A cueing aid, not a medical device.",
  applicationName: "GaitGuard",
  openGraph: {
    type: "website",
    locale: "en_US",
    url: siteUrl,
    siteName: "GaitGuard",
    title: "GaitGuard: a steady beat for every step",
    description:
      "When your steps start to freeze, your Apple Watch taps a gentle rhythm on your wrist. For people with Parkinson's. A cueing aid, not a medical device.",
  },
  twitter: {
    card: "summary_large_image",
    title: "GaitGuard",
    description:
      "A steady beat for every step. iPhone + Apple Watch for people with Parkinson's. A cueing aid, not a medical device.",
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
