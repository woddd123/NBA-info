<template>
  <div class="min-h-screen">
    <PageHeader eyebrow="NBA · Player">
      <template #title>球员详情</template>
    </PageHeader>

    <main class="px-5 pt-4">
      <button class="pressable mb-4 inline-flex items-center gap-1.5 text-[13px] text-ink-2"
              @click="router.back()">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2" stroke-linecap="round" class="w-4 h-4">
          <path d="M15 19l-7-7 7-7" />
        </svg>
        返回
      </button>

      <div v-if="loading" class="space-y-3">
        <div class="skeleton h-[130px] rounded-md" />
        <div class="skeleton h-[280px] rounded-md" />
      </div>

      <EmptyState v-else-if="!player" title="没有找到这名球员"
                  hint="球员数据服务暂时不可用，请稍后重试。" />

      <template v-else>
        <!-- 名片 -->
        <div class="card p-5 mb-4 relative overflow-hidden">
          <span class="glow" />
          <div class="relative flex items-start gap-4">
            <div class="initials u-display">{{ initials }}</div>
            <div class="min-w-0">
              <h2 class="text-[22px] font-bold text-ink leading-tight">
                {{ player.first_name }} {{ player.last_name }}
              </h2>
              <p class="text-[13px] text-ink-3 mt-1.5">
                {{ player.team?.full_name || '未知球队' }}
              </p>
              <div class="flex gap-2 mt-3">
                <span v-if="player.position" class="pill">{{ player.position }}</span>
                <span v-if="player.jersey_number" class="pill u-num">#{{ player.jersey_number }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- 场均数据 -->
        <div class="card p-5 mb-4">
          <div class="flex items-baseline justify-between mb-4">
            <h3 class="u-eyebrow">赛季场均</h3>
            <span class="text-[10px] text-ink-3">{{ statsSeason }}</span>
          </div>

          <div v-if="stats" class="grid grid-cols-5 gap-2">
            <div v-for="s in statLine" :key="s.key" class="text-center">
              <div class="u-display u-num text-[24px] text-ink leading-none">{{ s.value }}</div>
              <div class="text-[10px] text-ink-3 mt-1.5">{{ s.label }}</div>
            </div>
          </div>
          <p v-else class="text-[13px] text-ink-3 leading-relaxed">
            这名球员的场均数据暂时取不到。<br>
            过去这里会用球员 ID 现编一组数字填上，那是假的，已经去掉了。
          </p>
        </div>

        <!-- 雷达图：没有真实数据就不画，一张编出来的图比空白更有害 -->
        <div v-if="stats" class="card p-4">
          <h3 class="u-eyebrow mb-3">能力分布</h3>
          <div ref="radarRef" class="w-full h-[260px]" />
        </div>
      </template>
    </main>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import * as echarts from 'echarts/core'
import { RadarChart } from 'echarts/charts'
import { TooltipComponent } from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'
import { getPlayerDetail, getSeasonAverages } from '../api/nba'
import PageHeader from '../components/ui/PageHeader.vue'
import EmptyState from '../components/ui/EmptyState.vue'

echarts.use([RadarChart, TooltipComponent, CanvasRenderer])

const route = useRoute()
const router = useRouter()
const radarRef = ref(null)
let chart = null

const STATS_SEASON = 2023

const loading = ref(true)
const player = ref(null)
const stats = ref(null)
const statsSeason = `${STATS_SEASON}-${String(STATS_SEASON + 1).slice(2)} 赛季`

const INDICATORS = [
  { key: 'pts', label: '得分', max: 35 },
  { key: 'reb', label: '篮板', max: 15 },
  { key: 'ast', label: '助攻', max: 12 },
  { key: 'stl', label: '抢断', max: 3 },
  { key: 'blk', label: '盖帽', max: 3 }
]

const initials = computed(() => {
  const p = player.value
  if (!p) return ''
  return `${p.first_name?.[0] || ''}${p.last_name?.[0] || ''}`.toUpperCase()
})

const statLine = computed(() =>
  INDICATORS.map(i => ({ ...i, value: stats.value?.[i.key]?.toFixed(1) ?? '–' })))

const fetchPlayer = async () => {
  const id = route.params.id
  try {
    const res = await getPlayerDetail(id)
    player.value = res.data ? res.data : res

    // 取不到真实场均就留空。以前这里会用 playerId 取模造一组数字，
    // 用户完全看不出是编的，等于把假数据当真数据展示。
    try {
      const statsRes = await getSeasonAverages(STATS_SEASON, [id])
      stats.value = statsRes.data?.[0] || null
    } catch {
      stats.value = null
    }

    if (stats.value) {
      await nextTick()
      renderRadar()
    }
  } catch (e) {
    console.error('Failed to fetch player detail:', e)
  } finally {
    loading.value = false
  }
}

const renderRadar = () => {
  if (!radarRef.value || !stats.value) return
  chart = echarts.init(radarRef.value)
  chart.setOption({
    radar: {
      indicator: INDICATORS.map(i => ({ name: i.label, max: i.max })),
      radius: '68%',
      axisName: { color: '#a6adbb', fontSize: 11 },
      splitArea: { areaStyle: { color: ['rgba(255,255,255,0.02)', 'rgba(255,255,255,0.04)'] } },
      axisLine: { lineStyle: { color: 'rgba(255,255,255,0.12)' } },
      splitLine: { lineStyle: { color: 'rgba(255,255,255,0.09)' } }
    },
    series: [{
      type: 'radar',
      data: [{
        value: INDICATORS.map(i => stats.value[i.key] ?? 0),
        name: '场均',
        symbolSize: 4,
        lineStyle: { color: '#e8443f', width: 2 },
        itemStyle: { color: '#e8443f' },
        areaStyle: { color: 'rgba(232, 68, 63, 0.28)' }
      }]
    }]
  })
}

const handleResize = () => chart?.resize()

onMounted(() => {
  fetchPlayer()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  chart?.dispose()
  chart = null
})
</script>

<style scoped>
.glow {
  position: absolute;
  top: -60px;
  right: -40px;
  width: 180px;
  height: 180px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(232, 68, 63, 0.28), transparent 68%);
  pointer-events: none;
}

.initials {
  display: grid;
  place-items: center;
  width: 62px;
  height: 62px;
  flex-shrink: 0;
  border-radius: 18px;
  background: var(--bg-elev-2);
  border: 1px solid var(--line);
  color: var(--accent);
  font-size: 24px;
}

.pill {
  padding: 3px 10px;
  border-radius: 999px;
  background: var(--bg-elev-2);
  border: 1px solid var(--line);
  font-size: 11px;
  color: var(--ink-2);
}
</style>
