<!-- AXO-DESIGN-SYSTEM:BEGIN v1.0.0 -->
<!--
  Managed by the axo-design-system skill.
  Everything between the BEGIN and END markers is regenerated on each run.
  Put project-specific design decisions BELOW the END marker — that part is
  never overwritten.
-->

# DESIGN.md — Axolutions Design System

This file is the design contract for this repository. **Any agent or developer
writing UI here follows it.** It is not a suggestion layer: if a component
contradicts this document, the component is wrong.

Brand primary: **`#5D0EC1`** → `oklch(0.45 0.25 290)`
Aesthetic: **purple gradient shell + glassmorphism**, full light/dark parity.

---

## 1. The one rule

> **Never write a raw visual class string in a component.
> Import a constant from `lib/shell-identity.ts`.**

Colors, borders, radii, blurs, and shadows live in exactly two places:

| Where | What |
|---|---|
| `app/globals.css` | Design **tokens** (OKLCH CSS variables, light + dark) |
| `lib/shell-identity.ts` | Composed **class strings** (`AXO_*` constants) |

Layout classes (`flex`, `gap-3`, `p-6`, `grid-cols-2`) stay in components — those
are structure, not identity. Anything that carries the brand does not.

```tsx
// ✅ correct
import { AXO_GLASS_CARD, AXO_TEXT_PRIMARY } from "@/lib/shell-identity";
import { cn } from "@/lib/utils";

<div className={cn(AXO_GLASS_CARD, "p-6")}>
  <h2 className={cn(AXO_TEXT_PRIMARY, "text-xl font-semibold")}>Title</h2>
</div>

// ❌ wrong — hardcoded identity, no dark variant, drifts from every other card
<div className="rounded-2xl bg-white/70 border border-purple-200 p-6">
  <h2 className="text-black text-xl font-semibold">Title</h2>
</div>
```

Always combine with `cn()` (clsx + tailwind-merge), never string concatenation —
`twMerge` resolves conflicts such as two competing `rounded-*` classes in favour
of the later one. Plain concatenation silently produces both.

---

## 2. Light & dark mode

**Both themes ship in the same class string.** Every `AXO_*` constant already
carries its `dark:` variants.

```tsx
// ✅ one constant, both themes
<div className={AXO_GLASS_CARD} />

// ❌ never do this — branching on theme in JS
const { theme } = useTheme();
<div className={theme === "dark" ? "bg-black/40" : "bg-white/60"} />
```

Rules:

1. `useTheme()` is for the **theme toggle only**. No other component reads it to
   pick classes.
2. Dark mode is class-based: `.dark` on `<html>`, written by `next-themes` with
   `attribute="class"`. `globals.css` declares `@custom-variant dark (&:is(.dark *))`
   (Tailwind v4) or the config sets `darkMode: "class"` (v3).
3. `<html>` **must** carry `suppressHydrationWarning`. next-themes sets the class
   before hydration; without it React logs a mismatch on every page.
4. Any component that renders differently per theme must gate on a `mounted`
   flag and render a same-size placeholder first, or the layout shifts on
   hydration. See `components/theme-toggle.tsx`.
5. `--primary` stays **purple in dark mode** (`oklch(0.58 0.24 292)`). The
   shadcn starter defaults it to near-white in `.dark` — that is a bug, not a
   choice. If you see `--primary: oklch(0.985 0 0)` under `.dark`, fix it.
6. The **sidebar is theme-invariant**. It renders the same deep purple in light
   and dark, via `AXO_SIDEBAR_STYLE` (an inline `color-mix()` style, because
   Tailwind cannot express that value).

---

## 3. Layer model

The shell is six stacked layers. Order and z-index are load-bearing.

```
Layer 0  <body>              bg-background            token, visually covered by the shell
Layer 1  Shell wrapper       AXO_SHELL_BG             gradient background, min-h-screen
Layer 2  Overlay             AXO_SHELL_OVERLAY        fixed inset-0, pointer-events-none, z-0
Layer 3  Header              AXO_HEADER_BAR           glass bar, relative z-10
Layer 4  Sidebar             AXO_SIDEBAR_STYLE        fixed deep purple (inline style)
Layer 5  Page container      AXO_PAGE_CONTAINER       glass wrapper around page content
Layer 6  Card                AXO_GLASS_CARD           glass card (+ AXO_CARD_OVERLAY inside)
```

