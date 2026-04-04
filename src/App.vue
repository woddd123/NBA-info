<template>
  <div class="min-h-screen bg-dark-bg text-white pb-16">
    <router-view v-slot="{ Component }">
      <keep-alive include="Index,Rank,Players">
        <component :is="Component" />
      </keep-alive>
    </router-view>
    
    <!-- 底部导航栏 -->
    <nav class="fixed bottom-0 left-0 right-0 bg-card-bg backdrop-blur-md border-t border-gray-800 flex justify-around items-center h-16 px-2 z-50 pb-safe">
      <router-link to="/" class="flex flex-col items-center justify-center w-full h-full" :class="{ 'text-nba-red': $route.path === '/' }">
        <span class="text-xs mt-1">首页</span>
      </router-link>
      <router-link to="/rank" class="flex flex-col items-center justify-center w-full h-full" :class="{ 'text-nba-red': $route.path === '/rank' }">
        <span class="text-xs mt-1">排名</span>
      </router-link>
      <router-link to="/players" class="flex flex-col items-center justify-center w-full h-full" :class="{ 'text-nba-red': $route.path.startsWith('/player') }">
        <span class="text-xs mt-1">球员</span>
      </router-link>
      <router-link to="/setting" class="flex flex-col items-center justify-center w-full h-full" :class="{ 'text-nba-red': $route.path === '/setting' }">
        <span class="text-xs mt-1">设置</span>
      </router-link>
    </nav>
  </div>
</template>

<script setup>
</script>

<style>
/* 适配 iOS 底部安全区 */
.pb-safe {
  padding-bottom: env(safe-area-inset-bottom);
}
</style>
