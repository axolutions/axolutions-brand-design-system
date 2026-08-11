"use client";

/**
 * Axo Theme Provider — light/dark via next-themes.
 *
 * Wire this once, as high in the tree as possible (app/layout.tsx).
 * `attribute="class"` is REQUIRED: every Shell Identity constant relies on the
 * `.dark` class being on <html>, and globals.css defines `@custom-variant dark`
 * against that same class.
 *
 * The <html> element MUST carry `suppressHydrationWarning` — next-themes writes
 * the class before React hydrates, which otherwise trips a mismatch warning.
 */

import { ThemeProvider as NextThemesProvider } from "next-themes";
import type { ComponentProps } from "react";

export function ThemeProvider({
  children,
  ...props
}: ComponentProps<typeof NextThemesProvider>) {
  return (
    <NextThemesProvider
      attribute="class"
      defaultTheme="system"
      enableSystem
      disableTransitionOnChange
      storageKey="axo-theme"
      {...props}
    >
      {children}
    </NextThemesProvider>
  );
}
