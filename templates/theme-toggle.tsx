"use client";

/**
 * Axo Theme Toggle — light / dark / system.
 *
 * Renders a placeholder of identical size until mounted, so the header does not
 * shift layout on hydration. Never read `theme` during the first render.
 */

import { useEffect, useState } from "react";
import { useTheme } from "next-themes";
import { Monitor, Moon, Sun } from "lucide-react";
import { AXO_FOCUS_RING } from "@/lib/shell-identity";

const OPTIONS = [
  { value: "light", label: "Light", Icon: Sun },
  { value: "dark", label: "Dark", Icon: Moon },
  { value: "system", label: "System", Icon: Monitor },
] as const;

export function ThemeToggle() {
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => setMounted(true), []);

  if (!mounted) {
    return <div className="h-9 w-[7.5rem]" aria-hidden />;
  }

  return (
    <div
      role="radiogroup"
      aria-label="Color theme"
      className="inline-flex items-center gap-1 rounded-xl border border-purple-200/30 bg-purple-50/50 p-1 dark:border-white/10 dark:bg-white/5"
    >
      {OPTIONS.map(({ value, label, Icon }) => {
        const active = theme === value;
        return (
          <button
            key={value}
            type="button"
            role="radio"
            aria-checked={active}
            aria-label={label}
            onClick={() => setTheme(value)}
            className={[
              "flex h-7 w-8 items-center justify-center rounded-lg transition-all",
              AXO_FOCUS_RING,
              active
                ? "bg-white text-purple-700 shadow-sm dark:bg-white/15 dark:text-white"
                : "text-gray-500 hover:text-gray-900 dark:text-white/40 dark:hover:text-white/80",
            ].join(" ")}
          >
            <Icon className="h-4 w-4" />
          </button>
        );
      })}
    </div>
  );
}
