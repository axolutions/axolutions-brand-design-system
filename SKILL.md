---
name: axo-design-system
description: Apply the Axolutions design system (purple gradient shell + glassmorphism, full light/dark) to a repository. Creates or updates DESIGN.md, installs the design tokens and Shell Identity constants, wires theme switching, and migrates existing UI to the standard. Use when the user asks to apply the Axo/Axolutions design system or visual identity, standardize a project's UI, create or refresh DESIGN.md, set up the purple glass theme, or add light/dark mode to an Axo project. Installs Tailwind if the project does not have it.
---

# Axolutions Design System

Bring any repository to the Axolutions visual standard, and leave behind a
`DESIGN.md` that keeps it there.

Brand primary: `#5D0EC1` → `oklch(0.45 0.25 290)`.
Aesthetic: purple gradient shell + glassmorphism, full light/dark parity.

Templates referenced below live in this skill's directory, under `templates/`
and `references/`. Read a template before writing it — never reproduce one from
memory.

---

## Procedure

Work through these phases in order. Do not skip phase 1: everything after it
branches on what you find.

### Phase 1 — Detect

Establish, from the target repo:

| Question | How |
|---|---|
| Framework | `package.json` deps: `next`, `vite`, `nuxt`, `react-router`, none |
| Tailwind, and version | `tailwindcss` in deps; v4 if `^4`, v3 if `^3`; absent = install |
| Package manager | lockfile: `bun.lock` → bun, `pnpm-lock.yaml` → pnpm, `package-lock.json` → npm, `yarn.lock` → yarn |
| CSS entry | `app/globals.css`, `src/app/globals.css`, `styles/globals.css`, `src/index.css` |
| Path alias | `tsconfig.json` `compilerOptions.paths` — is `@/*` mapped, and to what root? |
| Source root | `app/` at repo root vs `src/app/` |
| Existing state | Does `DESIGN.md` exist? `lib/shell-identity.ts`? `next-themes`? a `ThemeProvider`? |
| Existing UI | shadcn (`components.json`), Nuxt UI, MUI, plain CSS, nothing |

State the detected stack to the user in two or three lines before changing
anything. If the framework is not React/Next, read
`references/non-react-stacks.md` before continuing.

### Phase 2 — Install what's missing

Use the detected package manager. Only install what is actually absent.

**Tailwind absent** — install v4 (never introduce v3 into a project that has
neither):

```bash
# Next.js
<pm> add tailwindcss @tailwindcss/postcss postcss
```

Then create `postcss.config.mjs`:

```js
export default { plugins: { "@tailwindcss/postcss": {} } };
```

For Vite, install `@tailwindcss/vite` instead and add it to `vite.config.ts`
plugins. Read `references/stack-setup.md` for the exact per-framework steps.

**Always ensure these:**

```bash
<pm> add next-themes clsx tailwind-merge lucide-react
<pm> add -D tw-animate-css   # or as a regular dep; it is imported from CSS
```

Skip any already present. Do not upgrade or downgrade Tailwind across a major
version without asking the user first — a v3→v4 migration is its own task.

**Fonts — do not skip this.** The brand typeface is **Public Sans**, with
**JetBrains Mono** for code and IDs. `globals.css` points `--font-sans` at
`var(--font-public-sans, "Public Sans")`, so if nothing loads the font the app
silently falls back to system-ui and looks generic no matter how correct the
rest of the system is. Wire it for the detected stack:

```tsx
// Next.js — app/layout.tsx
import { Public_Sans, JetBrains_Mono } from "next/font/google";

const sans = Public_Sans({ variable: "--font-public-sans", subsets: ["latin"], display: "swap" });
const mono = JetBrains_Mono({ variable: "--font-jetbrains-mono", subsets: ["latin"], display: "swap" });

<html lang="pt-BR" suppressHydrationWarning className={`${sans.variable} ${mono.variable}`}>
```

For Vite or static HTML, load it with a stylesheet link instead — see
`references/stack-setup.md`. Afterwards, confirm in the browser that the
rendered font is actually Public Sans and not the system fallback.

### Phase 3 — Write DESIGN.md

The target repo's `DESIGN.md`, at its root.

