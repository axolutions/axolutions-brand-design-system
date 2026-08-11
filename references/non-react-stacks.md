# Non-React stacks

The design system is defined as CSS tokens plus Tailwind class strings, so it
ports to any stack that runs Tailwind. Only the delivery mechanism changes.

What is portable, unchanged:

- `templates/globals.css` — the OKLCH token layer
- the class strings inside `templates/shell-identity.ts`
- the layer model, radius scale, typography, and every rule in `DESIGN.md`

What is React-specific and must be re-expressed: `theme-provider.tsx`,
`theme-toggle.tsx`, `app-shell.tsx`, `card-example.tsx`, and the `CSSProperties`
type import in `shell-identity.ts`.

---

## Nuxt / Vue

Live example: `axolutions/` (Nuxt 4 + Nuxt UI + Tailwind v4).

1. Token layer goes in `app/assets/css/main.css`. Keep the existing
   `@import "tailwindcss"` and any `@source` directives, then add the `:root`
   and `.dark` blocks and the `@theme inline` mapping from
   `templates/globals.css`.
2. `shell-identity.ts` becomes `app/utils/shell-identity.ts` — identical
   constants, minus the `CSSProperties` import:

   ```ts
   export const AXO_SIDEBAR_STYLE = {
     backgroundColor: "color-mix(in srgb, oklch(0.45 0.25 290) 85%, black)",
   }
   ```

   Nuxt auto-imports from `app/utils/`, so components use the constants without
   an import statement.
3. Theme switching: `@nuxtjs/color-mode` with `classSuffix: ''` — the default
   suffix is `-mode`, which produces `.dark-mode` and matches none of the
   `dark:` variants.

   ```ts
   // nuxt.config.ts
   modules: ['@nuxtjs/color-mode'],
   colorMode: { classSuffix: '', storageKey: 'axo-theme' },
   ```
4. If the project uses Nuxt UI, set the brand in `app.config.ts`:

   ```ts
   export default defineAppConfig({
     ui: { colors: { primary: 'purple', neutral: 'neutral' } },
   })
   ```

   Nuxt UI components read the same CSS variables, so the token layer retunes
   them the same way it retunes shadcn.
5. `cn()` → `import { twMerge } from 'tailwind-merge'` plus `clsx`, same
   implementation.

---

## Plain HTML / Astro / server-rendered templates

1. Include `templates/globals.css` through the Tailwind build.
2. Export the constants as plain CSS classes instead of TS strings:

   ```css
   @layer components {
     .axo-glass-card {
       @apply relative overflow-hidden rounded-3xl border backdrop-blur-xl
              bg-white/60 border-purple-200/30
              shadow-[0_4px_24px_-4px_rgba(147,51,234,0.08)]
              dark:bg-black/40 dark:border-white/20
              dark:shadow-[0_4px_24px_-4px_rgba(0,0,0,0.4)];
     }
   }
   ```

   Keep the names 1:1 with the constants (`AXO_GLASS_CARD` → `.axo-glass-card`)
   so `DESIGN.md` still reads correctly.
3. Theme switching is a small inline script that toggles `.dark` on
   `<html>` and persists to `localStorage["axo-theme"]`. Run it **before first
   paint**, in `<head>`, or the page flashes light on every load:

   ```html
   <script>
     (function () {
       var t = localStorage.getItem("axo-theme");
       var dark = t === "dark" || (!t && matchMedia("(prefers-color-scheme: dark)").matches);
       document.documentElement.classList.toggle("dark", dark);
     })();
   </script>
   ```

---

## Legacy dark-only sites

`axo-site/` predates this system: pure black background, `#9200cf` purple, HSL
tokens, Tailwind v3, no light mode. It is a different generation of the brand.

Do not half-convert it. Either migrate it fully — tokens, light mode, shell
layers, the lot — as its own scoped task, or leave it alone. A partial
conversion produces a site that is neither, and the neon utility classes
(`.neon-text`, `.gradient-purple`, `.shine-effect`) have no equivalent in the
glass system, so they need explicit decisions rather than a mechanical rewrite.

Confirm with the user which they want before starting.
