import { cachedResource } from '../_lib/data-source.js'
import { config, ttl } from '../_lib/config.js'
import { persistPlayers } from '../_lib/db.js'
import { fetchJSON, json, methodNotAllowed, queryValue } from '../_lib/http.js'

export default async function handler(req, res) {
  if (req.method !== 'GET') return methodNotAllowed(res)
  if (!config.ballDontLieKey) return json(res, 503, { error: 'BALLDONTLIE_API_KEY_not_configured' })
  const id = queryValue(req.query.id)
  if (!/^\d+$/.test(id)) return json(res, 400, { error: 'invalid_player_id' })
  try {
    const result = await cachedResource({
      key: `player:${id}`, resource: 'player', ttl: ttl.player,
      force: queryValue(req.query.refresh) === '1',
      fetchUpstream: () => fetchJSON(`${config.ballDontLieBaseURL}/players/${id}`, { headers: { Authorization: config.ballDontLieKey } }),
      persist: payload => persistPlayers(payload.data ? [payload.data] : []),
    })
    return json(res, 200, result.data, { 'X-Data-Source': result.source, 'X-Data-Stale': String(result.stale) })
  } catch (error) {
    return json(res, 502, { error: 'data_unavailable', message: error.message })
  }
}
