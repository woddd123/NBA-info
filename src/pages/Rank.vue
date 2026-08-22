<template>
  <div class="min-h-screen">
    <PageHeader
      eyebrow="NBA · Standings"
      title="球队排名"
      :refreshing="loading"
      :on-refresh="handleRefresh"
    />

    <div class="px-5">
      <SegmentedTabs v-model="tab" :options="tabOptions" />
    </div>

    <!-- ===================== 常规赛排名 ===================== -->
    <main v-if="tab !== 'Playoffs'" class="px-5 pt-5">
      <div v-if="loading" class="space-y-3">
        <div class="skeleton h-[190px] rounded-md" />
        <div v-for="n in 8" :key="n" class="skeleton h-[58px] rounded-sm" />
      </div>

      <EmptyState v-else-if="!sortedTeams.length" title="暂无排名数据"
                  hint="数据源可能暂时不可用，点右上角刷新重试。" />

      <template v-else>
        <!-- 胜率图表 -->
        <div class="card p-4 mb-5">
          <div class="flex items-baseline justify-between mb-3">
            <h2 class="u-eyebrow">前八胜率</h2>
            <span class="text-[10px] text-ink-3">按球队配色</span>
          </div>
          <div ref="chartRef" class="w-full h-[188px]" />
        </div>

        <!-- 排名列表 -->
        <h2 class="u-eyebrow mb-2.5">完整排名</h2>
        <div class="card overflow-hidden">
          <template v-for="(team, i) in sortedTeams" :key="team.id">
            <!-- 季后赛 / 附加赛分界线，比单纯给前八加粗更能说明问题 -->
            <div v-if="i === 6 || i === 10" class="cutline">
              <span class="hairline flex-1" />
              <span class="text-[9px] tracking-[0.2em] text-ink-3">
                {{ i === 6 ? '季后赛分界' : '附加赛分界' }}
              </span>
              <span class="hairline flex-1" />
            </div>

            <div class="row rise" :style="{ '--i': Math.min(i, 12) }">
              <span class="u-display u-num w-6 text-[17px]"
                    :class="i < 6 ? 'text-ink' : i < 10 ? 'text-ink-2' : 'text-ink-3'">
                {{ i + 1 }}
              </span>

              <TeamLogo :abbr="team.abbreviation" :name="team.name" :size="32" />

              <div class="min-w-0 flex-1">
                <div class="text-[15px] font-semibold text-ink truncate">{{ team.name }}</div>
                <!-- 胜率条：数字之外再给一个可以横向对比的视觉量 -->
                <div class="mt-1.5 h-[3px] rounded-full bg-elev-2 overflow-hidden">
                  <div
                    class="h-full rounded-full transition-[width] duration-700 ease-out"
                    :style="{ width: pct(team.winRate), background: teamColor(team.abbreviation) }"
                  />
                </div>
              </div>

              <div class="text-right shrink-0 w-[86px]">
                <div class="u-display u-num text-[17px] text-ink leading-none">
                  {{ team.wins }}<span class="text-ink-3">-</span>{{ team.losses }}
                </div>
                <div class="text-[11px] u-num text-ink-3 mt-1">
                  {{ pct(team.winRate) }}
                  <span v-if="team.streak" class="ml-1.5" :class="streakClass(team.streak)">{{ team.streak }}</span>
                </div>
              </div>
            </div>
          </template>
        </div>
      </template>
    </main>

    <!-- ===================== 季后赛 ===================== -->
    <main v-else class="px-5 pt-5">
      <div v-if="playoffsLoading" class="space-y-3">
        <div v-for="n in 4" :key="n" class="skeleton h-[150px] rounded-md" />
      </div>

      <template v-else>
        <div class="flex items-center justify-between mb-5">
          <div>
            <div class="u-display text-[26px] leading-none text-ink">2026 PLAYOFFS</div>
            <div class="text-[11px] text-ink-3 mt-1.5">
              数据更新于 {{ playoffsData.lastUpdated || '--' }}
            </div>
          </div>
        </div>

        <ConferenceBracket
          title="EASTERN"
          color="var(--accent)"
          :first-round="playoffsData.east?.firstRound || []"
          :semi-finals="playoffsData.east?.semiFinals || []"
          :conf-finals="playoffsData.east?.confFinals || []"
          :seeds="eastSeeds"
        />

        <!-- 总决赛：整页唯一的金色元素，视觉上就是终点 -->
        <div class="my-7">
          <div class="flex items-center gap-3 mb-3">
            <span class="hairline flex-1" />
            <span class="u-display text-[13px] tracking-[0.25em] text-gold">NBA FINALS</span>
            <span class="hairline flex-1" />
          </div>

          <SeriesCard
            v-if="playoffsData.finals"
            :match="playoffsData.finals"
            label="总决赛"
            is-finals
          />
          <div v-else class="card sc-pending px-5 py-6 text-center">
            <div class="flex items-center justify-center gap-4">
              <span class="text-[15px] font-semibold text-ink-2">
                {{ eastChampion?.name || '东部冠军' }}
              </span>
              <span class="u-display text-[13px] tracking-[0.2em] text-gold">VS</span>
              <span class="text-[15px] font-semibold text-ink-2">
                {{ westChampion?.name || '西部冠军' }}
              </span>
            </div>
            <p class="mt-2.5 text-[12px] text-ink-3">对阵尚未产生，等分区决赛打完</p>
          </div>
        </div>

        <ConferenceBracket
          title="WESTERN"
          color="var(--accent-cool)"
          :first-round="playoffsData.west?.firstRound || []"
          :semi-finals="playoffsData.west?.semiFinals || []"
          :conf-finals="playoffsData.west?.confFinals || []"
          :seeds="westSeeds"
        />
      </template>
    </main>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import * as echarts from 'echarts/core'