- **Absent** → copy `templates/DESIGN.md` verbatim.
- **Present, with the `AXO-DESIGN-SYSTEM:BEGIN` marker** → replace only the
  block between `BEGIN` and `END` with the current template's block. Everything
  below `END` is the project's own and must survive untouched.
- **Present, without markers** → read it first. Preserve any project-specific
  content by moving it below the `END` marker, then write the managed block
  above it. Tell the user exactly what you carried over.

Never delete a project's own design notes.

### Phase 4 — Install the design system files

Copy templates into the repo, respecting its source root and path alias:

| Template | Destination |
|---|---|
| `templates/shell-identity.ts` | `lib/shell-identity.ts` (or `src/lib/`) |
| `templates/cn.ts` | `lib/utils.ts` — **merge**, don't clobber |
| `templates/theme-provider.tsx` | `components/theme-provider.tsx` |
| `templates/theme-toggle.tsx` | `components/theme-toggle.tsx` |
| `templates/globals.css` (v4) or `templates/globals.v3.css` (v3) | the detected CSS entry |
| `templates/tailwind.config.v3.ts` (v3 only) | merge into existing `tailwind.config.*` |

Rules:

- `lib/utils.ts` usually already exports `cn` in shadcn projects. If an
  equivalent exists, keep it — only add `cn` when missing.
- **globals.css is a merge, not an overwrite.** Replace the token blocks
  (`:root`, `.dark`, `@theme inline`, base layer) with the template's. Preserve
  every project-specific rule below, and any existing `@import`, custom
  `@utility`, keyframes, or component classes. Move preserved rules under the
  `Project Extensions` marker.
- If the project has legacy prefixed tokens (`--orbita-*`, `--cosmos-*`), keep
  them and point them at the new brand tokens rather than deleting them —
  removing them breaks existing components. Orbita has a working example.
- If the alias is not `@/`, rewrite imports in the copied files to match.
- Tailwind v3 only: ensure `darkMode: "class"` and that `content` globs cover
  `lib/shell-identity.ts`, or every class in it gets purged.

### Phase 5 — Wire the theme

In the root layout (`app/layout.tsx` or equivalent):

1. `<html lang="..." suppressHydrationWarning>` — required, non-negotiable.
2. Wrap children in `<ThemeProvider>`. If the project already has providers,
   nest inside the outermost client provider rather than adding a second tree.
3. Ensure the CSS entry is imported.
4. Mount `<ThemeToggle />` somewhere reachable — the header, per
   `templates/app-shell.tsx`.

If the project already uses `next-themes`, do not add a second provider. Fix the
existing one instead: `attribute` must be `"class"`; if `enableSystem={false}`
with a forced `defaultTheme`, tell the user it disables light mode and ask before
changing it.

### Phase 6 — Apply the shell

This is the phase that makes the project *look* like Axo. Do not stop at
phase 5.

1. **Shell layers.** Wrap the app's root layout in layers 1→5 following
   `templates/app-shell.tsx`. If the project already has a layout with a sidebar
   and header, convert it in place rather than replacing it — keep its nav data,
   routing, and behaviour; swap only the visual classes.
   **`AXO_SHELL_GLOW` is mandatory.** Glassmorphism needs local luminance
   variation behind the glass; a single linear gradient across the viewport is
   locally flat, so without the bloom layer every card collapses into a flat
   panel and the whole system looks wrong. This is the most common way the
   result fails while every individual class is technically correct.
2. **Sidebar.** Apply `AXO_SIDEBAR_STYLE` as an inline `style`, and
   `AXO_SIDEBAR_LINK_ACTIVE` / `_INACTIVE` to nav links. Add
   `aria-current="page"` to the active one. Use `AXO_SIDEBAR_HEADER`,
   `AXO_SIDEBAR_SECTION_LABEL`, `AXO_SIDEBAR_DIVIDER` and `AXO_SIDEBAR_FOOTER`
   to give it structure — an unbroken full-height slab of saturated purple with
   five links floating at the top looks unfinished.
   **Everything inside the sidebar is theme-invariant.** The sidebar is always
   deep purple, so its contents are styled against purple (white-based), never
   against the page theme. Adding a light-mode variant to something in the
   sidebar paints dark text on a dark panel and it disappears.
