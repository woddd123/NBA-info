<template>
  <div class="card px-6 py-12 text-center">
    <div class="mx-auto mb-4 w-12 h-12 grid place-items-center rounded-full bg-elev-2 border border-line text-ink-3">
      <slot name="icon">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="1.6" class="w-5 h-5">
          <circle cx="12" cy="12" r="9" />
          <path d="M12 8v4m0 4h.01" stroke-linecap="round" />
        </svg>
      </slot>
    </div>
    <p class="text-[15px] text-ink-2">{{ title }}</p>
    <p v-if="hint" class="mt-1.5 text-[13px] text-ink-3 leading-relaxed">{{ hint }}</p>
    <slot name="action" />
  </div>
</template>

<script setup>
defineProps({
  title: { type: String, required: true },
  hint: { type: String, default: '' }
})
</script>
