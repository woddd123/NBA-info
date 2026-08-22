import { cacheGet, cacheSet, withLock } from './redis.js'
import { readSnapshot, writeSnapshot } from './db.js'

export async function cachedResource({ key, resource, ttl, fetchUpstream, persist, immutable = false, force = false }) {
  if (!force) {
    const cached = await cacheGet(key)
    if (cached) return { data: cached, source: 'redis', stale: false }

    const snapshot = await safeSnapshot(key)
    if (immutable && snapshot) {
      await cacheSet(key, snapshot.payload, ttl)
      return { data: snapshot.payload, source: 'database', stale: false }
    }
  }

  return withLock(key, async () => {
    if (!force) {
      const filled = await cacheGet(key)
      if (filled) return { data: filled, source: 'redis', stale: false }
    }
    try {
      const data = await fetchUpstream()
      await Promise.allSettled([
        writeSnapshot(key, resource, data),
        persist?.(data),
        cacheSet(key, data, ttl),
      ])
      return { data, source: 'upstream', stale: false }
    } catch (error) {
      const snapshot = await safeSnapshot(key)
      if (snapshot) return { data: snapshot.payload, source: 'database', stale: true }
      throw error
    }
  }, async () => {
    const value = await cacheGet(key)
    return value ? { data: value, source: 'redis', stale: false } : null
  })
}

async function safeSnapshot(key) {
  try { return await readSnapshot(key) } catch { return null }
}