3. **Cards.** Every card-like surface becomes `AXO_GLASS_CARD` +
   `AXO_CARD_OVERLAY`, content in a `relative z-10` wrapper. See
   `templates/card-example.tsx`.
4. **Controls.** Buttons → `AXO_BUTTON_*`. Inputs, selects, textareas →
   `AXO_INPUT`. Badges → `AXO_BADGE*`. Tables → `AXO_TABLE_*`. Modals →
   `AXO_MODAL`.
5. **Text.** Replace `text-black`, `text-gray-900`, `text-white`, and bare
   `text-muted-foreground` in components with `AXO_TEXT_*`.
6. **shadcn components.** Leave `components/ui/*` mostly alone — it already
   consumes the tokens, so retheming `globals.css` retunes it for free. Only
   patch a `ui/` file when it hardcodes a colour outside the token system.

Read `references/migration.md` before touching an existing codebase — it covers
ordering, the grep patterns that find work, and what to leave alone.

For a large migration, convert the shared layout and the highest-traffic screens
first, then sweep the rest. Report which screens you converted and which you did
not.

### Phase 7 — Verify

Run, and report real output:

```bash
<pm> run build        # or lint / typecheck if no build script
bash <skill-dir>/scripts/axo-audit.sh <repo-root>
```

Then check by hand:

- [ ] `DESIGN.md` at repo root, managed block current, project notes preserved
- [ ] `lib/shell-identity.ts` byte-identical to the template
- [ ] Tokens present for light **and** dark; `--primary` purple in both
- [ ] `darkMode: "class"` (v3) / `@custom-variant dark` (v4)
- [ ] `ThemeProvider` with `attribute="class"`, `<html suppressHydrationWarning>`
- [ ] Theme toggle reachable and working both directions
- [ ] **Public Sans actually rendering** — not the system fallback
- [ ] **`AXO_SHELL_GLOW` present** and cards read as glass, not flat panels
- [ ] Sidebar links readable in **light** mode (the theme-invariance trap)
- [ ] Shell layers applied; nothing hidden under the overlay
- [ ] Audit script reports no violations, or each remaining one is explained
- [ ] Build passes

Report honestly. If a screen was left unconverted or the build fails, say so
with the output — do not describe the work as complete.

---

## Guardrails

- **Never invent brand values.** The tokens and constants in `templates/` are
  canonical. If something is missing, add it to the template in this repo so
  every project gets it — don't improvise per-project.
- **`shell-identity.ts` is not project-editable.** Projects that need extra
  constants get them added here and propagated. If a project already has a
  drifted copy, diff it, report the differences, and replace it — carrying any
  genuinely project-specific constant into a separate file that re-exports.
- **Both themes, always.** A class string with a light value and no `dark:`
  sibling is a bug.
- **Preserve behaviour.** This skill changes appearance. Routing, data fetching,
  state, and business logic stay exactly as they were.
- **Don't mass-rewrite without saying so.** Before converting more than a
  handful of files, list what you are about to touch.
- The repo is a git repo: it is fine to make the edits, but don't commit or push
  unless the user asks.

---

## Files in this skill

```
SKILL.md                        this file
README.md                       human-facing description of the skill
templates/
  DESIGN.md                     the contract written into target repos
  shell-identity.ts             canonical AXO_* constants
  globals.css                   Tailwind v4 OKLCH tokens (light + dark)
  globals.v3.css                Tailwind v3 variant
  tailwind.config.v3.ts         Tailwind v3 config
  theme-provider.tsx            next-themes wiring
  theme-toggle.tsx              light / dark / system control
  cn.ts                         clsx + tailwind-merge helper
  app-shell.tsx                 reference layout, layers 1→6
  card-example.tsx              canonical glass card composition
  static-shell.html             complete no-build page (CDN Tailwind)
references/
  stack-setup.md                per-framework install steps
  migration.md                  converting an existing codebase
  non-react-stacks.md           Nuxt / Vue / plain HTML guidance
scripts/
  axo-audit.sh                  finds violations in a target repo
```
