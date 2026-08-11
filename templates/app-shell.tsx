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
  AXO_SHELL_OVERLAY,
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
      {/* Layer 2 — fixed wash */}
      <div className={AXO_SHELL_OVERLAY} aria-hidden />

      <div className="relative z-10 flex min-h-screen">
        {/* Layer 4 — sidebar (theme-invariant deep purple) */}
        <aside
          style={AXO_SIDEBAR_STYLE}
          className="hidden w-64 shrink-0 flex-col gap-1 p-4 md:flex"
        >
          <div className="px-3 py-4 text-lg font-semibold text-white">Axolutions</div>
          <nav className="flex flex-col gap-1">
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
