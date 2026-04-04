import { getStorage, setStorage } from './storage'

const CACHE_EXPIRE_TIME = 2 * 60 * 60 * 1000 // 2 hours

export const getCache = (key) => {
  const cached = getStorage(key)
  if (!cached) return null
  
  const { data, timestamp } = cached
  if (Date.now() - timestamp > CACHE_EXPIRE_TIME) {
    return null // Expired
  }
  return data
}

export const setCache = (key, data) => {
  setStorage(key, {
    data,
    timestamp: Date.now()
  })
}
