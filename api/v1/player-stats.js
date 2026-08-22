import { cachedResource } from '../_lib/data-source.js'
import { config, ttl } from '../_lib/config.js'
import { persistPlayerStats } from '../_lib/db.js'
import { boundedInt, fetchJSON, json, methodNotAllowed, queryValue } from '../_lib/http.js'

export default async function handler(req, res) {
  if (req.method !== 'GET') return methodNotAllowed(res)
  if (!config.ballDontLieKey) return json(res, 503, { error: 'BALLDONTLIE_API_KEY_not_configured' })
  const season = boundedInt(req.query.season, new Date().getUTCFullYear(), 1946, 2100)
  const playerIds = queryValue(req.query.player_ids).split(',').filter(id => /^\d+$/.test(id)).slice(0, 50)
  if (!playerIds.length) return json(res, 400, { error: 'player_ids_required' })
  const params = new URLSearchParams({ season: String(season) })
  playerIds.forEach(id => params.append('player_ids[]', id))
  try {
    const result = await cachedResource({
      key: `player-stats:${season}:${playerIds.join(',')}`, resource: 'player_stats', ttl: ttl.playerStats,
      force: queryValue(req.query.refresh) === '1',
      fetchUpstream: () => fetchJSON(`${config.ballDontLieBaseURL}/season_averages?${params}`, { headers: { Authorization: config.ballDontLieKey } }),
      persist: payload => persistPlayerStats(season, payload.data ?? []),
    })
    return json(res, 200, result.data, { 'X-Data-Source': result.source, 'X-Data-Stale': String(result.stale) })
  } catch (error) {
    return json(res, 502, { error: 'data_unavailable', message: error.message })
  }
}
