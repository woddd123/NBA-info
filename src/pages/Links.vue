<template>
  <div class="p-4 pt-safe min-h-screen pb-20">
    <div class="flex items-center mb-6">
      <button @click="router.back()" class="mr-4 p-2 bg-gray-800 rounded-full text-white">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
      </button>
      <h1 class="text-xl font-bold text-white">观赛链接管理</h1>
    </div>

    <!-- 添加表单 -->
    <div class="bg-card-bg border border-gray-800 rounded-xl p-4 mb-6">
      <h2 class="text-sm font-bold text-gray-200 mb-4">{{ editingIndex !== -1 ? '编辑链接' : '添加新链接' }}</h2>
      <div class="space-y-3">
        <input v-model="form.name" type="text" placeholder="平台名称 (如: 腾讯体育)" class="w-full bg-gray-900 border border-gray-700 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-nba-red transition-colors" />
        <input v-model="form.url" type="url" placeholder="网址 (包含 http/https)" class="w-full bg-gray-900 border border-gray-700 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-nba-red transition-colors" />
        <div class="flex space-x-2 pt-2">
          <button @click="saveLink" class="flex-1 bg-nba-red text-white py-2 rounded-lg font-medium active:scale-95 transition-transform">
            {{ editingIndex !== -1 ? '保存修改' : '添加' }}
          </button>
          <button v-if="editingIndex !== -1" @click="cancelEdit" class="flex-1 bg-gray-800 text-white py-2 rounded-lg font-medium active:scale-95 transition-transform">
            取消
          </button>
        </div>
      </div>
    </div>

    <!-- 链接列表 -->
    <div v-if="links.length === 0" class="text-center py-12 text-gray-500 bg-card-bg rounded-xl border border-gray-800">
      暂无自定义链接
    </div>
    <div v-else class="space-y-3">
      <div v-for="(link, index) in links" :key="index" class="bg-card-bg border border-gray-800 rounded-xl p-4 flex justify-between items-center">
        <div class="flex-1 min-w-0 pr-4">
          <div class="font-bold text-white mb-1 truncate">{{ link.name }}</div>
          <div class="text-xs text-gray-500 truncate">{{ link.url }}</div>
        </div>
        <div class="flex space-x-2 shrink-0">
          <button @click="editLink(index)" class="p-2 bg-gray-800 text-blue-400 rounded-lg active:scale-95 transition-transform">编辑</button>
          <button @click="deleteLink(index)" class="p-2 bg-gray-800 text-red-400 rounded-lg active:scale-95 transition-transform">删除</button>
        </div>
      </div>
    </div>
    
    <div class="mt-8 text-xs text-gray-500 text-center">
      * 所有链接仅保存在本地浏览器，不会上传至云端
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { getStorage, setStorage } from '../utils/storage'

const router = useRouter()
const links = ref([])
const form = ref({ name: '', url: '' })
const editingIndex = ref(-1)

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

const saveLink = () => {
  if (!form.value.name.trim() || !form.value.url.trim()) return
  
  if (editingIndex.value !== -1) {
    links.value[editingIndex.value] = { ...form.value }
    editingIndex.value = -1
  } else {
    links.value.push({ ...form.value })
  }
  
  setStorage('nba_links', links.value)
  form.value = { name: '', url: '' }
}

const editLink = (index) => {
  editingIndex.value = index
  form.value = { ...links.value[index] }
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const cancelEdit = () => {
  editingIndex.value = -1
  form.value = { name: '', url: '' }
}

const deleteLink = (index) => {
  if (confirm('确定要删除该链接吗？')) {
    links.value.splice(index, 1)
    setStorage('nba_links', links.value)
  }
}

onMounted(() => {
  loadLinks()
})
</script>

<style scoped>
.pt-safe {
  padding-top: env(safe-area-inset-top);
}
</style>
