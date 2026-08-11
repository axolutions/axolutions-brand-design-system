# Axolutions Design System

An AI skill. Point it at a repository and it brings that repository to the
Axolutions visual standard — then leaves behind a `DESIGN.md` that keeps it
there.

**Brand primary:** `#5D0EC1` → `oklch(0.45 0.25 290)`
**Aesthetic:** purple gradient shell + glassmorphism, full light/dark parity.

---

## What the skill does

Invoked with `/axo-design-system` (or by asking to "apply the Axo design system"),
it runs seven phases against the current repository:

**1. Detect** — framework, Tailwind version, package manager, CSS entry point,
path alias, source root, and what already exists (`DESIGN.md`,
`shell-identity.ts`, an existing theme provider). Everything downstream branches
on this, so it reports the detected stack before touching anything.

**2. Install what's missing** — `next-themes`, `clsx`, `tailwind-merge`,
`lucide-react`, `tw-animate-css`. **If the project has no Tailwind, the skill
installs it** (v4, with the right PostCSS or Vite wiring for the detected
framework). It never silently crosses a Tailwind major version on an existing
project.

**3. Write `DESIGN.md`** — the design contract, at the repo root.

- Doesn't exist → created from the template.
- Exists with the `AXO-DESIGN-SYSTEM` markers → only the managed block is
  regenerated; the project's own notes below the end marker survive untouched.
- Exists without markers → existing content is preserved and moved below the
  marker, then the managed block is written above it.

**4. Install the design system files**

| File | Role |
|---|---|
| `lib/shell-identity.ts` | the `AXO_*` class constants — every one carries light **and** dark |
| `app/globals.css` | OKLCH design tokens, light + dark, mapped into Tailwind |
| `components/theme-provider.tsx` | `next-themes`, class-based |
| `components/theme-toggle.tsx` | light / dark / system, hydration-safe |
| `lib/utils.ts` | `cn()` — clsx + tailwind-merge |

`globals.css` and `lib/utils.ts` are merged, not overwritten. Legacy prefixed
tokens (`--orbita-*`, `--cosmos-*`) are kept and re-pointed at the new brand
values rather than deleted, because components still read them.

**5. Wire the theme** — `ThemeProvider` with `attribute="class"`,
`<html suppressHydrationWarning>`, the toggle mounted somewhere reachable. If a
provider already exists, it fixes that one instead of adding a second tree.

**6. Apply the shell** — this is the phase that makes the project *look* like
Axo. The root layout gets the six shell layers; sidebars, headers, cards,
buttons, inputs, badges, tables, and modals get converted to the constants.
Existing layouts are converted in place — nav data, routing, and behaviour are
preserved; only visual classes change.

**7. Verify** — runs the build and `scripts/axo-audit.sh`, then reports honestly.
A partial migration is reported as partial, with the list of what was and wasn't
converted.

---

## The system it applies

### One rule

> Never write a raw visual class string in a component. Import a constant from
> `lib/shell-identity.ts`.

Identity lives in exactly two files — `globals.css` (tokens) and
`shell-identity.ts` (composed class strings). Layout classes (`flex`, `gap-3`,
`p-6`) stay in components; anything carrying the brand does not.

### Light and dark in one string

Every constant ships both themes:

```ts
export const AXO_GLASS_CARD = [
  "relative overflow-hidden rounded-3xl border backdrop-blur-xl",
  "bg-white/60 border-purple-200/30",
  "shadow-[0_4px_24px_-4px_rgba(147,51,234,0.08)]",
  "dark:bg-black/40 dark:border-white/20",
  "dark:shadow-[0_4px_24px_-4px_rgba(0,0,0,0.4)]",
].join(" ");
```

So components never branch on theme. `useTheme()` exists for the toggle and
nothing else.

### Six layers

```
Layer 1  Shell wrapper    AXO_SHELL_BG          gradient background
Layer 2  Overlay          AXO_SHELL_OVERLAY     fixed wash, z-0
Layer 3  Header           AXO_HEADER_BAR        glass bar, relative z-10
Layer 4  Sidebar          AXO_SIDEBAR_STYLE     deep purple, theme-invariant
Layer 5  Page container   AXO_PAGE_CONTAINER    glass wrapper
Layer 6  Card             AXO_GLASS_CARD        glass card + inner glow
```

The sidebar is deliberately the same deep purple in both themes — it uses an
inline `color-mix()` style because Tailwind can't express that value.

### Tokens

OKLCH throughout, so lightening a hue for dark mode doesn't shift its perceived
colour. `--primary` stays purple in dark mode (`oklch(0.58 0.24 292)`) — the
shadcn starter defaults it to near-white, which erases the brand.

---

## Install

Symlink into your skills directory:

```bash
ln -s ~/code/axolutions/design-system ~/.claude/skills/axo-design-system
```

Or per-project:

```bash
ln -s ~/code/axolutions/design-system .claude/skills/axo-design-system
```

Then, in any repo: `/axo-design-system` — or just ask for the Axo design system
to be applied.

---

## Audit an existing repo

Standalone, no skill invocation needed:

```bash
bash ~/code/axolutions/design-system/scripts/axo-audit.sh /path/to/repo
```

Checks structure, theme wiring, token integrity, hardcoded brand hex, theme
branching in JS, hand-rolled glass surfaces, and light-only class strings.
Exit code 0 = clean.

---

## Layout

```
SKILL.md                    the skill — the procedure the AI follows
README.md                   this file
templates/
  DESIGN.md                 the contract written into target repos
  shell-identity.ts         canonical AXO_* constants
  globals.css               Tailwind v4 OKLCH tokens (light + dark)
  globals.v3.css            Tailwind v3 variant
  tailwind.config.v3.ts     Tailwind v3 config
  theme-provider.tsx        next-themes wiring
  theme-toggle.tsx          light / dark / system control
  cn.ts                     clsx + tailwind-merge helper
  app-shell.tsx             reference layout, layers 1→6
  card-example.tsx          canonical glass card composition
references/
  stack-setup.md            per-framework install steps
  migration.md              converting an existing codebase
  non-react-stacks.md       Nuxt / Vue / plain HTML
scripts/
  axo-audit.sh              violation finder
```

---

## Changing the system

`templates/` is canonical. A project that needs a constant the system doesn't
have gets it **added here and propagated**, not improvised locally. If a repo has
a drifted `shell-identity.ts`, the skill diffs it, reports the differences, and
replaces it.

---

## Provenance

Reconciled from the Shell Identity implementations already running in
production:

| Repo | Contribution |
|---|---|
| `axoplataforma/apps/*/lib/shell-identity.ts` | the layer model and constant set, per-app in a monorepo |
| `orbita/src/lib/shell-identity.ts` | full OKLCH token set and the legacy-token bridge pattern |
| `cosmos-editor/app/globals.css` | the canonical brand declaration — `#5D0EC1` |

Those copies had drifted from each other: cards at `rounded-2xl` vs `rounded-3xl`,
inputs at `rounded-lg` vs `rounded-xl`, primary buttons at `purple-500` vs
`purple-600`, sidebar links styled dark-only, and `--primary` falling back to
near-white in dark mode. The templates here are the resolved version;
`references/migration.md` lists each drift and its correction.
