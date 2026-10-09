"use client";

import { motion, useScroll, useTransform } from "motion/react";
import Image from "next/image";
import { useRef } from "react";

/** The app design (exported from Paper) in a quiet device bezel. */
export function PhoneDesign({ src, alt, priority = false, className = "" }: { src: string; alt: string; priority?: boolean; className?: string }) {
  return (
    <div className={`rounded-[2.9rem] border border-bone/15 bg-hearth-raised p-[6px] shadow-[0_40px_80px_-30px_rgba(0,0,0,0.8),0_0_0_1px_rgba(0,0,0,0.4)] ${className}`}>
      <Image src={src} alt={alt} width={804} height={1748} priority={priority} className="h-auto w-full rounded-[2.5rem]" sizes="(min-width: 1024px) 320px, 70vw" />
    </div>
  );
}

/** Two screens that drift past each other as you scroll. */
export function ParallaxPhones() {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "end start"] });
  const yA = useTransform(scrollYProgress, [0, 1], [60, -60]);
  const yB = useTransform(scrollYProgress, [0, 1], [-30, 90]);
  const rA = useTransform(scrollYProgress, [0, 1], [-3, 1]);
  const rB = useTransform(scrollYProgress, [0, 1], [3, -1]);
  return (
    <div ref={ref} className="relative mx-auto flex max-w-[760px] items-start justify-center gap-5 sm:gap-10">
      <motion.div style={{ y: yA, rotate: rA }} className="relative w-[46%] max-w-[300px]">
        <PhoneDesign src="/design/app-home-ready.png" alt="GaitGuard app home screen before a walk: a dial of ticks with a Start button and 'Ready to walk?'" />
      </motion.div>
      <motion.div style={{ y: yB, rotate: rB }} className="relative mt-16 w-[46%] max-w-[300px] sm:mt-24">
        <PhoneDesign src="/design/app-home-walking.png" alt="GaitGuard app home screen during a walk: gait score 82 on the dial, steps, cadence, and cues today" />
      </motion.div>
    </div>
  );
}
