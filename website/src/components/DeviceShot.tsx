import Image from "next/image";

/** A real screenshot from the app, in a plain device bezel. */
export function PhoneShot({ src, alt, priority = false, className = "" }: { src: string; alt: string; priority?: boolean; className?: string }) {
  return (
    <div className={`rounded-[2.6rem] bg-[#1d1d1f] p-[7px] shadow-[0_30px_60px_-30px_rgba(0,0,0,0.45)] ${className}`}>
      <Image src={src} alt={alt} width={1206} height={2622} priority={priority} className="h-auto w-full rounded-[2.2rem]" sizes="(min-width: 1024px) 300px, 70vw" />
    </div>
  );
}

export function WatchShot({ src, alt, width, height, className = "" }: { src: string; alt: string; width: number; height: number; className?: string }) {
  return (
    <div className={`rounded-[2.4rem] bg-[#1d1d1f] p-[7px] shadow-[0_24px_50px_-26px_rgba(0,0,0,0.5)] ${className}`}>
      <Image src={src} alt={alt} width={width} height={height} className="h-auto w-full rounded-[2rem]" sizes="200px" />
    </div>
  );
}
