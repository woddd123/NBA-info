<template>
  <div class="min-h-screen">
    <PageHeader eyebrow="NBA · Player Stats" title="球员数据" />

    <main class="px-5 pt-4">
      <div class="card p-5 mb-5">
        <p class="text-[13px] text-ink-2 leading-relaxed">
          免费公开接口拿不到完整、可靠的球员高阶数据，与其展示一份不准的榜单，
          不如直接把你送到最权威的数据源。
        </p>
      </div>

      <h2 class="u-eyebrow mb-2.5">前往数据中心</h2>
      <div class="space-y-2.5">
        <a
          v-for="(src, i) in sources"
          :key="src.url"
          :href="src.url"
          target="_blank"
          rel="noopener noreferrer"
          class="src card pressable rise"
          :style="{ '--i': i, '--tint': src.tint }"
        >
          <span class="src-rail" />
          <div class="min-w-0 flex-1">
            <div class="text-[15px] font-semibold text-ink">{{ src.name }}</div>
            <div class="text-[11px] text-ink-3 mt-0.5">{{ src.desc }}</div>
          </div>
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
               stroke="currentColor" stroke-width="1.8" stroke-linecap="round"
               class="w-4 h-4 text-ink-3 shrink-0">
            <path d="M7 17 17 7M9 7h8v8" />
          </svg>
        </a>
      </div>

      <p class="mt-5 text-[11px] text-ink-3 text-center leading-relaxed">
        跳转后将离开本应用，数据由第三方平台提供。
      </p>
    </main>
  </div>
</template>

<script setup>
import PageHeader from '../components/ui/PageHeader.vue'

defineOptions({ name: 'Players' })

const sources = [
  {
    name: '腾讯体育 · 球员榜单',
    desc: '中文，得分 / 篮板 / 助攻等常规榜单',
    url: 'https://sports.qq.com/nba/stats/?type=player',
    tint: 'var(--accent-cool)'
  },
  {
    name: 'ESPN · Player Stats',
    desc: '英文，高阶数据最全',
    url: 'https://www.espn.com/nba/stats',
    tint: 'var(--accent)'
  },
  {
    name: 'NBA 中文官网 · 数据中心',
    desc: '官方数据，中文界面',
    url: 'https://china.nba.cn/statistics/',
    tint: 'var(--gold)'
  }
]
</script>

<style scoped>
.src {
  position: relative;
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 15px 16px 15px 20px;
  overflow: hidden;
  text-decoration: none;
}

.src-rail {
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 3px;
  background: var(--tint);
}
</style>
