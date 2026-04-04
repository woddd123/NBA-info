<template>
  <div class="p-4 pt-safe min-h-screen pb-20">
    <h1 class="text-2xl font-bold text-nba-red mb-6">设置</h1>

    <!-- API Key 配置 -->
    <div class="bg-card-bg border border-gray-800 rounded-xl mb-6 overflow-hidden">
      <div class="px-4 py-3 border-b border-gray-800 font-bold text-gray-200">BallDontLie API Key</div>
      <div class="p-4">
        <p class="text-xs text-gray-500 mb-3 leading-relaxed">
          BallDontLie API 现已需要提供 API Key (访问 balldontlie.io 免费注册)。未填写时将使用本地模拟数据。
        </p>
        <div class="flex space-x-2">
          <input 
            v-model="apiKey" 
            type="text" 
            placeholder="输入您的 API Key" 
            class="flex-1 bg-gray-900 border border-gray-700 rounded-lg px-3 py-2 text-white text-sm focus:outline-none focus:border-nba-red transition-colors" 
          />
          <button 
            @click="saveApiKey" 
            class="bg-nba-red text-white px-4 py-2 rounded-lg text-sm font-medium active:scale-95 transition-transform"
          >
            保存
          </button>
        </div>
      </div>
    </div>

    <!-- 缓存管理 -->
    <div class="bg-card-bg border border-gray-800 rounded-xl mb-6 overflow-hidden">
      <div class="px-4 py-3 border-b border-gray-800 font-bold text-gray-200">缓存管理</div>
      <div class="p-4 flex justify-between items-center active:bg-gray-800 transition-colors cursor-pointer" @click="clearAllCache">
        <div>
          <div class="text-white mb-1">清理本地缓存</div>
          <div class="text-xs text-gray-500">清除所有 API 请求缓存和本地设置数据</div>
        </div>
        <div class="text-gray-400">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
          </svg>
        </div>
      </div>
    </div>

    <!-- PWA 教程 -->
    <div class="bg-card-bg border border-gray-800 rounded-xl mb-6 overflow-hidden">
      <div class="px-4 py-3 border-b border-gray-800 font-bold text-gray-200">添加到主屏幕教程</div>
      <div class="p-4 space-y-4">
        <div class="flex items-start space-x-3">
          <div class="w-6 h-6 rounded-full bg-nba-blue text-white flex items-center justify-center font-bold shrink-0">1</div>
          <div class="text-sm text-gray-300">使用 Safari 浏览器打开本页面</div>
        </div>
        <div class="flex items-start space-x-3">
          <div class="w-6 h-6 rounded-full bg-nba-blue text-white flex items-center justify-center font-bold shrink-0">2</div>
          <div class="text-sm text-gray-300">点击底部工具栏中间的「分享」按钮</div>
        </div>
        <div class="flex items-start space-x-3">
          <div class="w-6 h-6 rounded-full bg-nba-blue text-white flex items-center justify-center font-bold shrink-0">3</div>
          <div class="text-sm text-gray-300">向下滚动并选择「添加到主屏幕」</div>
        </div>
        <div class="flex items-start space-x-3">
          <div class="w-6 h-6 rounded-full bg-nba-blue text-white flex items-center justify-center font-bold shrink-0">4</div>
          <div class="text-sm text-gray-300">确认添加后，即可在主屏幕全屏无广告使用</div>
        </div>
      </div>
    </div>

    <!-- 关于 -->
    <div class="text-center py-8">
      <div class="w-16 h-16 bg-gray-800 rounded-2xl mx-auto mb-4 flex items-center justify-center border border-gray-700">
        <span class="text-nba-red font-black text-xl">NBA</span>
      </div>
      <h3 class="text-white font-bold mb-1">NBA赛事数据助手</h3>
      <p class="text-gray-500 text-xs mb-4">Version 1.0.0 (PWA)</p>
      
      <div class="text-xs text-gray-600 px-8 leading-relaxed">
        本应用仅作为个人数据展示工具使用。<br/>
        数据来源于公共API，无任何侵权、广告和商业行为。<br/>
        不存储、不分发任何版权内容。
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { clearStorage, getStorage, setStorage } from '../utils/storage'

const apiKey = ref('')

onMounted(() => {
  apiKey.value = getStorage('nba_api_key', '')
})

const saveApiKey = () => {
  setStorage('nba_api_key', apiKey.value.trim())
  alert('API Key 保存成功！')
}

const clearAllCache = () => {
  if (confirm('清理缓存将会重置您的观赛链接等数据，确定要继续吗？')) {
    clearStorage()
    alert('缓存清理完成！')
    window.location.reload()
  }
}
</script>

<style scoped>
.pt-safe {
  padding-top: env(safe-area-inset-top);
}
</style>
