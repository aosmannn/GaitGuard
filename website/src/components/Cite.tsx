import { refNumber } from "@/lib/research";

/** Superscript citation that jumps to the reference list on /research. */
export function Cite({ ids }: { ids: string[] }) {
  return (
    <sup className="ml-0.5 text-[0.7em] font-semibold text-indigo">
      [
      {ids.map((id, i) => (
        <span key={id}>
          {i > 0 && ","}
          <a href={`/research#ref-${id}`} className="hover:underline" aria-label={`Reference ${refNumber(id)}`}>
            {refNumber(id)}
          </a>
        </span>
      ))}
      ]
    </sup>
  );
}
