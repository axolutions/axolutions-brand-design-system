# Migrating an existing codebase

Read this during **phase 6**, before editing components.

The goal is a codebase where identity lives in `globals.css` and
`shell-identity.ts`, and components carry only structure. Get there without
breaking behaviour.

---

## Order of work

Convert in this order. Each step makes the next one smaller.

1. **Tokens** (`globals.css`) — retheming the token layer instantly fixes every
   component already consuming `bg-background`, `text-foreground`,
   `border-border`, `text-primary`. In a shadcn project this is often 60% of the
   visual change for one file edited.
2. **Root layout** — layers 1, 2, 5 from `templates/app-shell.tsx`.
3. **Sidebar and header** — layers 3 and 4. High visibility, low risk.
4. **Cards** — the most repeated surface.
5. **Controls** — buttons, inputs, badges, tables.
6. **Long tail** — one-off screens, driven by the audit script.

Do not start at step 6. Converting leaf components before the token layer means
redoing them.

---

## Finding the work

```bash
# hand-rolled glass surfaces
rg -n 'backdrop-blur' -t tsx --glob '!**/shell-identity.ts'

# hardcoded brand purple
rg -n '#5D0EC1|#5d0ec1|#9200cf|#6a00cf|#b44dff|147,\s*51,\s*234' -t tsx -t ts

# theme branching in JS
rg -n 'theme\s*===\s*["'"'"']dark|resolvedTheme\s*===' -t tsx -t ts

# light-only class strings (no dark: sibling on the line)
rg -n 'className=.*(bg-white|bg-black|text-black|text-gray-900|border-gray-200)' -t tsx \
  | rg -v 'dark:' | rg -v 'shell-identity'

# card-ish surfaces built by hand
rg -n 'rounded-(2xl|3xl).*border' -t tsx --glob '!**/ui/**'
```

Triage each hit into: replace with an existing constant / add a new constant /
leave alone (it is layout, not identity).

---

## Conversion patterns

**Glass card**

```tsx
// before
<div className="rounded-2xl border border-gray-200 bg-white p-6 shadow">

// after
<div className={cn(AXO_GLASS_CARD, "p-6")}>
  <div className={AXO_CARD_OVERLAY} aria-hidden />
  <div className="relative z-10">…</div>
</div>
```

**Theme branching**

```tsx
// before
const { theme } = useTheme();
<div className={theme === "dark" ? "bg-black/40 text-white" : "bg-white/60 text-gray-900"}>

// after — no hook, no branch
<div className={cn(AXO_GLASS_CARD, AXO_TEXT_PRIMARY)}>
```

Delete the now-unused `useTheme` import. If it was the only reason the file was
`"use client"`, the file may be able to go back to a server component — check
for other client-only usage before removing the directive.

**Button**

```tsx
// before
<button className="rounded-lg bg-purple-600 px-4 py-2 text-white hover:bg-purple-700">

// after
<button className={cn(AXO_BUTTON_PRIMARY, "px-4 py-2")}>
```

Padding and sizing stay in the component; colour, radius, and border come from
the constant.

**Text**

```tsx
// before
<h2 className="text-xl font-semibold text-gray-900 dark:text-white">
// after
<h2 className={cn(AXO_TEXT_PRIMARY, "text-xl font-semibold")}>
```

---

## What to leave alone

- **`components/ui/*` (shadcn).** These consume tokens already. Retheming
  `globals.css` retunes them. Only patch one when it hardcodes a colour outside
  the token system — and then patch the colour, not the structure.
- **Layout classes.** `flex`, `grid`, `gap-*`, `p-*`, `w-*`, `max-w-*` belong in
  components. Do not pull them into constants.
- **Behaviour.** Event handlers, data fetching, state, routing, form validation.
  This is a visual migration.
- **Legacy prefixed tokens** (`--orbita-*`, `--cosmos-*`). Keep them and point
  them at the new brand values. Deleting them breaks every component still
  reading them. Orbita's `globals.css` shows the bridge pattern.

---

## Known drift to fix on sight

Found across the existing Axo repos — correct these wherever they appear:

| Drift | Correct |
|---|---|
| `--primary: oklch(0.985 0 0)` under `.dark` (shadcn default leak — turns the brand white in dark mode) | `oklch(0.58 0.24 292)` |
| `--destructive-foreground` set to the destructive colour itself | a readable foreground (`oklch(1 0 0)`) |
| Cards at `rounded-2xl` in some repos, `rounded-3xl` in others | `rounded-3xl` |
| Inputs at `rounded-lg` in some repos, `rounded-xl` in others | `rounded-xl` |
| `AXO_HEADER_BAR` missing `relative z-10` (header falls under the overlay) | include it |
| `AXO_BUTTON_PRIMARY` at `purple-500` with a neon glow | `purple-600` with border, per the template |
| Sidebar links styled for dark only (`text-white/50`) | both themes, per the template |

If the target repo has its own `shell-identity.ts` that predates this skill,
diff it against `templates/shell-identity.ts`, report the differences, then
replace it. Move anything genuinely project-specific into a separate file that
re-exports from `shell-identity`.

---

## Reporting

When the migration is partial — which is normal for a large app — say exactly:

- which screens/components were converted
- which were not, and why
- what the audit script still reports, and whether each hit is a real violation

Do not describe a partial migration as complete.
