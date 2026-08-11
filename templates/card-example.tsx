/**
 * Axo Glass Card — canonical composition.
 *
 * The overlay is a sibling absolute layer, so card content must sit in a
 * `relative z-10` wrapper or the wash paints over it. This is the single most
 * common mistake when hand-rolling the card.
 */

import type { ReactNode } from "react";
import {
  AXO_CARD_OVERLAY,
  AXO_GLASS_CARD,
  AXO_ICON_BOX,
  AXO_TEXT_MUTED,
  AXO_TEXT_PRIMARY,
} from "@/lib/shell-identity";
import { cn } from "@/lib/utils";

export function AxoCard({
  icon,
  title,
  description,
  children,
  className,
}: {
  icon?: ReactNode;
  title: string;
  description?: string;
  children?: ReactNode;
  className?: string;
}) {
  return (
    <div className={cn(AXO_GLASS_CARD, className)}>
      <div className={AXO_CARD_OVERLAY} aria-hidden />

      <div className="relative z-10 p-6">
        <div className="flex items-start gap-3">
          {icon && <div className={cn(AXO_ICON_BOX, "h-9 w-9 shrink-0")}>{icon}</div>}
          <div className="min-w-0">
            <h3 className={cn(AXO_TEXT_PRIMARY, "font-semibold")}>{title}</h3>
            {description && <p className={cn(AXO_TEXT_MUTED, "text-sm")}>{description}</p>}
          </div>
        </div>
        {children && <div className="mt-4">{children}</div>}
      </div>
    </div>
  );
}
