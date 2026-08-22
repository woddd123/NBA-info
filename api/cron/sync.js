import { config } from '../_lib/config.js'
import { beijingDateKey, json } from '../_lib/http.js'

export default async function handler(req, res) {
  if (config.cronSecret && req.headers.authorization !== `Bearer ${config.cronSecret}`) return json(res, 401, { error: 'unauthorized' })
  const origin = `https://${req.headers.host}`
  const dates = [-1, 0, 1].map(offset => {
    const date = new Date(Date.now() + offset * 86400000)
    return beijingDateKey(date)
  })
  const urls = [
    ...dates.map(date => `${origin}/api/v1/games?date=${date}&refresh=1`),
    `${origin}/api/v1/standings?refresh=1`,
    `${origin}/api/v1/playoffs?refresh=1`,
    `${origin}/api/v1/players?per_page=600&refresh=1`,
  ]
  const results = await Promise.allSettled(urls.map(url => fetch(url, { headers: { 'User-Agent': 'NBAASS-Cron/1.0' } })))
  return json(res, 200, { ok: results.filter(item => item.status === 'fulfilled' && item.value.ok).length, total: urls.length })
}
