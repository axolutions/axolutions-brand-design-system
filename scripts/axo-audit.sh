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

IDENTITY_EXCLUDE=(-g '!**/shell-identity.ts' -g '!**/globals.css' -g '!**/main.css')

# ── Silent-failure checks ────────────────────────────────────────────────────
# These two break the look completely while every individual class stays valid,
# so nothing errors and the audit is the only thing that catches them.
section "Silent failures"

# 1. The brand font must actually be loaded, not just referenced.
if rg -q 'next/font|fonts\.googleapis\.com|@fontsource|localFont' \
     "${CODE_GLOBS[@]}" -g '*.css' -g '*.html' . 2>/dev/null; then
  printf '  ✓ a font loader is wired\n'
else
  printf '  ✗ no font loader found — Public Sans never loads and the app\n'
  printf '    silently renders in the system font (next/font, a Google Fonts\n'
  printf '    <link>, or @fontsource)\n'
  VIOLATIONS=$((VIOLATIONS + 1))
fi

# Catch a --font-sans pointing at a variable nothing defines.
FONT_VAR=$(rg -o --no-filename '--font-sans:\s*var\(([^,)]+)' -r '$1' -g '*.css' . 2>/dev/null | head -1)
if [ -n "$FONT_VAR" ] && ! rg -q -- "${FONT_VAR}[\"']?\s*[:=]|variable:\s*[\"']${FONT_VAR}" \
     "${CODE_GLOBS[@]}" -g '*.css' . 2>/dev/null; then
  printf '  ✗ --font-sans points at %s, which nothing defines — the whole app\n' "$FONT_VAR"
  printf '    falls through to the system font\n'
  VIOLATIONS=$((VIOLATIONS + 1))
fi

# 2. The glass needs the ambient bloom behind it.
if rg -q 'AXO_SHELL_BG|axo-shell-bg' "${CODE_GLOBS[@]}" -g '*.html' . 2>/dev/null; then
  if rg -q 'AXO_SHELL_GLOW|axo-shell-glow' "${CODE_GLOBS[@]}" -g '*.html' -g '*.css' . 2>/dev/null; then
    printf '  ✓ ambient glow layer present\n'
  else
    printf '  ✗ shell background used without AXO_SHELL_GLOW — cards have nothing\n'
    printf '    to refract and render as flat panels instead of glass\n'
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
fi

# 3. Sidebar contents are theme-invariant; a dark: variant there disappears.
SIDEBAR_DARK=$(rg -n --multiline --multiline-dotall \
  'AXO_SIDEBAR_(LINK_[A-Z]+|HEADER|FOOTER|DIVIDER|SECTION_LABEL|EDGE)[^;]*?dark:' \
  -g '**/shell-identity.ts' . 2>/dev/null)
report "dark: variant inside a sidebar constant — the sidebar never changes theme, so this renders dark-on-dark in light mode" "$SIDEBAR_DARK"

# ── Component-level violations ───────────────────────────────────────────────

HARDCODED=$(rg -n '#5[Dd]0[Ee][Cc]1|#9200cf|#6a00cf|#b44dff|#d896ff|#4a0082' \
  "${CODE_GLOBS[@]}" "${IDENTITY_EXCLUDE[@]}" . 2>/dev/null)
report "Hardcoded brand hex outside the token layer" "$HARDCODED"

THEME_BRANCH=$(rg -n '(theme|resolvedTheme)\s*===\s*("|\x27)dark' \
  "${CODE_GLOBS[@]}" "${IDENTITY_EXCLUDE[@]}" \
  -g '!**/theme-toggle.tsx' -g '!**/theme-provider.tsx' . 2>/dev/null)
report "Theme branching in JS — legitimate only inside a theme toggle; anything picking classes or colours should use an AXO_* constant" "$THEME_BRANCH"

HANDROLLED=$(rg -n 'backdrop-blur' "${CODE_GLOBS[@]}" "${IDENTITY_EXCLUDE[@]}" . 2>/dev/null)
report "Hand-rolled glass surfaces — use AXO_GLASS_CARD / AXO_MODAL / AXO_HEADER_BAR" "$HANDROLLED"

# Translucent white overlays (bg-white/5 … /30, text-white/NN) are the
# theme-invariant idiom used on the purple sidebar, so they are exempt — they
# are painted over a panel that never changes theme.
LIGHT_ONLY=$(rg -n 'className=.*(bg-white|bg-black|text-black|text-gray-900|border-gray-200)' \
  "${CODE_GLOBS[@]}" "${IDENTITY_EXCLUDE[@]}" -g '!**/ui/**' . 2>/dev/null \
  | rg -v 'dark:' \
  | rg -v 'bg-white/(5|10|15|20|25|30)\b')
report "Light-only class strings (no dark: sibling, excluding sidebar overlays)" "$LIGHT_ONLY"

# ── Summary ──────────────────────────────────────────────────────────────────
printf '\n'
if [ "$VIOLATIONS" -eq 0 ]; then
  printf '\033[32m✓ axo-audit: clean\033[0m\n'
  exit 0
fi
printf '\033[31m✗ axo-audit: %d check(s) failed\033[0m — see DESIGN.md §8 and §10\n' "$VIOLATIONS"
exit 1
