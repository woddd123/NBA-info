import { cachedResource } from '../_lib/data-source.js'
import { config, ttl } from '../_lib/config.js'
import { persistGames } from '../_lib/db.js'
import { beijingDateKey, espnDateKey, fetchJSON, json, methodNotAllowed, queryValue } from '../_lib/http.js'

export default async function handler(req, res) {
  if (req.method !== 'GET') return methodNotAllowed(res)
  const date = queryValue(req.query.date, beijingDateKey())
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) return json(res, 400, { error: 'invalid_date' })
  const today = beijingDateKey()
  const force = queryValue(req.query.refresh) === '1'
  const key = `games:${date}`
  try {
    const result = await cachedResource({
      key, resource: 'games', force,
      ttl: date === today ? ttl.todayGames : ttl.scheduledGames,
      immutable: date < today,
      fetchUpstream: () => fetchJSON(`${config.espnBaseURL}/site/v2/sports/basketball/nba/scoreboard?dates=${espnDateKey(date)}`),
      persist: payload => persistGames(payload, date),
    })
    const hasLive = result.data.events?.some(event => event.status?.type?.state === 'in')
    if (hasLive && result.source === 'upstream') await import('../_lib/redis.js').then(({ cacheSet }) => cacheSet(key, result.data, ttl.liveGame))
    return json(res, 200, result.data, { 'X-Data-Source': result.source, 'X-Data-Stale': String(result.stale) })
  } catch (error) {
    return json(res, 502, { error: 'data_unavailable', message: error.message })
  }
}
