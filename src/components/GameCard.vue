<template>
  <article
    class="gc card pressable"
    :style="{ '--c-away': awayRgb, '--c-home': homeRgb }"
  >
    <!-- 两侧品牌色从外缘向内渗透，这是整个 App 的视觉签名 -->
    <span class="gc-bleed gc-bleed-l" aria-hidden="true" />
    <span class="gc-bleed gc-bleed-r" aria-hidden="true" />

    <div class="gc-inner">
      <!-- 状态条 -->
      <div class="flex items-center justify-between mb-4">
        <div class="flex items-center gap-1.5">
          <span v-if="isLive" class="dot-live w-1.5 h-1.5 rounded-full bg-live" />
          <span class="u-eyebrow" :style="{ color: statusColor }">{{ statusLabel }}</span>
        </div>
        <span class="text-[11px] u-num text-ink-3">{{ game.time }}</span>
      </div>

      <!-- 客队 / 主队 -->
      <TeamRow :team="game.visitor_team" :score="game.visitor_team_score"
               :won="awayWon" :settled="isFinal" label="客" />
      <div class="my-3 hairline" />
      <TeamRow :team="game.home_team" :score="game.home_team_score"
               :won="homeWon" :settled="isFinal" label="主" />
    </div>
  </article>
</template>

<script setup>
import { computed, h } from 'vue'
import TeamLogo from './ui/TeamLogo.vue'
import { teamRgb } from '../config/teams'

const props = defineProps({
  game: { type: Object, required: true }
})

const isLive = computed(() => props.game.status === '进行中')
const isFinal = computed(() => props.game.status === '已结束')

const statusLabel = computed(() => {
  if (isLive.value) return 'LIVE · 进行中'
  if (isFinal.value) return 'FINAL · 已结束'
  return '未开始'
})

const statusColor = computed(() => {
  if (isLive.value) return 'var(--live)'
  if (isFinal.value) return 'var(--ink-3)'
  return 'var(--ink-2)'
})

const awayRgb = computed(() => teamRgb(props.game.visitor_team?.abbreviation))
const homeRgb = computed(() => teamRgb(props.game.home_team?.abbreviation))

// 只有打完了才谈输赢；进行中的领先方不该被渲染成「赢家」
const num = (v) => Number.parseInt(v, 10) || 0
const awayWon = computed(() =>
  isFinal.value && num(props.game.visitor_team_score) > num(props.game.home_team_score))
const homeWon = computed(() =>
  isFinal.value && num(props.game.home_team_score) > num(props.game.visitor_team_score))

// 一行球队信息。只在这个卡片里用，就地定义避免多开一个文件
const TeamRow = (rowProps) => h('div', { class: 'flex items-center gap-3' }, [
  h(TeamLogo, { abbr: rowProps.team?.abbreviation, name: rowProps.team?.name, size: 38 }),
  h('div', { class: 'min-w-0 flex-1' }, [
    h('div', {
      class: ['text-[15px] font-semibold truncate transition-colors',
              rowProps.settled && !rowProps.won ? 'text-ink-3' : 'text-ink']
    }, rowProps.team?.name || '—'),
    h('div', { class: 'text-[10px] tracking-widest text-ink-3 mt-0.5' }, rowProps.label)
  ]),
  h('div', { class: 'flex items-center gap-2' }, [
    // 胜方左侧一个小三角，比单纯加粗更容易一眼扫到
    rowProps.won
      ? h('span', { class: 'w-0 h-0 border-y-4 border-y-transparent border-l-[6px] border-l-accent' })
      : null,
    h('span', {
      class: ['u-display u-num text-[30px] leading-none tabular-nums',
              rowProps.settled && !rowProps.won ? 'text-ink-3' : 'text-ink']
    }, rowProps.score ?? '–')
  ])
])
</script>

<style scoped>
.gc {
  position: relative;
  overflow: hidden;
  isolation: isolate;
}

.gc-inner {
  position: relative;
  z-index: 1;
  padding: 16px 18px 18px;
}

.gc-bleed {
  position: absolute;
  top: 0;
  bottom: 0;
  width: 58%;
  z-index: 0;
  pointer-events: none;
  opacity: 0.5;
}

.gc-bleed-l {
  left: 0;
  background: radial-gradient(90% 120% at 0% 50%, rgba(var(--c-away), 0.42) 0%, transparent 68%);
}

.gc-bleed-r {
  right: 0;
  background: radial-gradient(90% 120% at 100% 50%, rgba(var(--c-home), 0.42) 0%, transparent 68%);
}
</style>
