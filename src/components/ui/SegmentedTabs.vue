<template>
  <div class="seg" role="tablist">
    <!-- 滑块单独一层做位移动画，比给每个按钮切背景色顺滑得多 -->
    <div
      class="seg-thumb"
      :style="{
        width: `calc((100% - 8px) / ${options.length})`,
        transform: `translateX(${activeIndex * 100}%)`,
        '--tint': activeOption?.color || 'var(--accent)'
      }"
    />
    <button
      v-for="(opt, i) in options"
      :key="opt.value"
      role="tab"
      :aria-selected="opt.value === modelValue"
      class="seg-btn u-display"
      :class="opt.value === modelValue ? 'seg-btn-on' : 'seg-btn-off'"
      @click="$emit('update:modelValue', opt.value)"
    >
      {{ opt.label }}
    </button>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  modelValue: { type: [String, Number], required: true },
  /** [{ value, label, color? }] */
  options: { type: Array, required: true }
})
defineEmits(['update:modelValue'])

const activeIndex = computed(() =>
  Math.max(0, props.options.findIndex(o => o.value === props.modelValue))
)
const activeOption = computed(() => props.options[activeIndex.value])
</script>

<style scoped>
.seg {
  position: relative;
  display: flex;
  padding: 4px;
  border-radius: 999px;
  background: var(--bg-elev);
  border: 1px solid var(--line);
}

.seg-thumb {
  position: absolute;
  top: 4px;
  bottom: 4px;
  left: 4px;
  border-radius: 999px;
  background: color-mix(in srgb, var(--tint) 90%, black);
  box-shadow: 0 2px 14px -2px color-mix(in srgb, var(--tint) 60%, transparent);
  transition: transform 320ms cubic-bezier(0.34, 1.4, 0.5, 1), background 240ms ease;
}

.seg-btn {
  position: relative;
  flex: 1;
  padding: 9px 0;
  font-size: 15px;
  letter-spacing: 0.06em;
  background: none;
  border: 0;
  cursor: pointer;
  transition: color 200ms ease;
}

.seg-btn-on { color: #fff; }
.seg-btn-off { color: var(--ink-3); }

@media (prefers-reduced-motion: reduce) {
  .seg-thumb { transition: none; }
}
</style>
