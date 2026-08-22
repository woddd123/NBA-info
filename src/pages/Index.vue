<template>
  <div class="min-h-screen">
    <PageHeader
      eyebrow="NBA · Scoreboard"
      title="赛程战报"
      :refreshing="loading"
      :on-refresh="() => fetchGames(true)"
    />

    <!-- 日期条：横向滑动选日，比「前一天 / 后一天」两个按钮快得多 -->
    <div class="relative">
      <div ref="stripRef" class="flex gap-2 overflow-x-auto no-scrollbar px-5 py-3 snap-x">
        <button
          v-for="d in strip"
          :key="d"
          :ref="el => { if (el && d === currentDate) activeChip = el }"
          class="day-chip pressable snap-center"
          :class="{ 'day-chip-on': d === currentDate }"
          @click="selectDate(d)"
        >
          <span class="text-[10px] tracking-wider opacity-70">{{ weekdayLabel(d) }}</span>
          <span class="u-display u-num text-[20px] leading-none mt-0.5">{{ dayOfMonth(d) }}</span>
          <span v-if="d === todayStr" class="day-dot" />
        </button>
      </div>
    </div>

    <main class="px-5 pt-2">
      <!-- 赛程 -->
      <section class="mb-9">
        <div class="flex items-baseline justify-between mb-3">
          <h2 class="u-eyebrow">{{ currentDate === todayStr ? '今日比赛' : currentDate }}</h2>
          <span v-if="!loading && !error" class="text-[11px] text-ink-3 u-num">
            {{ games.length }} 场
          </span>
        </div>

        <div v-if="loading" class="space-y-3">
          <div v-for="n in 3" :key="n" class="skeleton h-[150px] rounded-md" />
        </div>

        <EmptyState
          v-else-if="error"
          title="赛程加载失败"
          hint="可能是网络问题或数据源暂时不可用，稍后再试一次。"
        >
          <template #action>
            <button class="mt-4 px-4 py-2 rounded-full bg-accent text-white text-sm font-medium pressable"
                    @click="fetchGames(true)">
              重新加载
            </button>
          </template>
        </EmptyState>

        <EmptyState
          v-else-if="games.length === 0"
          title="这天没有比赛"
          hint="换个日期看看，或者回到今天。"
        />

        <div v-else class="space-y-3">
          <GameCard
            v-for="(game, i) in games"
            :key="game.id"
            :game="game"
            class="rise"
            :style="{ '--i': i }"
          />
        </div>
      </section>

      <!-- 观赛入口 -->
      <section>
        <div class="flex items-baseline justify-between mb-3">
          <h2 class="u-eyebrow">观赛入口</h2>
          <router-link to="/links" class="text-[13px] text-accent-cool">管理</router-link>
        </div>

        <EmptyState
          v-if="links.length === 0"
          title="还没有观赛链接"
          hint="点右上角「管理」添加你自己常用的入口。"
        />

        <div v-else class="grid grid-cols-2 gap-3">
          <a
            v-for="(link, i) in links"
            :key="link.url + i"
            :href="link.url"
            target="_blank"
            rel="noopener noreferrer"
            class="link-tile card pressable rise"
            :style="{ '--i': i }"
          >
            <span class="u-display u-num text-[11px] text-ink-3">{{ String(i + 1).padStart(2, '0') }}</span>
            <span class="mt-2 text-[15px] font-semibold text-ink truncate w-full">{{ link.name }}</span>
            <span class="mt-0.5 text-[11px] text-ink-3 truncate w-full">{{ hostOf(link.url) }}</span>
          </a>
        </div>
      </section>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted, onActivated, nextTick } from 'vue'
import { getGamesByDate } from '../api/nba'
import { getToday, dateStrip, weekdayLabel, dayOfMonth } from '../utils/date'
import { getStorage } from '../utils/storage'
import { DEFAULT_LINKS, LINKS_STORAGE_KEY } from '../config/links'
import PageHeader from '../components/ui/PageHeader.vue'
import EmptyState from '../components/ui/EmptyState.vue'
import GameCard from '../components/GameCard.vue'

defineOptions({ name: 'Index' })

const todayStr = getToday()
const currentDate = ref(todayStr)
const strip = ref(dateStrip(todayStr, 3))
const games = ref([])
const loading = ref(true)
const error = ref(false)
const links = ref([])

const stripRef = ref(null)
const activeChip = ref(null)

const hostOf = (url) => {
  try { return new URL(url).host } catch { return url }
}

const selectDate = (d) => {
  if (d === currentDate.value) return
  currentDate.value = d
  // 选到边缘时把窗口往前/后推，日期条变成可以无限翻的
  const idx = strip.value.indexOf(d)
  if (idx <= 0 || idx >= strip.value.length - 1) {
    strip.value = dateStrip(d, 3)
  }
  centerActiveChip()
  fetchGames()
}

const fetchGames = async (forceRefresh = false) => {
  loading.value = true
  error.value = false
  try {
    const data = await getGamesByDate(currentDate.value, forceRefresh)
    games.value = data.data || []
  } catch (e) {
    console.error('Failed to fetch games:', e)
    error.value = true
    games.value = []
  } finally {
    loading.value = false
  }
}

const loadLinks = () => {
  links.value = getStorage(LINKS_STORAGE_KEY, DEFAULT_LINKS)
}

const centerActiveChip = () => {
  nextTick(() => {
    activeChip.value?.scrollIntoView({ block: 'nearest', inline: 'center' })
  })
}

onMounted(() => {
  fetchGames()
  loadLinks()
  centerActiveChip()
})

// 首页被 keep-alive 缓存，从管理页返回时要重新读本地链接
onActivated(loadLinks)
</script>

<style scoped>
.day-chip {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: 54px;
  height: 62px;
  border-radius: 14px;
  background: var(--bg-elev);
  border: 1px solid var(--line);
  color: var(--ink-3);
  transition: background 220ms ease, color 220ms ease, border-color 220ms ease;
}

.day-chip-on {
  background: linear-gradient(180deg, color-mix(in srgb, var(--accent) 88%, black), color-mix(in srgb, var(--accent) 55%, black));
  border-color: transparent;
  color: #fff;
  box-shadow: 0 6px 20px -8px color-mix(in srgb, var(--accent) 80%, transparent);
}

/* 今天始终有个小点，即使不是当前选中项也能一眼定位 */
.day-dot {
  position: absolute;
  bottom: 7px;
  width: 4px;
  height: 4px;
  border-radius: 50%;
  background: currentColor;
  opacity: 0.85;
}

.link-tile {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  padding: 14px;
  min-width: 0;
  text-decoration: none;
}
</style>
