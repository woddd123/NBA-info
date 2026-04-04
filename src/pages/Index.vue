<template>
  <div class="p-4 pt-safe min-h-screen pb-20">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold text-nba-red">NBA 赛事</h1>
      <button @click="fetchGames(true)" class="text-sm text-gray-400 bg-gray-800 px-3 py-1 rounded-full">
        刷新
      </button>
    </div>

    <!-- 赛程列表 -->
    <div class="mb-8">
      <div class="flex justify-between items-center mb-4">
        <button @click="changeDate(-1)" class="text-sm text-gray-400 p-2">&lt; 前一天</button>
        <h2 class="text-lg font-semibold text-gray-200">{{ displayDateText }}</h2>
        <button @click="changeDate(1)" class="text-sm text-gray-400 p-2">后一天 &gt;</button>
      </div>
      
      <div v-if="loading" class="text-center py-8 text-gray-500">加载中...</div>
      <div v-else-if="games.length === 0" class="text-center py-8 text-gray-500">该日无比赛安排</div>
      <div v-else class="flex overflow-x-auto no-scrollbar space-x-4 pb-4">
        <div v-for="game in games" :key="game.id" class="flex-shrink-0 w-64 bg-card-bg rounded-xl p-4 border border-gray-800">
          <div class="flex justify-between items-center mb-4">
            <span class="text-xs font-bold" :class="game.status.includes('Final') ? 'text-gray-500' : 'text-nba-red'">
              {{ game.status }}
            </span>
            <span class="text-xs text-gray-400">
              {{ game.time || '未开始' }}
            </span>
          </div>
          
          <div class="flex justify-between items-center mb-2">
            <div class="flex items-center space-x-2">
              <span class="font-bold">{{ game.visitor_team.name }}</span>
            </div>
            <span class="text-xl font-bold" :class="parseInt(game.visitor_team_score) > parseInt(game.home_team_score) ? 'text-white' : 'text-gray-400'">
              {{ game.visitor_team_score }}
            </span>
          </div>
          
          <div class="flex justify-between items-center">
            <div class="flex items-center space-x-2">
              <span class="font-bold">{{ game.home_team.name }}</span>
            </div>
            <span class="text-xl font-bold" :class="parseInt(game.home_team_score) > parseInt(game.visitor_team_score) ? 'text-white' : 'text-gray-400'">
              {{ game.home_team_score }}
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- 快捷观赛入口 -->
    <div>
      <div class="flex justify-between items-center mb-4">
        <h2 class="text-lg font-semibold text-gray-200">快捷观赛入口</h2>
        <router-link to="/links" class="text-sm text-nba-blue">管理</router-link>
      </div>
      <div v-if="links.length === 0" class="text-center py-8 bg-card-bg rounded-xl border border-gray-800 text-gray-500 text-sm">
        暂无观赛链接，请点击管理添加
      </div>
      <div v-else class="grid grid-cols-2 gap-4">
        <a v-for="(link, index) in links" :key="index" :href="link.url" target="_blank" class="bg-card-bg rounded-xl p-4 border border-gray-800 flex flex-col items-center justify-center active:scale-95 transition-transform">
          <span class="font-medium text-white mb-1">{{ link.name }}</span>
          <span class="text-xs text-gray-500 truncate w-full text-center">{{ link.url }}</span>
        </a>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onActivated, computed } from 'vue'
import { getGamesByDate } from '../api/nba'
import { getToday, getOffsetDate } from '../utils/date'
import { getStorage } from '../utils/storage'

const todayStr = getToday()
const currentDate = ref(todayStr)
const games = ref([])
const loading = ref(true)
const links = ref([])

const displayDateText = computed(() => {
  if (currentDate.value === todayStr) return `今日赛程 (${currentDate.value})`
  return `赛程 (${currentDate.value})`
})

const changeDate = (offset) => {
  currentDate.value = getOffsetDate(currentDate.value, offset)
  fetchGames()
}

const fetchGames = async (forceRefresh = false) => {
  loading.value = true
  try {
    const data = await getGamesByDate(currentDate.value, forceRefresh)
    games.value = data.data || []
  } catch (error) {
    console.error('Failed to fetch games:', error)
  } finally {
    loading.value = false
  }
}

const loadLinks = () => {
  // 推荐内置（安全、稳定、官方）
  const officialLinks = [ 
    { 
      name: "腾讯体育 - 免费场", 
      url: "https://sports.qq.com/nba/" 
    }, 
    { 
      name: "CCTV5 体育频道", 
      url: "https://tv.cctv.com/live/cctv5" 
    }, 
    { 
      name: "咪咕视频 NBA", 
      url: "https://www.miguvideo.com/wap/resource/pc/pages/nba/index.html" 
    }, 
    { 
      name: "NBA官网", 
      url: "https://www.nba.com/watch/" 
    } 
  ]
  
  links.value = getStorage('nba_links', officialLinks)
}

onMounted(() => {
  fetchGames()
  loadLinks()
})

// 因为首页使用了 keep-alive 缓存，每次从管理页返回时，需要重新读取本地链接
onActivated(() => {
  loadLinks()
})
</script>

<style scoped>
.pt-safe {
  padding-top: env(safe-area-inset-top);
}
</style>

<style scoped>
.pt-safe {
  padding-top: env(safe-area-inset-top);
}
</style>
