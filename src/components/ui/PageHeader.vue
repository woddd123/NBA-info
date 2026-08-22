<template>
  <header class="pt-safe px-5 pb-4">
    <div class="flex items-end justify-between gap-3">
      <div class="min-w-0">
        <div v-if="eyebrow" class="u-eyebrow mb-1">{{ eyebrow }}</div>
        <h1 class="u-display text-[34px] leading-[0.95] tracking-tight text-ink truncate">
          <slot name="title">{{ title }}</slot>
        </h1>
      </div>

      <div class="flex items-center gap-2 shrink-0 pb-1">
        <slot name="actions" />
        <button
          v-if="onRefresh"
          class="pressable grid place-items-center w-9 h-9 rounded-full bg-elev-2 border border-line text-ink-2"
          :aria-label="'刷新'"
          @click="onRefresh"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
            stroke="currentColor" stroke-width="2" stroke-linecap="round"
            class="w-4 h-4" :class="{ 'animate-spin': refreshing }"
          >
            <path d="M21 12a9 9 0 1 1-2.64-6.36" />
            <path d="M21 3v6h-6" />
          </svg>
        </button>
      </div>
    </div>

    <!-- 标题下的一道渐隐分割线，比整条实线更轻 -->
    <div class="mt-4 h-px bg-gradient-to-r from-line-strong via-line to-transparent" />
  </header>
</template>

<script setup>
defineProps({
  title: { type: String, default: '' },
  eyebrow: { type: String, default: '' },
  refreshing: { type: Boolean, default: false },
  onRefresh: { type: Function, default: null }
})
</script>