Two failure modes to watch for:

- **Content vanishing under the wash.** Layer 2 is `fixed inset-0 z-0`. Anything
  above it needs `relative` plus a z-index. The shell's inner wrapper should be
  `relative z-10`.
- **Card overlay painting over card content.** `AXO_CARD_OVERLAY` is an absolute
  sibling. Card content must live in a `relative z-10` wrapper.

```tsx
<div className={cn("relative min-h-screen", AXO_SHELL_BG)}>   {/* 1 */}
  <div className={AXO_SHELL_OVERLAY} aria-hidden />           {/* 2 */}
  <div className="relative z-10 flex min-h-screen">
    <aside style={AXO_SIDEBAR_STYLE} className="w-64" />      {/* 4 */}
    <div className="flex min-w-0 flex-1 flex-col">
      <header className={AXO_HEADER_BAR} />                   {/* 3 */}
      <main className="flex-1 p-6">
        <div className={cn(AXO_PAGE_CONTAINER, "p-6")}>       {/* 5 */}
          {children}
        </div>
      </main>
    </div>
  </div>
</div>
```

---

## 4. Design tokens

Defined in `app/globals.css` as OKLCH CSS variables, mapped into Tailwind via
`@theme inline` (v4) or `tailwind.config.ts` (v3). Consume them as
`bg-background`, `text-foreground`, `border-border`, `text-primary`, and so on.

### Brand

| Token | Value | Notes |
|---|---|---|
| `--axo-purple` | `oklch(0.45 0.25 290)` | `#5D0EC1` — the brand primary |
| `--axo-purple-deep` | `color-mix(in srgb, oklch(0.45 0.25 290) 85%, black)` | sidebar fill |
| `--axo-purple-soft` | `oklch(0.92 0.08 290)` | tinted surfaces |

### Semantic

| Token | Light | Dark |
|---|---|---|
| `--background` | `oklch(0.99 0.005 290)` | `oklch(0.16 0.02 290)` |
| `--foreground` | `oklch(0.25 0.02 290)` | `oklch(0.985 0 0)` |
| `--card` | `oklch(1 0 0)` | `oklch(0.2 0.02 290)` |
| `--primary` | `oklch(0.45 0.25 290)` | `oklch(0.58 0.24 292)` |
| `--primary-foreground` | `oklch(1 0 0)` | `oklch(1 0 0)` |
| `--muted-foreground` | `oklch(0.55 0.05 290)` | `oklch(0.72 0.03 290)` |
| `--border` | `oklch(0.9 0.02 290)` | `oklch(1 0 0 / 0.12)` |
| `--ring` | `oklch(0.45 0.25 290)` | `oklch(0.58 0.24 292)` |
| `--destructive` | `oklch(0.577 0.245 27.325)` | `oklch(0.637 0.237 25.331)` |
| `--success` | `oklch(0.65 0.19 160)` | `oklch(0.7 0.17 160)` |
| `--warning` | `oklch(0.75 0.18 75)` | `oklch(0.8 0.16 75)` |
| `--info` | `oklch(0.55 0.15 250)` | `oklch(0.65 0.14 250)` |

**Why OKLCH:** perceptually uniform, so lightening a hue for dark mode does not
shift its perceived colour. Do not add hex or HSL tokens alongside these.

### Tailwind palette

The glass layer is built on Tailwind's stock `purple-*` / `indigo-*` / `blue-*`
scales (they harmonise with `#5D0EC1`), used **only inside `shell-identity.ts`**:

- `purple-50 / 100 / 200` — light-mode tinted surfaces and borders
- `purple-400 / 500 / 600 / 700` — accents, buttons, focus rings
- `purple-950`, `indigo-950`, `gray-900` — dark-mode gradient stops
- `rgba(147,51,234,…)` (= `purple-600`) — the purple glow in card shadows

---

## 5. Shell Identity API

`lib/shell-identity.ts`. Every constant carries both themes.

