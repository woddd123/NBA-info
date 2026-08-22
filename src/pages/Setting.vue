<template>
  <div class="min-h-screen">
    <PageHeader eyebrow="App · Settings" title="设置" />

    <main class="px-5 pt-4 space-y-5">
      <!-- 观赛链接入口 -->
      <router-link to="/links" class="card pressable flex items-center gap-3.5 p-4">
        <span class="ico"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
          stroke="currentColor" stroke-width="1.8" stroke-linecap="round" class="w-[18px] h-[18px]">
          <path d="M10 13a5 5 0 0 0 7.5.5l3-3a5 5 0 0 0-7-7l-1.7 1.7" />
          <path d="M14 11a5 5 0 0 0-7.5-.5l-3 3a5 5 0 0 0 7 7l1.7-1.7" />
        </svg></span>
        <div class="flex-1 min-w-0">
          <div class="text-[15px] font-semibold text-ink">观赛链接管理</div>
          <div class="text-[11px] text-ink-3 mt-0.5">添加、编辑你自己的观赛入口</div>
        </div>
        <span class="chev" />
      </router-link>

      <!-- 数据源 -->
      <section class="card overflow-hidden">
        <div class="sec-head">数据服务</div>
        <div class="p-4">
          <p class="text-[12px] text-ink-3 leading-relaxed">
            赛事优先读取实时缓存，历史比赛、排名和球员数据由数据库持久化；缓存失效时由服务端自动向第三方数据源更新，无需在设备上填写 API Key。
          </p>
        </div>
      </section>

      <!-- 缓存 -->
      <section class="card overflow-hidden">
        <div class="sec-head">存储</div>
        <button class="w-full flex items-center gap-3.5 p-4 text-left pressable" @click="clearApiCache">
          <span class="ico"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
            stroke="currentColor" stroke-width="1.8" stroke-linecap="round" class="w-[18px] h-[18px]">
            <path d="M21 12a9 9 0 1 1-2.64-6.36M21 3v6h-6" />
          </svg></span>
          <div class="flex-1 min-w-0">
            <div class="text-[15px] text-ink">清理接口缓存</div>
            <div class="text-[11px] text-ink-3 mt-0.5">只清设备本地缓存，服务端数据不会删除</div>
          </div>
          <span class="chev" />
        </button>

        <div class="hairline" />

        <button class="w-full flex items-center gap-3.5 p-4 text-left pressable" @click="resetEverything">
          <span class="ico ico-danger"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
            fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"
            class="w-[18px] h-[18px]">
            <path d="M3 6h18M8 6V4h8v2M19 6l-1 14H6L5 6M10 11v6M14 11v6" />
          </svg></span>
          <div class="flex-1 min-w-0">
            <div class="text-[15px] text-accent">重置全部数据</div>
            <div class="text-[11px] text-ink-3 mt-0.5">清空观赛链接和设备本地缓存</div>
          </div>
          <span class="chev" />
        </button>
      </section>
      <p v-if="toast" class="text-[12px] text-emerald-400 px-1">{{ toast }}</p>

      <!-- PWA 教程 -->
      <section class="card overflow-hidden">
        <div class="sec-head">添加到主屏幕</div>
        <ol class="p-4 space-y-3.5">
          <li v-for="(step, i) in steps" :key="i" class="flex items-start gap-3">
            <span class="step u-display u-num">{{ i + 1 }}</span>
            <span class="text-[14px] text-ink-2 leading-relaxed pt-0.5">{{ step }}</span>
          </li>
        </ol>
      </section>

      <!-- 关于 -->
      <div class="text-center pt-4 pb-6">
        <div class="mx-auto mb-3.5 w-14 h-14 rounded-lg grid place-items-center
                    bg-elev border border-line u-display text-accent text-[19px]">
          NBA
        </div>
        <div class="text-[15px] font-semibold text-ink">NBA 赛事数据助手</div>
        <div class="text-[11px] u-num text-ink-3 mt-1">v1.0.0 · PWA</div>
        <p class="mt-4 text-[11px] text-ink-3 leading-relaxed px-6">
          个人自用的数据展示工具。数据来自公开 API，不存储、不分发任何版权内容，无广告、无商业行为。
        </p>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { clearStorage } from '../utils/storage'
import { clearCache } from '../utils/cache'
import PageHeader from '../components/ui/PageHeader.vue'

const toast = ref('')

const steps = [
  '用 Safari 打开本页面',
  '点底部工具栏中间的「分享」按钮',
  '向下滚动，选择「添加到主屏幕」',
  '确认后即可从主屏幕全屏打开'
]

const flash = (msg) => {
  toast.value = msg
  setTimeout(() => { toast.value = '' }, 2400)
}

// 分成两档：日常只想刷新数据的人不该被迫连观赛链接一起丢掉
const clearApiCache = () => {
  clearCache()
  flash('接口缓存已清理')
}

const resetEverything = () => {
  if (!confirm('将清空观赛链接和设备本地缓存，确定继续吗？')) return
  clearStorage()
  window.location.reload()
}
</script>

<style scoped>
.sec-head {
  padding: 11px 16px;
  border-bottom: 1px solid var(--line);
  background: rgba(255, 255, 255, 0.015);
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 0.04em;
  color: var(--ink-2);
}

.ico {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  flex-shrink: 0;
  border-radius: 10px;
  background: var(--bg-elev-2);
  border: 1px solid var(--line);
  color: var(--ink-2);
}
.ico-danger { color: var(--accent); }

/* 右侧的 › 用纯 CSS 画，省一个 SVG */
.chev {
  width: 7px;
  height: 7px;
  flex-shrink: 0;
  border-top: 1.6px solid var(--ink-3);
  border-right: 1.6px solid var(--ink-3);
  transform: rotate(45deg);
}

.step {
  display: grid;
  place-items: center;
  width: 24px;
  height: 24px;
  flex-shrink: 0;
  border-radius: 50%;
  background: color-mix(in srgb, var(--accent-cool) 22%, transparent);
  border: 1px solid color-mix(in srgb, var(--accent-cool) 45%, transparent);
  color: #9dc0ff;
  font-size: 13px;
}

.field {
  padding: 11px 13px;
  border-radius: var(--r-sm);
  background: var(--bg);
  border: 1px solid var(--line);
  color: var(--ink);
  font-size: 15px;
  outline: none;
  transition: border-color 180ms ease, box-shadow 180ms ease;
  min-width: 0;
}
.field::placeholder { color: var(--ink-3); }
.field:focus {
  border-color: color-mix(in srgb, var(--accent) 65%, transparent);
  box-shadow: 0 0 0 3px color-mix(in srgb, var(--accent) 14%, transparent);
}
</style>
