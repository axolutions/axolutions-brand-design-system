import type { Config } from "tailwindcss";

/**
 * Axolutions Tailwind v3 config.
 *
 * `darkMode: "class"` is REQUIRED — every Shell Identity constant uses `dark:`
 * against the `.dark` class that next-themes writes on <html>.
 *
 * Merge this into the project's existing config rather than replacing it
 * wholesale, so app-specific `content` globs and plugins survive.
 */
const config: Config = {
  darkMode: "class",
  content: [
    "./app/**/*.{ts,tsx,js,jsx,mdx}",
    "./src/**/*.{ts,tsx,js,jsx,mdx}",
    "./components/**/*.{ts,tsx,js,jsx,mdx}",
    "./lib/**/*.{ts,tsx,js,jsx}",
  ],
  theme: {
    extend: {
      colors: {
        background: "var(--background)",
        foreground: "var(--foreground)",
        card: { DEFAULT: "var(--card)", foreground: "var(--card-foreground)" },
        popover: { DEFAULT: "var(--popover)", foreground: "var(--popover-foreground)" },
        primary: { DEFAULT: "var(--primary)", foreground: "var(--primary-foreground)" },
        secondary: { DEFAULT: "var(--secondary)", foreground: "var(--secondary-foreground)" },
        muted: { DEFAULT: "var(--muted)", foreground: "var(--muted-foreground)" },
        accent: { DEFAULT: "var(--accent)", foreground: "var(--accent-foreground)" },
        destructive: { DEFAULT: "var(--destructive)", foreground: "var(--destructive-foreground)" },
        success: "var(--success)",
        warning: "var(--warning)",
        info: "var(--info)",
        border: "var(--border)",
        input: "var(--input)",
        ring: "var(--ring)",
        axo: {
          purple: "var(--axo-purple)",
          "purple-deep": "var(--axo-purple-deep)",
          "purple-soft": "var(--axo-purple-soft)",
        },
      },
      borderRadius: {
        sm: "calc(var(--radius) - 4px)",
        md: "calc(var(--radius) - 2px)",
        lg: "var(--radius)",
        xl: "calc(var(--radius) + 4px)",
      },
    },
  },
  plugins: [],
};

export default config;
