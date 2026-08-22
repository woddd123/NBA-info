<template>
  <article class="sc card" :class="{ 'sc-final': isFinals }">
    <!-- 胜方品牌色沿卡片左缘打一道光，一眼看出这轮谁过了 -->
    <span v-if="winnerAbbr" class="sc-rail" :style="{ background: teamColor(winnerAbbr) }" />

    <div class="px-4 py-3.5">
      <div class="flex items-center justify-between mb-3">
        <span class="u-eyebrow" :style="isFinals ? { color: 'var(--gold)' } : null">{{ label }}</span>
        <span class="text-[10px] font-medium tracking-wide" :class="statusClass">{{ statusText }}</span>
      </div>

      <SeriesTeam :team="match.team1" :seed="seedOf(match.team1)" :wins="match.wins1"
                  :state="stateOf(match.team1)" />

      <div class="sc-mid">
        <span class="hairline flex-1" />
        <span class="u-display u-num text-[13px] tracking-[0.2em] text-ink-2">
          {{ hasScore ? `${match.wins1 ?? 0} - ${match.wins2 ?? 0}` : 'VS' }}
        </span>
        <span class="hairline flex-1" />
      </div>

      <SeriesTeam :team="match.team2" :seed="seedOf(match.team2)" :wins="match.wins2"
                  :state="stateOf(match.team2)" />

      <!-- 单场比分 -->
      <div v-if="match.games?.length" class="mt-3 pt-3 border-t border-line flex flex-wrap gap-1.5">
        <span v-for="(g, i) in match.games" :key="i" class="game-chip">
          <span class="text-ink-3">G{{ i + 1 }}</span>
          <span class="u-num text-ink">{{ g.awayScore }}-{{ g.homeScore }}</span>
          <span class="text-ink-3">@{{ normalizeAbbr(g.homeAbbr) }}</span>
        </span>
      </div>

      <p v-if="match.seriesSummary" class="mt-2.5 text-[11px] text-ink-3">{{ match.seriesSummary }}</p>
    </div>
  </article>
</template>

<script setup>
import { computed, h } from 'vue'
import TeamLogo from './ui/TeamLogo.vue'
import { teamColor, normalizeAbbr } from '../config/teams'

const props = defineProps({
  match: { type: Object, required: true },
  label: { type: String, default: '' },
  /** 该分区 1–8 号种子的缩写数组，用于标注种子号 */
  seeds: { type: Array, default: () => [] },
  isFinals: { type: Boolean, default: false }
})

const hasScore = computed(() =>
  props.match.wins1 !== undefined || props.match.wins2 !== undefined)

const decided = computed(() => props.match.wins1 >= 4 || props.match.wins2 >= 4)

const winnerAbbr = computed(() => {
  if (props.match.wins1 >= 4) return props.match.team1?.abbreviation
  if (props.match.wins2 >= 4) return props.match.team2?.abbreviation
  return null
})

const inProgress = computed(() =>
  !decided.value && ((props.match.wins1 || 0) + (props.match.wins2 || 0)) > 0)

const statusText = computed(() => {
  if (decided.value) return '已结束'
  if (inProgress.value) return '进行中'
  return '未开赛'
})

const statusClass = computed(() => {
  if (decided.value) return 'text-ink-3'
  if (inProgress.value) return 'text-live'
  return 'text-ink-3'
})

const seedOf = (team) => {
  const i = props.seeds.indexOf(normalizeAbbr(team?.abbreviation))
  return i >= 0 ? i + 1 : null
}

// 'win' | 'lose' | null —— 没分出胜负时两边都是 null，不做任何强调
const stateOf = (team) => {
  if (!decided.value || !team) return null
  return normalizeAbbr(team.abbreviation) === normalizeAbbr(winnerAbbr.value) ? 'win' : 'lose'
}

const SeriesTeam = (p) => h('div', {
  class: ['flex items-center gap-3 py-1', p.state === 'lose' ? 'opacity-45' : '']
}, [
  h('span', {
    class: 'u-display u-num w-5 text-center text-[13px] text-ink-3 shrink-0'
  }, p.seed ?? ''),
  h(TeamLogo, { abbr: p.team?.abbreviation, name: p.team?.name, size: 30 }),
  h('span', {
    class: ['flex-1 min-w-0 truncate text-[15px]',
            p.state === 'win' ? 'font-bold text-ink' : 'font-medium text-ink-2']
  }, p.team?.name || '待定'),
  h('span', {
    class: ['u-display u-num text-[22px] leading-none',
            p.state === 'win' ? 'text-ink' : 'text-ink-3']
  }, p.wins ?? '–')
])
</script>

<style scoped>
.sc {
  position: relative;
  overflow: hidden;
}

.sc-rail {
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 3px;
}

.sc-final {
  border-color: color-mix(in srgb, var(--gold) 40%, transparent);
  background: linear-gradient(180deg, color-mix(in srgb, var(--gold) 9%, var(--bg-elev)) 0%, var(--bg-elev) 60%);
}

.sc-mid {
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 6px 0;
}

.game-chip {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 3px 7px;
  border-radius: 6px;
  background: var(--bg-elev-2);
  border: 1px solid var(--line);
  font-size: 10px;
  white-space: nowrap;
}
</style>
