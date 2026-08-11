# Stack setup — per-framework install steps

Read this during **phase 2** of the skill. Substitute `<pm>` with the detected
package manager (`bun add`, `pnpm add`, `npm i`, `yarn add`).

---

## Common dependencies (every React stack)

```bash
<pm> next-themes clsx tailwind-merge lucide-react tw-animate-css
```

- `next-themes` — class-based theme switching
- `clsx` + `tailwind-merge` — the `cn()` helper
- `lucide-react` — icon set used by `theme-toggle.tsx`
- `tw-animate-css` — imported from `globals.css`; required by the v4 template

Skip whichever are already in `package.json`.

---

## Next.js + Tailwind v4 (preferred)

```bash
<pm> tailwindcss @tailwindcss/postcss postcss
```

`postcss.config.mjs`:

```js
export default { plugins: { "@tailwindcss/postcss": {} } };
```

CSS entry (`app/globals.css` or `src/app/globals.css`) — from
`templates/globals.css`. It starts with:

```css
@import "tailwindcss";
@import "tw-animate-css";
@custom-variant dark (&:is(.dark *));
```

There is no `tailwind.config.ts` in v4. Content detection is automatic; the
`@theme inline` block replaces the old `theme.extend`.

`app/layout.tsx`:

```tsx
import "./globals.css";
import { ThemeProvider } from "@/components/theme-provider";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="pt-BR" suppressHydrationWarning>
      <body>
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  );
}
```

---

## Next.js + Tailwind v3 (existing projects only)

Do not introduce v3 into a project that has no Tailwind. Only use this path when
the project is already on `tailwindcss@^3` and migrating to v4 is out of scope.

- CSS entry ← `templates/globals.v3.css`
- Config ← merge `templates/tailwind.config.v3.ts` into the existing
  `tailwind.config.{ts,js}`

Two things must be true or the system silently breaks:

1. `darkMode: "class"` — with the default (`"media"`), every `dark:` class in
   `shell-identity.ts` ignores the toggle and follows the OS.
2. `content` globs cover `lib/**/*.ts`. `shell-identity.ts` is a `.ts` file full
   of class strings; if it is not scanned, JIT purges all of them and the app
   renders unstyled.

```ts
content: [
  "./app/**/*.{ts,tsx,mdx}",
  "./src/**/*.{ts,tsx,mdx}",
  "./components/**/*.{ts,tsx}",
  "./lib/**/*.{ts,tsx}",   // ← easy to forget, breaks everything
],
```

---

## Vite + React

```bash
<pm> tailwindcss @tailwindcss/vite
```

`vite.config.ts`:

```ts
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [react(), tailwindcss()],
});
```

CSS entry is `src/index.css` — same content as `templates/globals.css`.

`next-themes` does not apply outside Next. Replace it with a small provider that
writes `document.documentElement.classList.toggle("dark", …)` and persists to
`localStorage` under the key `axo-theme`, plus an inline script in `index.html`
that applies the stored theme before first paint (otherwise the page flashes
light on load):

```html
<script>
  (function () {
    var t = localStorage.getItem("axo-theme");
    var dark = t === "dark" || (!t && matchMedia("(prefers-color-scheme: dark)").matches);
    document.documentElement.classList.toggle("dark", dark);
  })();
</script>
```

Adapt `theme-toggle.tsx` to call that provider's `setTheme` — the markup and
classes stay identical.

---

## Path aliases

The templates import from `@/lib/shell-identity`, `@/lib/utils`, and
`@/components/theme-toggle`. Confirm `tsconfig.json` maps it:

```json
{ "compilerOptions": { "baseUrl": ".", "paths": { "@/*": ["./*"] } } }
```

For a `src/` layout it is usually `"@/*": ["./src/*"]`. If the project uses a
different alias or none at all, rewrite the imports in the copied files to match
rather than adding a new alias.

---

## Verifying the install

```bash
<pm> run build
```

Then in the browser: toggle the theme and confirm the gradient, the sidebar
purple, and the card glass all change (except the sidebar, which is intentionally
theme-invariant). If nothing changes, the cause is almost always one of:

- `attribute="class"` missing on `ThemeProvider`
- `darkMode: "class"` missing (v3)
- `@custom-variant dark (&:is(.dark *))` missing (v4)
