"use client";

import Lenis from "lenis";
import { useEffect } from "react";

/** Buttery scrolling for the whole site. Skipped for people who prefer reduced motion. */
export function SmoothScroll() {
  useEffect(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const lenis = new Lenis({ autoRaf: true, lerp: 0.1, anchors: true });
    return () => lenis.destroy();
  }, []);
  return null;
}
