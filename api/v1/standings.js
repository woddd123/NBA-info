import { cachedResource } from '../_lib/data-source.js'
import { config, ttl } from '../_lib/config.js'
import { persistStandings } from '../_lib/db.js'
import { boundedInt, fetchJSON, json, methodNotAllowed, queryValue } from '../_lib/http.js'

export default async function handler(req, res) {
  if (req.method !== 'GET') return methodNotAllowed(res)
  const season = boundedInt(req.query.season, latestRegularSeason(), 1947, 2100)
  try {
    const result = await cachedResource({
      key: `standings:regular:${season}`, resource: 'standings', ttl: ttl.standings,
      force: queryValue(req.query.refresh) === '1',
      fetchUpstream: () => fetchJSON(`${config.espnBaseURL}/v2/sports/basketball/nba/standings?season=${season}&seasontype=2`),
      persist: persistStandings,
    })
    return json(res, 200, result.data, { 'X-Data-Source': result.source, 'X-Data-Stale': String(result.stale) })
  } catch (error) {
    return json(res, 502, { error: 'data_unavailable', message: error.message })
  }
}

function latestRegularSeason(now = new Date()) {
  const year = now.getUTCFullYear()
  // ESPN uses the ending year as the season id. Before October, the latest
  // regular season is the one that ended in the current calendar year.
  return now.getUTCMonth() >= 9 ? year + 1 : year
}
