<template>
  <div class="p-4 pt-safe min-h-screen pb-20">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold text-nba-red">球队排名</h1>
      <button @click="fetchTeams(true)" class="text-sm text-gray-400 bg-gray-800 px-3 py-1 rounded-full">
        刷新
      </button>
    </div>

    <div class="flex bg-gray-800 rounded-full p-1 mb-6">
      <button @click="conference = 'East'" class="flex-1 py-2 text-sm font-medium rounded-full transition-colors" :class="conference === 'East' ? 'bg-nba-red text-white' : 'text-gray-400'">东部</button>
      <button @click="conference = 'West'" class="flex-1 py-2 text-sm font-medium rounded-full transition-colors" :class="conference === 'West' ? 'bg-nba-blue text-white' : 'text-gray-400'">西部</button>
    </div>

    <!-- 柱状图 -->
    <div class="bg-card-bg border border-gray-800 rounded-xl p-4 mb-6">
      <h2 class="text-sm font-bold text-gray-200 mb-2">胜率图表</h2>
      <div ref="chartRef" class="w-full h-48"></div>
    </div>

    <!-- 排名表格 -->
    <div class="bg-card-bg border border-gray-800 rounded-xl overflow-hidden">
      <table class="w-full text-sm text-left">
        <thead class="text-xs text-gray-400 bg-gray-800">
          <tr>
            <th class="px-4 py-3">排名</th>
            <th class="px-4 py-3">球队</th>
            <th class="px-4 py-3 text-right">胜-负</th>
            <th class="px-4 py-3 text-right">胜率</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(team, index) in sortedTeams" :key="team.id" class="border-b border-gray-800 last:border-0" @click="goToTeam(team.id)">
            <td class="px-4 py-3 font-bold" :class="index < 8 ? 'text-white' : 'text-gray-500'">{{ index + 1 }}</td>
            <td class="px-4 py-3 font-medium">
              <div>{{ team.name }}</div>
              <div class="text-xs text-gray-500" v-if="team.streak">{{ team.streak }}</div>
            </td>
            <td class="px-4 py-3 text-right text-gray-400">{{ team.wins }}-{{ team.losses }}</td>
            <td class="px-4 py-3 text-right text-nba-red">{{ (team.winRate * 100).toFixed(1) }}%</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import * as echarts from 'echarts'
import { getTeams } from '../api/nba'

const router = useRouter()
const conference = ref('East')
const chartRef = ref(null)
let chartInstance = null

const teams = ref([])
const loading = ref(true)

// Fetch teams using real ESPN standings data
const fetchTeams = async (forceRefresh = false) => {
  loading.value = true
  try {
    const data = await getTeams(forceRefresh)
    teams.value = data.data || []
    renderChart()
  } catch (error) {
    console.error('Failed to fetch teams:', error)
  } finally {
    loading.value = false
  }
}

const sortedTeams = computed(() => {
  return teams.value
    .filter(t => t.conference === conference.value)
    .sort((a, b) => b.winRate - a.winRate)
})

const renderChart = () => {
  if (!chartRef.value) return
  if (chartInstance) chartInstance.dispose()
  
  chartInstance = echarts.init(chartRef.value)
  
  const currentTeams = sortedTeams.value.slice(0, 8) // Show top 8 in chart
  
  const option = {
    tooltip: { trigger: 'axis' },
    grid: { top: 10, right: 10, bottom: 20, left: 30 },
    xAxis: {
      type: 'category',
      data: currentTeams.map(t => t.name),
      axisLabel: { color: '#999', fontSize: 10 }
    },
    yAxis: {
      type: 'value',
      axisLabel: { color: '#999', fontSize: 10 },
      splitLine: { lineStyle: { color: '#333' } },
      max: 1
    },
    series: [{
      data: currentTeams.map(t => t.winRate),
      type: 'bar',
      itemStyle: {
        color: conference.value === 'East' ? '#E03A3E' : '#17408B',
        borderRadius: [4, 4, 0, 0]
      }
    }]
  }
  
  chartInstance.setOption(option)
}

watch(conference, () => {
  renderChart()
})

const goToTeam = (id) => {
  // router.push(`/team/${id}`) // Not requested in PRD
}

onMounted(() => {
  fetchTeams()
})
</script>

<style scoped>
.pt-safe {
  padding-top: env(safe-area-inset-top);
}
</style>
