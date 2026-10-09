import Image from "next/image";

/** The GaitGuard app icon (from /branding): a tick dial around an ember G, as on the phone and Watch. */
export function LogoMark({ size = 32, className = "" }: { size?: number; className?: string }) {
  return (
    <Image
      src="/brand/gaitguard-logo-1024.png"
      alt=""
      width={size}
      height={size}
      priority
      className={`shrink-0 rounded-[22.5%] ring-1 ring-bone/20 ${className}`}
      style={{ width: size, height: size }}
    />
  );
}

export function Logo({ size = 36 }: { size?: number }) {
  return (
    <span className="flex items-center gap-3">
      <LogoMark size={size} />
      <span className="font-[family-name:var(--font-fraunces)] text-[1.25rem] font-medium tracking-tight">GaitGuard</span>
    </span>
  );
}
