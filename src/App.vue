<template>
  <div class="min-h-screen" style="padding-bottom: calc(60px + var(--safe-bottom))">
    <router-view v-slot="{ Component }">
      <keep-alive :include="['Index', 'Rank', 'Players']">
        <component :is="Component" />
      </keep-alive>
    </router-view>

    <TabBar />
  </div>
</template>

<script setup>
import TabBar from './components/TabBar.vue'
</script>
