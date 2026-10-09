"use client";

import { motion, useScroll, useTransform } from "motion/react";
import Image from "next/image";
import { useRef } from "react";

/** A real iPhone screenshot (demo data) in a plain dark bezel. */
export function PhoneShot({ src, alt, priority = false, className = "" }: { src: string; alt: string; priority?: boolean; className?: string }) {
  return (
    <div className={`rounded-[2.9rem] border border-bone/15 bg-hearth-raised p-[6px] shadow-[0_40px_80px_-30px_rgba(0,0,0,0.8),0_0_0_1px_rgba(0,0,0,0.4)] ${className}`}>
      <Image src={src} alt={alt} width={828} height={1800} priority={priority} className="h-auto w-full rounded-[2.5rem]" sizes="(min-width: 1024px) 320px, 70vw" />
    </div>
  );
}

/** A real Apple Watch screenshot (demo data) in a dark bezel. */
export function WatchShot({ src, alt, className = "" }: { src: string; alt: string; className?: string }) {
  return (
    <div className={`rounded-[2.2rem] border border-bone/15 bg-hearth-raised p-[5px] shadow-[0_30px_60px_-30px_rgba(0,0,0,0.8)] ${className}`}>
      <Image src={src} alt={alt} width={422} height={514} className="h-auto w-full rounded-[1.8rem]" sizes="(min-width: 1024px) 240px, 45vw" />
    </div>
  );
}

/** Two real screens that drift past each other as you scroll. */
export function ParallaxPhones() {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "end start"] });
  const yA = useTransform(scrollYProgress, [0, 1], [50, -50]);
  const yB = useTransform(scrollYProgress, [0, 1], [-25, 75]);
  return (
    <div ref={ref} className="relative mx-auto flex max-w-[760px] items-start justify-center gap-5 sm:gap-10">
      <motion.div style={{ y: yA }} className="relative w-[46%] max-w-[300px]">
        <PhoneShot src="/app/home-ready.png" alt="GaitGuard Home before a walk: the tick dial with a Start button, cues today and calibration status" />
      </motion.div>
      <motion.div style={{ y: yB }} className="relative mt-14 w-[46%] max-w-[300px] sm:mt-20">
        <PhoneShot src="/app/home-live.png" alt="GaitGuard Home during a walk: steadiness 86 on the tick dial, with time, steps and cadence" />
      </motion.div>
    </div>
  );
}
