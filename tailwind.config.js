/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'nba-red': '#E03A3E',
        'nba-blue': '#17408B',
        'dark-bg': '#121212',
        'card-bg': 'rgba(30, 30, 30, 0.8)',
      }
    },
  },
  plugins: [],
}
