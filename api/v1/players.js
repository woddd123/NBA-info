import { cachedResource } from '../_lib/data-source.js'
import { config, ttl } from '../_lib/config.js'
import { persistPlayers, persistPlayerStats } from '../_lib/db.js'
import { boundedInt, fetchJSON, json, methodNotAllowed, queryValue } from '../_lib/http.js'

export default async function handler(req, res) {
  if (req.method !== 'GET') return methodNotAllowed(res)
  const page = boundedInt(req.query.page, 1, 1, 10000)
  const perPage = boundedInt(req.query.per_page, 100, 1, 600)
  const season = boundedInt(req.query.season, currentBasketballSeason(), 1947, 2100)
  const key = `players:v2:${season}:${page}:${perPage}`
  try {
    const result = await cachedResource({
      key, resource: 'players', ttl: ttl.playerList,
      force: queryValue(req.query.refresh) === '1',
      fetchUpstream: async () => {
        const [rosters, statistics] = await Promise.all([
          Promise.all(TEAM_SLUGS.map(async slug => {
            const roster = await fetchJSON(`${config.espnSiteBaseURL}/teams/${slug}/roster`)
            return (roster.athletes ?? []).map(athlete => normalizePlayer(athlete, roster.team))
          })),
          fetchJSON(`${config.espnStatsBaseURL}/statistics/byathlete?region=us&lang=en&contentorigin=espn&isqualified=false&season=${season}&seasontype=2&limit=1000`, { timeout: 20_000 }),
        ])
        const statsByPlayer = normalizeStatistics(statistics, season)
        const players = rosters.flat().sort((a, b) => a.last_name.localeCompare(b.last_name) || a.first_name.localeCompare(b.first_name))
          .map(player => ({ ...player, stats: statsByPlayer.get(player.id) ?? null }))
        const start = (page - 1) * perPage
        return {
          data: players.slice(start, start + perPage),
          meta: { current_page: page, per_page: perPage, total_count: players.length, total_pages: Math.ceil(players.length / perPage) },
        }
      },
      persist: async payload => {
        const players = payload.data ?? []
        await Promise.all([
          persistPlayers(players),
          persistPlayerStats(season, players.filter(player => player.stats).map(player => ({ player_id: player.id, ...player.stats })), 'espn'),
        ])
      },
    })
    return json(res, 200, result.data, { 'X-Data-Source': result.source, 'X-Data-Stale': String(result.stale) })
  } catch (error) {
    return json(res, 502, { error: 'data_unavailable', message: error.message })
  }
}

function currentBasketballSeason(now = new Date()) {
  const year = now.getUTCFullYear()
  return now.getUTCMonth() >= 8 ? year + 1 : year
}

function normalizeStatistics(payload, season) {
  const categoryNames = new Map((payload.categories ?? []).map(category => [category.name, category.names ?? []]))
  const result = new Map()
  for (const entry of payload.athletes ?? []) {
    const id = String(entry.athlete?.id ?? '')
    if (!id) continue
    const values = new Map()
    for (const category of entry.categories ?? []) {
      const names = categoryNames.get(category.name) ?? []
      names.forEach((name, index) => values.set(name, Number(category.values?.[index]) || 0))
    }
    result.set(id, {
      season,
      games_played: values.get('gamesPlayed') ?? 0,
      minutes: values.get('avgMinutes') ?? 0,
      points: values.get('avgPoints') ?? 0,
      rebounds: values.get('avgRebounds') ?? 0,
      assists: values.get('avgAssists') ?? 0,
      steals: values.get('avgSteals') ?? 0,
      blocks: values.get('avgBlocks') ?? 0,
      turnovers: values.get('avgTurnovers') ?? 0,
      field_goal_pct: values.get('fieldGoalPct') ?? 0,
      three_point_pct: values.get('threePointFieldGoalPct') ?? 0,
      free_throw_pct: values.get('freeThrowPct') ?? 0,
      field_goals_made: values.get('fieldGoalsMade') ?? 0,
      field_goals_attempted: values.get('fieldGoalsAttempted') ?? 0,
      three_pointers_made: values.get('threePointFieldGoalsMade') ?? 0,
      three_pointers_attempted: values.get('threePointFieldGoalsAttempted') ?? 0,
      free_throws_made: values.get('freeThrowsMade') ?? 0,
      free_throws_attempted: values.get('freeThrowsAttempted') ?? 0,
    })
  }
  return result
}

const TEAM_SLUGS = [
  'atl', 'bos', 'bkn', 'cha', 'chi', 'cle', 'dal', 'den', 'det', 'gs',
  'hou', 'ind', 'lac', 'lal', 'mem', 'mia', 'mil', 'min', 'no', 'ny',
  'okc', 'orl', 'phi', 'phx', 'por', 'sac', 'sa', 'tor', 'utah', 'wsh',
]

function normalizePlayer(athlete, team) {
  return {
    id: String(athlete.id),
    first_name: athlete.firstName || '',
    last_name: athlete.lastName || '',
    full_name: athlete.displayName || athlete.fullName || '',
    position: athlete.position?.abbreviation || athlete.position?.displayName || '',
    jersey_number: athlete.jersey || '',
    height: athlete.displayHeight || '',
    weight: athlete.displayWeight || '',
    age: athlete.age ?? null,
    experience_years: athlete.experience?.years ?? null,
    headshot: athlete.headshot?.href || '',
    team: team ? { id: String(team.id), abbreviation: team.abbreviation || '', full_name: team.displayName || '' } : null,
  }
}