import { BarChart } from 'echarts/charts'
import { GridComponent, TooltipComponent } from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'
import { getTeams, getPlayoffsData } from '../api/nba'
import { teamColor, normalizeAbbr } from '../config/teams'
import PageHeader from '../components/ui/PageHeader.vue'
import SegmentedTabs from '../components/ui/SegmentedTabs.vue'
import EmptyState from '../components/ui/EmptyState.vue'
import TeamLogo from '../components/ui/TeamLogo.vue'
import ConferenceBracket from '../components/ConferenceBracket.vue'
import SeriesCard from '../components/SeriesCard.vue'

defineOptions({ name: 'Rank' })

// 按需注册，整包引入 echarts 会给首屏多背 ~700KB
echarts.use([BarChart, GridComponent, TooltipComponent, CanvasRenderer])

const tab = ref('East')
const tabOptions = [
  { value: 'East', label: '东部', color: 'var(--accent)' },
  { value: 'West', label: '西部', color: 'var(--accent-cool)' },
  { value: 'Playoffs', label: '季后赛', color: 'var(--gold)' }
]

const teams = ref([])
const loading = ref(true)
const playoffsLoading = ref(false)
const playoffsData = ref({ east: null, west: null, finals: null })

const chartRef = ref(null)
let chartInstance = null

const pct = (rate) => `${((rate || 0) * 100).toFixed(1)}%`

const streakClass = (streak) =>
  String(streak).toUpperCase().startsWith('W') ? 'text-emerald-400' : 'text-ink-3'

const sortedTeams = computed(() =>
  teams.value
    .filter(t => t.conference === tab.value)
    .sort((a, b) => b.winRate - a.winRate)
)

const eastSeeds = computed(() =>
  (playoffsData.value.east?.teams || []).map(t => normalizeAbbr(t?.abbreviation)))
const westSeeds = computed(() =>
  (playoffsData.value.west?.teams || []).map(t => normalizeAbbr(t?.abbreviation)))

