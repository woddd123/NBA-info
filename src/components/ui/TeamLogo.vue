<template>
  <span class="tl" :style="{ '--tc': color, '--sz': size + 'px' }">
    <!-- 缩写兜底：ESPN CDN 挂了或被墙时它就是最终形态，不会留白。
         队徽多有透明区域，所以加载成功后必须把它撤掉，不然会从缝里透出来。 -->
    <span v-if="!loaded" class="tl-fallback u-display">{{ short }}</span>
    <img
      v-if="src && !failed"
      :src="src"
      :alt="name"
      class="tl-img"
      loading="lazy"
      decoding="async"
      @load="loaded = true"
      @error="failed = true"
    />
  </span>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { teamColor, teamLogo, normalizeAbbr } from '../../config/teams'

const props = defineProps({
  abbr: { type: String, default: '' },
  name: { type: String, default: '' },
  size: { type: Number, default: 36 }
})

const failed = ref(false)
const loaded = ref(false)
watch(() => props.abbr, () => { failed.value = false; loaded.value = false })

const color = computed(() => teamColor(props.abbr))
const src = computed(() => teamLogo(props.abbr))
const short = computed(() => normalizeAbbr(props.abbr) || '?')
</script>

<style scoped>
.tl {
  position: relative;
  display: inline-grid;
  place-items: center;
  width: var(--sz);
  height: var(--sz);
  flex-shrink: 0;
  border-radius: 50%;
  /* 队徽底下垫一圈品牌色光晕，深色底上不至于飘着 */
  background: radial-gradient(circle at 50% 45%, rgba(255, 255, 255, 0.08), transparent 70%),
              color-mix(in srgb, var(--tc) 18%, transparent);
}

.tl-fallback {
  position: absolute;
  font-size: calc(var(--sz) * 0.34);
  letter-spacing: 0.02em;
  color: var(--tc);
}

.tl-img {
  position: relative;
  width: 82%;
  height: 82%;
  object-fit: contain;
}
</style>
