import Image from "next/image";

/** The GaitGuard mark from /branding: the tick dial and the ember G, on a transparent background. */
export function LogoMark({ size = 46, className = "" }: { size?: number; className?: string }) {
  return (
    <Image
      src="/brand/gaitguard-mark.svg"
      alt=""
      width={size}
      height={size}
      priority
      unoptimized
      className={`shrink-0 ${className}`}
      style={{ width: size, height: size }}
    />
  );
}

export function Logo({ size = 48 }: { size?: number }) {
  return (
    <span className="flex items-center gap-2">
      <LogoMark size={size} className="-my-1" />
      <span className="font-[family-name:var(--font-fraunces)] text-[1.25rem] font-medium tracking-tight">GaitGuard</span>
    </span>
  );
}