### Layout
| Constant | Use |
|---|---|
| `AXO_SHELL_BG` | Layer 1 — outermost gradient |
| `AXO_SHELL_OVERLAY` | Layer 2 — fixed wash (`aria-hidden`) |
| `AXO_HEADER_BAR` | Layer 3 — top bar |
| `AXO_PAGE_CONTAINER` | Layer 5 — page wrapper |
| `AXO_GLASS_CARD` | Layer 6 — card surface |
| `AXO_CARD_OVERLAY` | inner glow, absolute sibling inside a card |
| `AXO_SIDEBAR_STYLE` | Layer 4 — inline `style`, not a class |

### Text
| Constant | Use |
|---|---|
| `AXO_TEXT_PRIMARY` | headings, main content |
| `AXO_TEXT_SECONDARY` | subtitles, labels |
| `AXO_TEXT_MUTED` | descriptions, captions |
| `AXO_TEXT_SUBTLE` | timestamps, hints |
| `AXO_LINK` | inline links |

### Controls
| Constant | Use |
|---|---|
| `AXO_BUTTON_PRIMARY` | the one main action per view |
| `AXO_BUTTON_SECONDARY` | supporting actions |
| `AXO_BUTTON_OUTLINE` | tertiary / low-emphasis |
| `AXO_BUTTON_DESTRUCTIVE` | delete, revoke, cancel-with-loss |
| `AXO_INPUT` / `AXO_INPUT_DISABLED` | text fields, selects, textareas |
| `AXO_FOCUS_RING` | any custom interactive element |

### Surfaces & content
| Constant | Use |
|---|---|
| `AXO_MODAL` | dialog content |
| `AXO_BADGE` + `_SUCCESS` / `_WARNING` / `_DANGER` | status pills |
| `AXO_ICON_BOX` | small icon container (pair with `h-9 w-9`) |
| `AXO_FEATURE_ROW` | list rows inside cards |
| `AXO_BORDER` / `AXO_DIVIDER` | inner separators |
| `AXO_TABLE_HEADER` / `AXO_TABLE_ROW` | data tables |
| `AXO_EMPTY_STATE` | zero-data states |
| `AXO_SKELETON` | loading placeholders |
| `AXO_TOOLTIP` | tooltip surface |
| `AXO_SIDEBAR_LINK_ACTIVE` / `_INACTIVE` | sidebar nav |

Need something not on this list? **Add it to `shell-identity.ts`** with both
light and dark variants and a JSDoc line. Do not inline it in a component.

---

## 6. Shape, spacing, type, motion

**Radius** — `--radius: 0.75rem`.

| Element | Radius |
|---|---|
| Cards, page containers, modals | `rounded-3xl` |
| Buttons, inputs, feature rows, icon boxes, nav links | `rounded-xl` |
| Badges, pills, avatars | `rounded-full` |
| Nested chips inside a `rounded-xl` control | `rounded-lg` |

Never mix `rounded-2xl` into a card — the family is 3xl → xl → full.

**Spacing** — 4px scale. Card padding `p-6` (`p-4` on mobile), section gaps
`gap-6`, inline element gaps `gap-3`, tight icon+label `gap-2`.

**Typography** — `--font-sans` (Geist Sans → system fallback), `--font-mono` for
code and IDs.

| Role | Classes |
|---|---|
| Page title | `text-2xl font-semibold` + `AXO_TEXT_PRIMARY` |
| Section title | `text-lg font-semibold` + `AXO_TEXT_PRIMARY` |
| Card title | `font-semibold` + `AXO_TEXT_PRIMARY` |
| Body | `text-sm` + `AXO_TEXT_SECONDARY` |
| Caption | `text-sm` + `AXO_TEXT_MUTED` |
| Meta | `text-xs` + `AXO_TEXT_SUBTLE` |

**Blur** — `backdrop-blur-xl` for cards/header/modals, `backdrop-blur-sm` for
inputs and the page container. Blur is expensive; do not stack more than two
blurred layers in one subtree.

**Motion** — `transition-all` on interactive elements, default duration. Entry
animations via `tw-animate-css`. `globals.css` already honours
`prefers-reduced-motion`; do not add motion that bypasses it.

