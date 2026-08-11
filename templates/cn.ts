import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

/**
 * Merge Tailwind classes with correct conflict resolution.
 *
 * Always use this when combining a Shell Identity constant with local classes:
 *
 *   <div className={cn(AXO_GLASS_CARD, "p-6")} />
 *
 * Plain string concatenation breaks when the local class conflicts with one
 * inside the constant (e.g. two `rounded-*` values) — twMerge keeps the last.
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
