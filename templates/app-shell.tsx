/**
 * Axo App Shell — reference wiring of layers 1 → 6.
 *
 * Copy this into the target project's layout (or a components/layout/AppShell.tsx)
 * and adapt the nav items. The layer order and z-index relationships are load-
 * bearing: the overlay is z-0 and fixed, everything above it needs `relative`
 * plus a z-index, or it disappears under the wash.
 */

import type { ReactNode } from "react";
import Link from "next/link";
import {
  AXO_BORDER,
  AXO_HEADER_BAR,
  AXO_PAGE_CONTAINER,
  AXO_SHELL_BG,
  AXO_SHELL_GLOW,
  AXO_SHELL_OVERLAY,
  AXO_SIDEBAR_EDGE,
  AXO_SIDEBAR_FOOTER,
  AXO_SIDEBAR_HEADER,
  AXO_SIDEBAR_LINK_ACTIVE,
  AXO_SIDEBAR_LINK_INACTIVE,
  AXO_SIDEBAR_STYLE,
  AXO_TEXT_MUTED,
  AXO_TEXT_PRIMARY,
} from "@/lib/shell-identity";
import { ThemeToggle } from "@/components/theme-toggle";
import { cn } from "@/lib/utils";

type NavItem = { href: string; label: string; icon?: ReactNode };

export function AppShell({
  children,
  nav = [],
  currentPath,
  title,
  subtitle,
}: {
  children: ReactNode;
  nav?: NavItem[];
  currentPath?: string;
  title?: string;
  subtitle?: string;
}) {
  return (
    // Layer 1 — shell gradient
    <div className={cn("relative min-h-screen", AXO_SHELL_BG)}>
      {/* Layer 2a — ambient bloom. Do not drop this: without it the cards have
          nothing to refract and the whole system reads as flat panels. */}
      <div className={AXO_SHELL_GLOW} aria-hidden />
      {/* Layer 2b — fixed wash */}
      <div className={AXO_SHELL_OVERLAY} aria-hidden />

      <div className="relative z-10 flex min-h-screen">
        {/* Layer 4 — sidebar (theme-invariant deep purple gradient) */}
        <aside
          style={AXO_SIDEBAR_STYLE}
          className={cn("hidden w-64 shrink-0 flex-col gap-1 p-3 md:flex", AXO_SIDEBAR_EDGE)}
        >
          <div className={AXO_SIDEBAR_HEADER}>
            <span className="flex size-8 items-center justify-center rounded-xl bg-white/15 text-sm font-semibold">
              A
            </span>
            <span className="text-lg font-semibold">Axolutions</span>
          </div>

          <nav className="flex flex-col gap-1" aria-label="Main">
            {nav.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                aria-current={currentPath === item.href ? "page" : undefined}
                className={
                  currentPath === item.href
                    ? AXO_SIDEBAR_LINK_ACTIVE
                    : AXO_SIDEBAR_LINK_INACTIVE
                }
              >
                {item.icon}
                {item.label}
              </Link>
            ))}
          </nav>

          {/* Theme toggle lives in the header, not here — the sidebar is
              `hidden md:flex`, so a toggle placed here disappears on mobile. */}
          <div className={AXO_SIDEBAR_FOOTER}>
            <div className="flex items-center gap-2.5 px-3 py-2 text-sm text-white/70">
              <span className="flex size-7 items-center justify-center rounded-full bg-white/15 text-xs font-semibold text-white">
                U
              </span>
              User
            </div>
          </div>
        </aside>

        <div className="flex min-w-0 flex-1 flex-col">
          {/* Layer 3 — header */}
          <header className={cn(AXO_HEADER_BAR, "flex items-center justify-between px-6 py-4")}>
            <div className="min-w-0">
              {title && <h1 className={cn(AXO_TEXT_PRIMARY, "truncate text-xl font-semibold")}>{title}</h1>}
              {subtitle && <p className={cn(AXO_TEXT_MUTED, "truncate text-sm")}>{subtitle}</p>}
            </div>
            <ThemeToggle />
          </header>

          {/* Layer 5 — page container */}
          <main className="flex-1 p-4 md:p-6">
            <div className={cn(AXO_PAGE_CONTAINER, AXO_BORDER, "p-4 md:p-6")}>{children}</div>
          </main>
        </div>
      </div>
    </div>
  );
}
