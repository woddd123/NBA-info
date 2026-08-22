import { Redis } from '@upstash/redis'

let redis

function client() {
  const url = process.env.UPSTASH_REDIS_REST_URL || process.env.KV_REST_API_URL
  const token = process.env.UPSTASH_REDIS_REST_TOKEN || process.env.KV_REST_API_TOKEN
  if (!url || !token) return null
  redis ||= new Redis({ url, token })
  return redis
}

export async function cacheGet(key) {
  try { return await client()?.get(key) ?? null } catch { return null }
}

export async function cacheSet(key, value, seconds) {
  try { await client()?.set(key, value, { ex: seconds }) } catch { /* Database remains the fallback. */ }
}

export async function withLock(key, work, waitForValue) {
  const redisClient = client()
  if (!redisClient) return work()
  const token = crypto.randomUUID()
  const lockKey = `lock:${key}`
  let acquired = false
  try {
    acquired = (await redisClient.set(lockKey, token, { nx: true, ex: 12 })) === 'OK'
    if (acquired) return await work()
    for (let attempt = 0; attempt < 8; attempt += 1) {
      await new Promise(resolve => setTimeout(resolve, 150))
      const value = await waitForValue()
      if (value) return value
    }
    return work()
  } finally {
    if (acquired) {
      try {
        if (await redisClient.get(lockKey) === token) await redisClient.del(lockKey)
      } catch { /* Lock expires automatically. */ }
    }
  }
}
