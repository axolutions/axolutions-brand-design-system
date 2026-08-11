#!/usr/bin/env bash
#
# axo-audit.sh — check a repository against the Axolutions design system.
#
# Usage: bash axo-audit.sh [repo-root]   (defaults to the current directory)
#
# Exit code 0 = clean, 1 = violations found. Every hit is either something to
# fix or a new constant to add to shell-identity.ts — read them, don't just
# count them.

set -uo pipefail

ROOT="${1:-.}"
cd "$ROOT" || { echo "axo-audit: cannot cd into '$ROOT'" >&2; exit 2; }

if ! command -v rg >/dev/null 2>&1; then
  echo "axo-audit: ripgrep (rg) is required" >&2
  exit 2
fi

VIOLATIONS=0
CODE_GLOBS=(-g '*.tsx' -g '*.ts' -g '*.jsx' -g '*.js' -g '*.vue'
            -g '!node_modules/**' -g '!**/*.d.ts' -g '!dist/**' -g '!.next/**' -g '!build/**')

MAX_HITS="${AXO_AUDIT_MAX_HITS:-15}"

section() { printf '\n\033[1m%s\033[0m\n' "$1"; }

# Print at most MAX_HITS lines, and always say how many were withheld.
report() {
  local title="$1" hits="$2" total shown
  [ -z "$hits" ] && return 0
  total=$(printf '%s\n' "$hits" | wc -l | tr -d ' ')
  section "✗ $title ($total)"
  printf '%s\n' "$hits" | head -n "$MAX_HITS"
  if [ "$total" -gt "$MAX_HITS" ]; then
    shown=$((total - MAX_HITS))
    printf '  … %d more not shown (AXO_AUDIT_MAX_HITS=%s)\n' "$shown" "$MAX_HITS"
  fi
  VIOLATIONS=$((VIOLATIONS + 1))
}

# ── Structure ────────────────────────────────────────────────────────────────
section "Structure"

check_file() {
  local label="$1"; shift
  for f in "$@"; do
    if [ -f "$f" ]; then printf '  ✓ %s (%s)\n' "$label" "$f"; return 0; fi
  done
  printf '  ✗ %s — missing\n' "$label"
  VIOLATIONS=$((VIOLATIONS + 1))
  return 1
}

check_file "DESIGN.md"        DESIGN.md
check_file "shell-identity"   lib/shell-identity.ts src/lib/shell-identity.ts app/utils/shell-identity.ts
check_file "CSS entry"        app/globals.css src/app/globals.css styles/globals.css src/index.css app/assets/css/main.css

# ── Theme wiring ─────────────────────────────────────────────────────────────
section "Theme wiring"

if rg -q 'suppressHydrationWarning' "${CODE_GLOBS[@]}" . 2>/dev/null; then
  printf '  ✓ suppressHydrationWarning present\n'
else
  printf '  ✗ <html suppressHydrationWarning> missing — hydration mismatch on every load\n'
  VIOLATIONS=$((VIOLATIONS + 1))
fi

if rg -q 'attribute=("|\x27)class' "${CODE_GLOBS[@]}" . 2>/dev/null \
   || rg -q "classSuffix:\s*(''|\"\")" "${CODE_GLOBS[@]}" . 2>/dev/null; then
  printf '  ✓ class-based theme attribute\n'
else
  printf '  ✗ ThemeProvider attribute="class" not found — dark: variants will not respond to the toggle\n'
  VIOLATIONS=$((VIOLATIONS + 1))
fi

if rg -q 'darkMode' -g 'tailwind.config.*' . 2>/dev/null; then
  if rg -q 'darkMode:\s*\[?\s*("|\x27)class' -g 'tailwind.config.*' . 2>/dev/null; then
    printf '  ✓ darkMode: "class" (Tailwind v3)\n'
  else
    printf '  ✗ tailwind.config sets darkMode to something other than "class"\n'
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
elif rg -q '@custom-variant dark' -g '*.css' . 2>/dev/null; then
  printf '  ✓ @custom-variant dark (Tailwind v4)\n'
else
  printf '  ✗ no class-based dark variant declared (v4 @custom-variant / v3 darkMode)\n'
  VIOLATIONS=$((VIOLATIONS + 1))
fi

# ── Token integrity ──────────────────────────────────────────────────────────
section "Token integrity"

# Walk each CSS file tracking whether we are inside a `.dark { … }` block, and
# report only the offending --primary line rather than the whole block.
WHITE_PRIMARY=$(
  while IFS= read -r css; do
    awk -v f="$css" '
      /\.dark[[:space:]]*\{/ { indark = 1 }
      indark && /\}/         { indark = 0 }
      indark && /--primary:[[:space:]]*oklch\(0\.9[0-9]*[[:space:]]+0[[:space:]]+0\)/ {
        gsub(/^[[:space:]]+/, "")
        print f ":" NR ": " $0
      }
    ' "$css"
  done < <(rg --files -g '*.css' -g '!node_modules/**' . 2>/dev/null)
)
report "--primary is near-white in dark mode (shadcn default leak — brand disappears)" "$WHITE_PRIMARY"

# ── Component-level violations ───────────────────────────────────────────────
IDENTITY_EXCLUDE=(-g '!**/shell-identity.ts' -g '!**/globals.css' -g '!**/main.css')

HARDCODED=$(rg -n '#5[Dd]0[Ee][Cc]1|#9200cf|#6a00cf|#b44dff|#d896ff|#4a0082' \
  "${CODE_GLOBS[@]}" "${IDENTITY_EXCLUDE[@]}" . 2>/dev/null)
report "Hardcoded brand hex outside the token layer" "$HARDCODED"

THEME_BRANCH=$(rg -n '(theme|resolvedTheme)\s*===\s*("|\x27)dark' \
  "${CODE_GLOBS[@]}" "${IDENTITY_EXCLUDE[@]}" \
  -g '!**/theme-toggle.tsx' -g '!**/theme-provider.tsx' . 2>/dev/null)
report "Theme branching in JS — legitimate only inside a theme toggle; anything picking classes or colours should use an AXO_* constant" "$THEME_BRANCH"

HANDROLLED=$(rg -n 'backdrop-blur' "${CODE_GLOBS[@]}" "${IDENTITY_EXCLUDE[@]}" . 2>/dev/null)
report "Hand-rolled glass surfaces — use AXO_GLASS_CARD / AXO_MODAL / AXO_HEADER_BAR" "$HANDROLLED"

LIGHT_ONLY=$(rg -n 'className=.*(bg-white|bg-black|text-black|text-gray-900|border-gray-200)' \
  "${CODE_GLOBS[@]}" "${IDENTITY_EXCLUDE[@]}" -g '!**/ui/**' . 2>/dev/null | rg -v 'dark:')
report "Light-only class strings (no dark: sibling)" "$LIGHT_ONLY"

# ── Summary ──────────────────────────────────────────────────────────────────
printf '\n'
if [ "$VIOLATIONS" -eq 0 ]; then
  printf '\033[32m✓ axo-audit: clean\033[0m\n'
  exit 0
fi
printf '\033[31m✗ axo-audit: %d check(s) failed\033[0m — see DESIGN.md §8 and §10\n' "$VIOLATIONS"
exit 1
