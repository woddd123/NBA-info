<template>
  <div class="min-h-screen">
    <PageHeader eyebrow="Watch · Links" title="观赛入口" />

    <main class="px-5 pt-4">
      <button class="pressable mb-4 inline-flex items-center gap-1.5 text-[13px] text-ink-2"
              @click="router.back()">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2" stroke-linecap="round" class="w-4 h-4">
          <path d="M15 19l-7-7 7-7" />
        </svg>
        返回
      </button>

      <!-- 编辑表单 -->
      <div class="card p-4 mb-6">
        <h2 class="u-eyebrow mb-3.5">{{ isEditing ? '编辑链接' : '添加链接' }}</h2>

        <div class="space-y-2.5">
          <input v-model="form.name" type="text" class="field" placeholder="平台名称，如「腾讯体育」" />
          <input v-model="form.url" type="url" inputmode="url" class="field"
                 placeholder="网址，需带 https://" />
        </div>

        <p v-if="err" class="mt-2.5 text-[12px] text-accent">{{ err }}</p>

        <div class="flex gap-2.5 mt-4">
          <button class="btn btn-primary pressable" @click="saveLink">
            {{ isEditing ? '保存修改' : '添加' }}
          </button>
          <button v-if="isEditing" class="btn btn-ghost pressable" @click="cancelEdit">取消</button>
        </div>
      </div>

      <!-- 列表 -->
      <div class="flex items-baseline justify-between mb-2.5">
        <h2 class="u-eyebrow">已保存</h2>
        <span class="text-[10px] text-ink-3 u-num">{{ links.length }}</span>
      </div>

      <EmptyState v-if="links.length === 0" title="还没有任何链接"
                  hint="在上面填好名称和网址就能添加。" />

      <div v-else class="space-y-2.5">
        <div v-for="(link, i) in links" :key="link.url + i"
             class="card flex items-center gap-3 p-3.5 rise" :style="{ '--i': i }">
          <span class="u-display u-num w-6 text-center text-[13px] text-ink-3 shrink-0">
            {{ String(i + 1).padStart(2, '0') }}
          </span>
          <div class="min-w-0 flex-1">
            <div class="text-[15px] font-semibold text-ink truncate">{{ link.name }}</div>
            <div class="text-[11px] text-ink-3 truncate mt-0.5">{{ link.url }}</div>
          </div>
          <div class="flex gap-1.5 shrink-0">
            <button class="icon-btn pressable" aria-label="编辑" @click="editLink(i)">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                   stroke="currentColor" stroke-width="1.8" stroke-linecap="round" class="w-4 h-4">
                <path d="M12 20h9M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4Z" />
              </svg>
            </button>
            <button class="icon-btn icon-btn-danger pressable" aria-label="删除" @click="deleteLink(i)">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
                   stroke="currentColor" stroke-width="1.8" stroke-linecap="round" class="w-4 h-4">
                <path d="M3 6h18M8 6V4h8v2M19 6l-1 14H6L5 6M10 11v6M14 11v6" />
              </svg>
            </button>
          </div>
        </div>
      </div>

      <p class="mt-6 text-[11px] text-ink-3 text-center">
        所有链接只存在这台设备的浏览器里，不会上传。
      </p>
    </main>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { getStorage, setStorage } from '../utils/storage'
import { DEFAULT_LINKS, LINKS_STORAGE_KEY } from '../config/links'
import PageHeader from '../components/ui/PageHeader.vue'
import EmptyState from '../components/ui/EmptyState.vue'

const router = useRouter()
const links = ref([])
const form = ref({ name: '', url: '' })
const editingIndex = ref(-1)
const err = ref('')

const isEditing = computed(() => editingIndex.value !== -1)

const persist = () => setStorage(LINKS_STORAGE_KEY, links.value)

const saveLink = () => {
  const name = form.value.name.trim()
  const url = form.value.url.trim()

  // 以前这里静默 return，用户填错了完全没反馈
  if (!name) return (err.value = '请填写平台名称')
  if (!url) return (err.value = '请填写网址')
  try {
    const parsed = new URL(url)
    if (!/^https?:$/.test(parsed.protocol)) throw new Error('bad protocol')
  } catch {
    return (err.value = '网址格式不对，需要以 http:// 或 https:// 开头')
  }

  err.value = ''
  if (isEditing.value) {
    links.value[editingIndex.value] = { name, url }
    editingIndex.value = -1
  } else {
    links.value.push({ name, url })
  }
  persist()
  form.value = { name: '', url: '' }
}

const editLink = (i) => {
  editingIndex.value = i
  form.value = { ...links.value[i] }
  err.value = ''
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const cancelEdit = () => {
  editingIndex.value = -1
  form.value = { name: '', url: '' }
  err.value = ''
}

const deleteLink = (i) => {
  if (!confirm(`确定删除「${links.value[i].name}」吗？`)) return
  links.value.splice(i, 1)
  if (editingIndex.value === i) cancelEdit()
  persist()
}

onMounted(() => {
  links.value = getStorage(LINKS_STORAGE_KEY, DEFAULT_LINKS)
})
</script>

<style scoped>
.field {
  width: 100%;
  padding: 11px 13px;
  border-radius: var(--r-sm);
  background: var(--bg);
  border: 1px solid var(--line);
  color: var(--ink);
  font-size: 15px;
  outline: none;
  transition: border-color 180ms ease, box-shadow 180ms ease;
}
.field::placeholder { color: var(--ink-3); }
.field:focus {
  border-color: color-mix(in srgb, var(--accent) 65%, transparent);
  box-shadow: 0 0 0 3px color-mix(in srgb, var(--accent) 14%, transparent);
}

.btn {
  flex: 1;
  padding: 11px 0;
  border-radius: var(--r-sm);
  font-size: 15px;
  font-weight: 600;
  border: 1px solid transparent;
  cursor: pointer;
}
.btn-primary { background: var(--accent); color: #fff; }
.btn-ghost { background: var(--bg-elev-2); border-color: var(--line); color: var(--ink-2); }

.icon-btn {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  border-radius: 9px;
  background: var(--bg-elev-2);
  border: 1px solid var(--line);
  color: var(--ink-2);
  cursor: pointer;
}
.icon-btn-danger { color: var(--accent); }
</style>
