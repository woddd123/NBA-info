import { getStorage, setStorage, removeStorage } from './storage'

export const DEFAULT_TTL = 2 * 60 * 60 * 1000 // 2 hours
export const LONG_TTL = 30 * 24 * 60 * 60 * 1000 // 30 days，用于已结束、不会再变的历史数据

const INDEX_KEY = '__cache_index__'
const MAX_ENTRIES = 200

const readIndex = () => getStorage(INDEX_KEY, []) || []

const touchIndex = (key) => {
  const index = readIndex().filter(k => k !== key)
  index.push(key)
  // 超出上限时淘汰最久未写入的条目，否则每查一天赛程就多一个永不清理的 key
  while (index.length > MAX_ENTRIES) {
    removeStorage(index.shift())
  }
  setStorage(INDEX_KEY, index)
}

const dropFromIndex = (key) => {
  setStorage(INDEX_KEY, readIndex().filter(k => k !== key))
}

export const getCache = (key, ttl = DEFAULT_TTL) => {
  const cached = getStorage(key)
  if (!cached) return null

  const { data, timestamp } = cached
  if (Date.now() - timestamp > ttl) {
    removeStorage(key)
    dropFromIndex(key)
    return null
  }
  return data
}

export const setCache = (key, data) => {
  if (setStorage(key, { data, timestamp: Date.now() })) {
    touchIndex(key)
    return true
  }

  // 写失败通常是 localStorage 配额满了：清掉一半旧缓存后重试一次
  const index = readIndex()
  const half = Math.ceil(index.length / 2)
  index.slice(0, half).forEach(removeStorage)
  setStorage(INDEX_KEY, index.slice(half))

  if (setStorage(key, { data, timestamp: Date.now() })) {
    touchIndex(key)
    return true
  }
  return false
}

export const clearCache = () => {
  readIndex().forEach(removeStorage)
  removeStorage(INDEX_KEY)
}
