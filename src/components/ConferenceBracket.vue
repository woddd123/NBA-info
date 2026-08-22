<template>
  <section>
    <!-- 分区标题：一条品牌色横杠 + 名称，替代原来那行居中小字 -->
    <div class="flex items-center gap-3 mb-4">
      <span class="h-[3px] w-8 rounded-full" :style="{ background: color }" />
      <h3 class="u-display text-[17px] tracking-[0.14em]" :style="{ color }">{{ title }}</h3>
      <span class="hairline flex-1" />
    </div>

    <div class="space-y-6">
      <div v-for="round in rounds" :key="round.key">
        <div class="flex items-center gap-2 mb-2.5 pl-0.5">
          <span class="u-eyebrow">{{ round.label }}</span>
          <span class="text-[10px] text-ink-3 u-num">{{ round.matches.length }}</span>
        </div>

        <div class="space-y-2.5">
          <SeriesCard
            v-for="(m, i) in round.matches"
            :key="round.key + '-' + i"
            :match="m"
            :label="matchupLabel(m)"
            :seeds="seeds"
            class="rise"
            :style="{ '--i': i }"
          />
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
import { computed } from 'vue'
import SeriesCard from './SeriesCard.vue'
import { normalizeAbbr } from '../config/teams'

const props = defineProps({
  title: { type: String, required: true },
  color: { type: String, default: 'var(--accent)' },
  firstRound: { type: Array, default: () => [] },
  semiFinals: { type: Array, default: () => [] },
  confFinals: { type: Array, default: () => [] },
  /** 1–8 号种子缩写，顺序即种子顺序 */
  seeds: { type: Array, default: () => [] }
})

// 手机上横向对阵树必然要缩到 7px 字号才塞得下，所以改成按轮次纵向堆叠：
// 信息量一样，但每张卡都是全宽、可读，不用左右拖。
const rounds = computed(() => [
  { key: 'r1', label: '首轮 · FIRST ROUND', matches: props.firstRound },
  { key: 'r2', label: '分区半决赛 · SEMIFINALS', matches: props.semiFinals },
  { key: 'r3', label: '分区决赛 · CONF FINALS', matches: props.confFinals }
].filter(r => r.matches.length))

// 卡片左上角放种子对位（如「1 VS 8」），轮次名已经在上面的分组标题里了，再写一遍是废话
const seedOf = (team) => {
  const i = props.seeds.indexOf(normalizeAbbr(team?.abbreviation))
  return i >= 0 ? i + 1 : null
}

const matchupLabel = (m) => {
  const a = seedOf(m.team1)
  const b = seedOf(m.team2)
  return a && b ? `${a} VS ${b}` : ''
}
</script>
