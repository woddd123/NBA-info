<template>
  <nav class="tabbar pb-safe">
    <router-link
      v-for="tab in tabs"
      :key="tab.to"
      :to="tab.to"
      class="tab"
      :class="{ 'tab-on': isActive(tab) }"
    >
      <span class="tab-glow" aria-hidden="true" />
      <span class="tab-icon" v-html="tab.icon" />
      <span class="tab-label">{{ tab.label }}</span>
    </router-link>
  </nav>
</template>

<script setup>
import { useRoute } from 'vue-router'

const route = useRoute()

// 内联 SVG：4 个图标不值得为此拉一个图标库进来（会让首屏包变大）
const tabs = [
  {
    to: '/', label: '赛程', match: (p) => p === '/',
    icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><rect x="3" y="5" width="18" height="16" rx="3"/><path d="M8 3v4M16 3v4M3 10h18"/></svg>`
  },
  {
    to: '/rank', label: '排名', match: (p) => p === '/rank',
    icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M5 21V11M12 21V4M19 21v-6"/></svg>`
  },
  {
    to: '/players', label: '球员', match: (p) => p.startsWith('/player'),
    icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="8" r="3.5"/><path d="M4.5 20a7.5 7.5 0 0 1 15 0"/></svg>`
  },
  {
    to: '/setting', label: '设置', match: (p) => p === '/setting' || p === '/links',
    icon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M5 21v-6M5 11V3M12 21v-9M12 8V3M19 21v-4M19 13V3"/><path d="M2.5 15h5M9.5 8h5M16.5 17h5"/></svg>`
  }
]

const isActive = (tab) => tab.match(route.path)
</script>

<style scoped>
.tabbar {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 50;
  display: flex;
  align-items: stretch;
  height: calc(60px + var(--safe-bottom));
  /* 毛玻璃 + 顶部一道高光，做出「浮在内容之上」的层次 */
  background: rgba(10, 11, 15, 0.72);
  backdrop-filter: saturate(180%) blur(22px);
  -webkit-backdrop-filter: saturate(180%) blur(22px);
  border-top: 1px solid var(--line);
  box-shadow: 0 -18px 40px -20px rgba(0, 0, 0, 0.9);
}

.tab {
  position: relative;
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
  height: 60px;
  color: var(--ink-3);
  text-decoration: none;
  transition: color 200ms ease;
}

.tab-on { color: var(--accent); }

.tab-icon { display: block; width: 22px; height: 22px; }
.tab-icon :deep(svg) { width: 100%; height: 100%; }

.tab-label {
  font-size: 10px;
  letter-spacing: 0.08em;
}

/* 选中态：图标上方一小片色晕，比给整个 tab 加背景块克制 */
.tab-glow {
  position: absolute;
  top: 0;
  width: 46px;
  height: 26px;
  border-radius: 0 0 999px 999px;
  background: radial-gradient(60% 100% at 50% 0%, color-mix(in srgb, var(--accent) 55%, transparent), transparent 70%);
  opacity: 0;
  transition: opacity 260ms ease;
}

.tab-on .tab-glow { opacity: 1; }

.tab:active .tab-icon { transform: scale(0.9); transition: transform 120ms ease; }
</style>