---

## 7. Accessibility

- Every interactive element gets a visible focus state: `AXO_FOCUS_RING`, or a
  constant that already includes `focus:` classes (`AXO_INPUT`).
- Contrast: body text ≥ 4.5:1, large text and UI borders ≥ 3:1. `AXO_TEXT_SUBTLE`
  is decorative — never use it for content a user must read.
- Glass surfaces reduce effective contrast. Text on a card uses
  `AXO_TEXT_PRIMARY` or `AXO_TEXT_SECONDARY`, never `AXO_TEXT_SUBTLE`.
- Icon-only buttons need `aria-label`. Decorative layers (`AXO_SHELL_OVERLAY`,
  `AXO_CARD_OVERLAY`) need `aria-hidden`.
- Active nav links carry `aria-current="page"`, not just a colour change.
- Never signal state with colour alone — pair with an icon or text.

---

## 8. Anti-patterns

| Don't | Do |
|---|---|
| Hardcode `#5D0EC1` / `#9200cf` / `rgb(...)` in a component | Use a token or an `AXO_*` constant |
| `theme === "dark" ? a : b` for classes | Use the constant — it has both |
| Write a new glass card by hand | `AXO_GLASS_CARD` + `AXO_CARD_OVERLAY` |
| `className={AXO_GLASS_CARD + " p-6"}` | `cn(AXO_GLASS_CARD, "p-6")` |
| Add a `dark:` class to only some of a component | Both themes, always |
| Style a one-off `bg-purple-500/10` inline | Add a named constant |
| Leave `--primary` near-white under `.dark` | Purple in both themes |
| `darkMode: "media"` | `darkMode: "class"` |
| Edit `shell-identity.ts` per project to taste | Change it in the design-system repo, propagate |

---

## 9. Adding a new component

1. Check §5 — does a constant already cover it?
2. If not, add one to `lib/shell-identity.ts` with light + dark and a JSDoc line.
3. Build the component from constants + layout classes only.
4. Check both themes, and keyboard focus.
5. Run the audit (§10).

---

## 10. Audit

Run before opening a PR that touches UI:

```bash
# hardcoded brand colors outside the token/identity files
rg -n "#5D0EC1|#9200cf|#5d0ec1|rgb\(|rgba\(" --glob '!**/globals.css' \
   --glob '!**/shell-identity.ts' --glob '!node_modules' -t tsx -t ts

# theme branching in JS
rg -n 'theme\s*===\s*["'"'"']dark' -t tsx -t ts

# light-only classes: a bg-white/gray-900 with no dark: sibling on the same line
rg -n 'className=.*(bg-white|bg-black|text-black|text-gray-900)' -t tsx \
  | rg -v 'dark:' | rg -v 'shell-identity'

# glass cards built by hand
rg -n 'backdrop-blur' -t tsx --glob '!**/shell-identity.ts'
```

Each hit is either a violation to fix or a new constant to add.

Checklist:

- [ ] `DESIGN.md` present and current
- [ ] `lib/shell-identity.ts` present, unmodified from the design-system source
- [ ] `globals.css` carries the OKLCH tokens, light + dark
- [ ] `darkMode: "class"` (v3) or `@custom-variant dark` (v4)
- [ ] `ThemeProvider` mounted with `attribute="class"`
- [ ] `<html suppressHydrationWarning>`
- [ ] A theme toggle reachable from the app shell
- [ ] Every screen verified in light **and** dark
- [ ] No hardcoded brand colours outside `globals.css` / `shell-identity.ts`
- [ ] Focus visible on every interactive element
- [ ] Build passes

---

## 11. Reference implementations

| Repo | What to look at |
|---|---|
| `axoplataforma/apps/*/lib/shell-identity.ts` | the shell in a monorepo, per-app |
| `orbita/src/lib/shell-identity.ts` | full OKLCH token set + legacy bridge |
| `cosmos-editor/app/globals.css` | canonical brand token declaration |

<!-- AXO-DESIGN-SYSTEM:END -->

---

## Project-specific design notes

<!-- Everything below this line is yours. The skill never overwrites it. -->
