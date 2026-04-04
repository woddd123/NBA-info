<template>
  <div class="p-4 pt-safe min-h-screen pb-20">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold text-nba-red">球员高阶数据</h1>
    </div>
    
    <div class="bg-gray-900 rounded-xl p-6 text-center border border-gray-800 mb-6">
      <div class="text-4xl mb-4">📊</div>
      <h2 class="text-lg font-bold text-white mb-2">获取官方真实球员数据</h2>
      <p class="text-sm text-gray-400 mb-6 leading-relaxed">
        由于免费第三方接口的限制，我们不再提供模拟的球员榜单。<br>
        您可以直接点击下方按钮，跳转至官方或主流体育平台查看最权威、最实时的球员高阶数据与榜单。
      </p>
      
      <div class="flex flex-col space-y-3">
        <a 
          href="https://sports.qq.com/nba/stats/?type=player" 
          target="_blank"
          class="bg-nba-blue text-white py-3 rounded-lg font-medium flex items-center justify-center active:scale-95 transition-transform"
        >
          <span>🔗 前往 腾讯体育 - 球员榜单</span>
        </a>
        
        <a 
          href="https://www.espn.com/nba/stats" 
          target="_blank"
          class="bg-red-600 text-white py-3 rounded-lg font-medium flex items-center justify-center active:scale-95 transition-transform"
        >
          <span>🔗 前往 ESPN - Player Stats (英文)</span>
        </a>
        
        <a 
          href="https://china.nba.cn/statistics/" 
          target="_blank"
          class="bg-gray-800 text-white py-3 rounded-lg font-medium flex items-center justify-center border border-gray-700 active:scale-95 transition-transform"
        >
          <span>🔗 前往 NBA 中文官网 - 数据中心</span>
        </a>
      </div>
    </div>
    
    <div class="text-xs text-gray-500 text-center px-4">
      * 跳转后将离开本应用，数据由第三方版权平台提供。
    </div>
  </div>
</template>

<script setup>
// 数据展示改为纯静态外链跳转，无需发起 API 请求
</script>

<style scoped>
.pt-safe {
  padding-top: env(safe-area-inset-top);
}
</style>
