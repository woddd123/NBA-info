import { cachedResource } from '../_lib/data-source.js'
import { config, ttl } from '../_lib/config.js'
import { boundedInt, fetchJSON, json, methodNotAllowed, queryValue } from '../_lib/http.js'

export default async function handler(req, res) {
  if (req.method !== 'GET') return methodNotAllowed(res)
  const season = boundedInt(req.query.season, latestRegularSeason(), 1947, 2100)
  try {
    const result = await cachedResource({
      key: `playoffs:v1:${season}`, resource: 'playoffs', ttl: ttl.standings,
      force: queryValue(req.query.refresh) === '1',
      fetchUpstream: async () => {
        const [scoreboard, standings] = await Promise.all([
          fetchJSON(`${config.espnSiteBaseURL}/scoreboard?dates=${season}0415-${season}0630&seasontype=3&limit=1000`, { timeout: 20_000 }),
          fetchJSON(`${config.espnBaseURL}/v2/sports/basketball/nba/standings?season=${season}&seasontype=2`),
        ])
        return normalizePlayoffs(scoreboard, standings, season)
      },
    })
    return json(res, 200, result.data, { 'X-Data-Source': result.source, 'X-Data-Stale': String(result.stale) })
  } catch (error) {
    return json(res, 502, { error: 'data_unavailable', message: error.message })
  }
}

function normalizePlayoffs(scoreboard, standings, season) {
  const seeds = new Map()
  for (const conference of standings.children ?? []) {
    const side = conference.name === 'Eastern Conference' ? 'East' : 'West'
    for (const entry of conference.standings?.entries ?? []) {
      const abbr = normalizeAbbreviation(entry.team?.abbreviation || '')
      const playoffSeed = entry.stats?.find(stat => stat.name === 'playoffSeed')?.value
      if (abbr) seeds.set(abbr, { conference: side, seed: Number(playoffSeed) || null })
    }
  }

  const grouped = new Map()
  for (const event of scoreboard.events ?? []) {
    if (Number(event.season?.year) !== season || Number(event.season?.type) !== 3) continue
    const competition = event.competitions?.[0]
    const competitors = competition?.competitors ?? []
    if (competitors.length !== 2 || !competition.series) continue
    const teams = competitors.map(item => ({
      id: String(item.team?.id || ''),
      abbreviation: normalizeAbbreviation(item.team?.abbreviation || ''),
    }))
    const key = teams.map(team => team.abbreviation).sort().join('-')
    const prior = grouped.get(key)
    if (!prior || new Date(event.date) > new Date(prior.event.date)) grouped.set(key, { event, competition, teams })
  }

  const series = [...grouped.values()].map(({ event, competition, teams }) => {
    const headline = competition.notes?.[0]?.headline || ''
    const round = headline.includes('1st Round') ? 'first_round'
      : headline.includes('Semifinals') ? 'semifinals'
        : headline.includes('Finals') && !headline.includes('NBA Finals') ? 'conference_finals'
          : 'nba_finals'
    const conference = headline.startsWith('East') ? 'East' : headline.startsWith('West') ? 'West' : 'Finals'
    const winsById = new Map((competition.series?.competitors ?? []).map(item => [String(item.id), Number(item.wins) || 0]))
    return {
      id: teams.map(team => team.abbreviation).sort().join('-'), round, conference,
      completed: Boolean(competition.series?.completed), summary: competition.series?.summary || '',
      teams: teams.map(team => ({
        abbreviation: team.abbreviation,
        seed: seeds.get(team.abbreviation)?.seed ?? null,
        conference: seeds.get(team.abbreviation)?.conference ?? null,
        wins: winsById.get(team.id) ?? 0,
      })).sort((a, b) => round === 'nba_finals' ? (a.conference === 'East' ? -1 : 1) : (a.seed ?? 99) - (b.seed ?? 99)),
    }
  }).sort((a, b) => roundOrder(a.round) - roundOrder(b.round) || (a.teams[0].seed ?? 99) - (b.teams[0].seed ?? 99))

  return { season, season_display: `${season - 1}-${String(season).slice(-2)}`, series }
}

function roundOrder(round) {
  return ['first_round', 'semifinals', 'conference_finals', 'nba_finals'].indexOf(round)
}

function normalizeAbbreviation(value) {
  return ({ NY: 'NYK', SA: 'SAS', GS: 'GSW', UTAH: 'UTA', WSH: 'WAS', NO: 'NOP' })[value] || value
}

function latestRegularSeason(now = new Date()) {
  const year = now.getUTCFullYear()
  return now.getUTCMonth() >= 9 ? year + 1 : year
}