const championOf = (conf) => {
  const cf = playoffsData.value[conf]?.confFinals?.[0]
  if (!cf) return null
  if (cf.wins1 >= 4) return cf.team1
  if (cf.wins2 >= 4) return cf.team2
  return null
}
const eastChampion = computed(() => championOf('east'))
const westChampion = computed(() => championOf('west'))

/* ------------------------------ data ------------------------------ */

const fetchTeams = async (forceRefresh = false) => {
  loading.value = true
  try {
    const data = await getTeams(forceRefresh)
    teams.value = data.data || []
  } catch (e) {
    console.error('Failed to fetch teams:', e)
  } finally {
    loading.value = false
    await nextTick()
    renderChart()
  }
}

const fetchPlayoffs = async (forceRefresh = false) => {
  playoffsLoading.value = true
  try {
    playoffsData.value = await getPlayoffsData(forceRefresh)
  } catch (e) {
    console.error('Failed to fetch playoffs data:', e)
  } finally {
    playoffsLoading.value = false
  }
}

const handleRefresh = () => {
  if (tab.value === 'Playoffs') fetchPlayoffs(true)
  else fetchTeams(true)
}

/* ------------------------------ chart ------------------------------ */

const renderChart = () => {
  if (!chartRef.value) return
  if (!chartInstance) chartInstance = echarts.init(chartRef.value)

  const top = sortedTeams.value.slice(0, 8)

  chartInstance.setOption({
    tooltip: {
      trigger: 'axis',
      backgroundColor: 'rgba(16,18,24,0.94)',
      borderColor: 'rgba(255,255,255,0.1)',
      textStyle: { color: '#f2f4f7', fontSize: 12 },
      valueFormatter: (v) => `${(v * 100).toFixed(1)}%`,
      // 轴上放缩写，中文队名放 tooltip —— 8 个中文队名并排必然互相压字
      formatter: (params) => {
        const p = params[0]
        return `${top[p.dataIndex]?.name || p.name}<br/>胜率 ${(p.value * 100).toFixed(1)}%`
      }
    },
    grid: { top: 12, right: 6, bottom: 24, left: 34 },
    xAxis: {
      type: 'category',
      data: top.map(t => normalizeAbbr(t.abbreviation)),
      axisLabel: { color: '#6b7280', fontSize: 10, interval: 0, fontFamily: 'var(--font-display)' },
      axisLine: { lineStyle: { color: 'rgba(255,255,255,0.1)' } },
      axisTick: { show: false }
    },
    yAxis: {
      type: 'value',
      max: 1,
      axisLabel: { color: '#6b7280', fontSize: 10, formatter: (v) => `${v * 100}%` },
      splitLine: { lineStyle: { color: 'rgba(255,255,255,0.05)' } }
    },
    series: [{
      type: 'bar',
      data: top.map(t => ({
        value: t.winRate,
        // 每根柱子用自己球队的颜色，图表和列表里的胜率条就是同一套语言
        itemStyle: { color: teamColor(t.abbreviation), borderRadius: [3, 3, 0, 0] }
      })),
      barMaxWidth: 22,
      animationDuration: 700
    }]
  }, true)
}

const handleResize = () => chartInstance?.resize()

watch(tab, async (val) => {
  if (val === 'Playoffs') {
    if (!playoffsData.value.east) fetchPlayoffs()
    return
  }
  if (!teams.value.length) {
    fetchTeams()
    return
  }
  await nextTick()
  renderChart()
})

onMounted(() => {
  if (tab.value === 'Playoffs') fetchPlayoffs()
  else fetchTeams()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  chartInstance?.dispose()
  chartInstance = null
})
</script>

<style scoped>
.row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 14px;
}
.row + .row { border-top: 1px solid var(--line); }

.cutline {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 7px 14px;
  background: rgba(255, 255, 255, 0.015);
}

.sc-pending {
  border-color: color-mix(in srgb, var(--gold) 28%, transparent);
  background: linear-gradient(180deg, color-mix(in srgb, var(--gold) 7%, var(--bg-elev)), var(--bg-elev));
}
</style>
