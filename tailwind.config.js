/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      // 全部指回 style.css 里的 CSS 变量，避免同一个颜色在两处各写一遍
      colors: {
        bg: 'var(--bg)',
        elev: 'var(--bg-elev)',
        'elev-2': 'var(--bg-elev-2)',
        line: 'var(--line)',
        'line-strong': 'var(--line-strong)',
        ink: 'var(--ink)',
        'ink-2': 'var(--ink-2)',
        'ink-3': 'var(--ink-3)',
        accent: 'var(--accent)',
        'accent-cool': 'var(--accent-cool)',
        gold: 'var(--gold)',
        live: 'var(--live)',
      },
      borderColor: {
        DEFAULT: 'var(--line)',
      },
      borderRadius: {
        sm: 'var(--r-sm)',
        md: 'var(--r-md)',
        lg: 'var(--r-lg)',
      },
      fontFamily: {
        body: 'var(--font-body)',
        display: 'var(--font-display)',
      },
    },
  },
  plugins: [],
}
