import axios from 'axios'
import { getCache, setCache, LONG_TTL } from '../utils/cache'
import { mockTeams, mockPlayers, mockPlayerDetail, getChineseTeamName } from './mockData'

// ESPN scoreboard API 返回的缩写有时和 standings API 不一致，需要映射到本项目使用的 ESPN standings 缩写
const sbToTeamAbbr = {
  'GS': 'GS', 'GSW': 'GS',
  'SA': 'SA', 'SAS': 'SA',
  'NY': 'NY', 'NYK': 'NY',
  'PHX': 'PHX',
  'CHA': 'CHA', 'UT': 'UTA', 'UTAH': 'UTA', 'BKN': 'BKN',
  'LA': 'LAL', 'LAC': 'LAC',
}

const pairKey = (abbr1, abbr2) => {
  if (!abbr1 || !abbr2) return ''
  return [abbr1, abbr2].sort().join('-')
}

// 2026 NBA 官方季后赛 bracket。不能用实时 standings 排名生成，否则进入季后赛后排名顺序会变乱。
const playoffSeeds = {
  east: ['DET', 'BOS', 'NY', 'CLE', 'TOR', 'ATL', 'PHI', 'ORL'],
  west: ['OKC', 'SA', 'DEN', 'LAL', 'HOU', 'MIN', 'POR', 'PHX']
}

const playoffBracket = {
  east: {
    firstRound: [
      ['DET', 'ORL'], // 1 vs 8
      ['CLE', 'TOR'], // 4 vs 5
      ['NY', 'ATL'],  // 3 vs 6
      ['BOS', 'PHI']  // 2 vs 7
    ],
    semiFinals: [
      ['DET', 'CLE'],
      ['NY', 'PHI']
    ],
    confFinals: [
      [null, 'NY']
    ]
  },
  west: {
    firstRound: [
      ['OKC', 'PHX'], // 1 vs 8
      ['LAL', 'HOU'], // 4 vs 5
      ['DEN', 'MIN'], // 3 vs 6
      ['SA', 'POR']   // 2 vs 7
    ],
    semiFinals: [
      ['OKC', 'LAL'],
      ['SA', 'MIN']
    ],
    confFinals: [
      ['OKC', 'SA']
    ]
  }
}

// 所有客户端统一访问自建数据层；Redis / PostgreSQL / 第三方回源由服务端处理。
const dataApi = axios.create({
  baseURL: '/api/v1',
  timeout: 10000
})

const requestWithCache = async (key, requestFn, mockFallback, forceRefresh = false) => {
  if (!forceRefresh) {
    const cached = getCache(key)
    if (cached) return cached
  }
  try {
    const response = await requestFn()
    const data = response.data
    setCache(key, data)
    return data
  } catch (error) {
    console.warn(`[API] Request failed for ${key}, using fallback data. Error: ${error.message}`)
    return typeof mockFallback === 'function' ? mockFallback() : mockFallback
  }
}

// 获取指定日期赛程
export const getGamesByDate = async (date, forceRefresh = false) => {
  const data = await requestWithCache(
    `games_${date}`,
    () => dataApi.get('/games', { params: { date, refresh: forceRefresh ? 1 : undefined } }),
    { events: [] },
    forceRefresh
  )
  
  // 转换 ESPN 数据格式适配原有组件
  const games = (data?.events || []).map(event => {
    const homeTeam = event.competitions[0].competitors.find(c => c.homeAway === 'home')
    const visitorTeam = event.competitions[0].competitors.find(c => c.homeAway === 'away')
    
    // 转换时间到中国时区
    let timeStr = event.status.displayClock || ''
    if (event.status.type.state === 'pre') {
      const matchDate = new Date(event.date)
      const hours = String(matchDate.getHours()).padStart(2, '0')
      const minutes = String(matchDate.getMinutes()).padStart(2, '0')
      timeStr = `${hours}:${minutes}`
    } else if (event.status.type.state === 'post') {
      // 卡片上的状态标签已经写了「已结束」，这里再写一遍就是同一句话说两次
      timeStr = ''
    } else {
      timeStr = event.status.type.shortDetail // 比如 "3rd Qtr" 或 "Halftime"
    }
    
    return {
      id: event.id,
      status: event.status.type.state === 'post' ? '已结束' : (event.status.type.state === 'pre' ? '未开始' : '进行中'),
      time: timeStr,
      home_team: {
        abbreviation: homeTeam.team.abbreviation,
        full_name: homeTeam.team.displayName,
        name: getChineseTeamName(homeTeam.team.shortDisplayName)
      },
      home_team_score: homeTeam.score,
      visitor_team: {
        abbreviation: visitorTeam.team.abbreviation,
        full_name: visitorTeam.team.displayName,
        name: getChineseTeamName(visitorTeam.team.shortDisplayName)
      },
      visitor_team_score: visitorTeam.score
    }
  })
  
  return { data: games }
}

// 获取所有球队 (使用 ESPN standings 接口同时获取排名数据)
export const getTeams = async (forceRefresh = false) => {
  const data = await requestWithCache(
    'espn_standings',
    () => dataApi.get('/standings', { params: { refresh: forceRefresh ? 1 : undefined } }),
    { children: [] },
    forceRefresh
  )
  
  try {
    let allTeams = []
    
    // ESPN 数据结构: children[0] = East, children[1] = West
    data.children.forEach(conferenceData => {
      const conference = conferenceData.name === 'Eastern Conference' ? 'East' : 'West'
      
      const teamsInConf = conferenceData.standings.entries.map(entry => {
        const team = entry.team
        const stats = entry.stats
        
        const getStat = (name) => stats.find(s => s.name === name)?.value || 0
        
        return {
          id: team.id,
          abbreviation: team.abbreviation,
          name: getChineseTeamName(team.shortDisplayName),
          full_name: team.displayName,
          conference: conference,
          // 从 standings 中提取真实战绩数据
          wins: getStat('wins'),
          losses: getStat('losses'),
          winRate: getStat('winPercent'),
          streak: stats.find(s => s.name === 'streak')?.displayValue || ''
        }
      })
      
      allTeams = [...allTeams, ...teamsInConf]
    })
    
    return { data: allTeams.length ? allTeams : mockTeams }
  } catch (e) {
    return { data: mockTeams }
  }
}

// 获取球员列表 (真实数据)
export const getPlayers = (page = 0, per_page = 25, forceRefresh = false) => {
  return requestWithCache(
    `bdl_players_${page}_${per_page}`,
    () => dataApi.get('/players', { params: { page, per_page, refresh: forceRefresh ? 1 : undefined } }),
    { data: mockPlayers(per_page) }, // 如果 API 失效返回 mock
    forceRefresh
  )
}

// 获取指定球员详情 (真实数据)
export const getPlayerDetail = (id, forceRefresh = false) => {
  return requestWithCache(
    `bdl_player_${id}`,
    () => dataApi.get('/player', { params: { id, refresh: forceRefresh ? 1 : undefined } }),
    { data: mockPlayerDetail(id) },
    forceRefresh
  )
}

// 季后赛首轮对阵生成函数
const generateFirstRound = (teams) => {
  if (!teams || teams.length < 8) return []
  return [
    { match: 1, team1: teams[0], team2: teams[7], round: 1 }, // 1 vs 8
    { match: 2, team1: teams[3], team2: teams[4], round: 1 }, // 4 vs 5
    { match: 3, team1: teams[2], team2: teams[5], round: 1 }, // 3 vs 6
    { match: 4, team1: teams[1], team2: teams[6], round: 1 }, // 2 vs 7
  ]
}

// 获取赛季场均数据 (真实数据)
export const getSeasonAverages = (season, playerIds = [], forceRefresh = false) => {
  return requestWithCache(
    `bdl_season_averages_${season}_${playerIds.join(',')}`,
    () => dataApi.get('/player-stats', {
      params: {
        season,
        player_ids: playerIds.join(','),
        refresh: forceRefresh ? 1 : undefined
      }
    }),
    { data: [] },
    forceRefresh
  )
}

// 获取季后赛对阵数据
export const getPlayoffsData = async (forceRefresh = false) => {
  const teamsData = await getTeams(forceRefresh)

  const allTeams = teamsData.data || []

  if (allTeams.length === 0) {
    const mockEast = mockTeams.filter(t => t.conference === 'East').slice(0, 8)
    const mockWest = mockTeams.filter(t => t.conference === 'West').slice(0, 8)

    return {
      east: { teams: mockEast, firstRound: generateFirstRound(mockEast) },
      west: { teams: mockWest, firstRound: generateFirstRound(mockWest) }
    }
  }

  const teamsByAbbr = Object.fromEntries(allTeams.map(team => [team.abbreviation, team]))
  const makeTeam = (abbr) => {
    if (!abbr) return null
    return teamsByAbbr[abbr] || {
      id: abbr,
      abbreviation: abbr,
      name: getChineseTeamName(abbr),
      full_name: abbr
    }
  }

  const eastTeams = playoffSeeds.east.map(makeTeam)
  const westTeams = playoffSeeds.west.map(makeTeam)

  // 获取真实季后赛比赛结果
  const { seriesData, gamesBySeries, lastUpdated, updatedAt } = await fetchPlayoffsData(forceRefresh)

  const makeMatch = ([abbr1, abbr2], index) => ({
    match: index + 1,
    team1: makeTeam(abbr1),
    team2: makeTeam(abbr2),
    round: 1
  })

  // 为每组对阵添加系列赛比分。比分必须按“对阵组合”取，不能按球队取，否则下一轮会覆盖首轮。
  const addScoresToMatch = (match, seriesData) => {
    // Both null -> skip; one null is OK (e.g. confFinals bracket)
    if (!match.team1 && !match.team2) return match
    const abbr1 = match.team1?.abbreviation || null
    const abbr2 = match.team2?.abbreviation || null

    // Find series key: prefer direct pairKey, fallback to searching when one team is null
    let key = null
    if (abbr1 && abbr2) {
      key = pairKey(abbr1, abbr2)
    } else {
      const known = abbr1 || abbr2
      key = Object.keys(seriesData).find(k => k.includes(known))
    }

    const series = key ? seriesData[key] : null
    if (series) {
      if (abbr1) { match.wins1 = series.wins?.[abbr1] || 0 }
      if (abbr2) { match.wins2 = series.wins?.[abbr2] || 0 }
      match.seriesSummary = series.summary || ''
      match.seriesCompleted = series.completed || false
      match.games = key ? (gamesBySeries[key] || []) : []
    }
    return match
  }

  const buildRound = (roundPairs) => roundPairs
    .map(makeMatch)
    .map(m => addScoresToMatch(m, seriesData))

  const eastFirstRound = buildRound(playoffBracket.east.firstRound)
  const westFirstRound = buildRound(playoffBracket.west.firstRound)
  const eastSemiFinals = buildRound(playoffBracket.east.semiFinals)
  const westSemiFinals = buildRound(playoffBracket.west.semiFinals)

  // Resolve confFinals null entries from semiFinals winners
  const resolveConfBracket = (semiFinals, confPairs) => confPairs.map(([a, b]) => {
    const winnerOf = (sf) => sf?.wins1 >= 4 ? sf.team1?.abbreviation : sf?.wins2 >= 4 ? sf.team2?.abbreviation : null
    return [a && a !== null ? a : (winnerOf(semiFinals[0]) || a),
            b && b !== null ? b : (winnerOf(semiFinals[1]) || b)]
  })
  const resolvedEastConf = resolveConfBracket(eastSemiFinals, playoffBracket.east.confFinals)
  const resolvedWestConf = resolveConfBracket(westSemiFinals, playoffBracket.west.confFinals)
  const eastConfFinals = buildRound(resolvedEastConf)
  const westConfFinals = buildRound(resolvedWestConf)


  // Compute NBA Finals matchup from conference winners
  const eastWinner = eastConfFinals[0]?.wins1 >= 4 ? eastConfFinals[0].team1
    : eastConfFinals[0]?.wins2 >= 4 ? eastConfFinals[0].team2 : null
  const westWinner = westConfFinals[0]?.wins1 >= 4 ? westConfFinals[0].team1
    : westConfFinals[0]?.wins2 >= 4 ? westConfFinals[0].team2 : null

  let finals = null
  if (eastWinner && westWinner) {
    const fKey = pairKey(eastWinner.abbreviation, westWinner.abbreviation)
    const series = seriesData[fKey]
    finals = {
      team1: eastWinner,
      team2: westWinner,
      wins1: series?.wins?.[eastWinner.abbreviation] || 0,
      wins2: series?.wins?.[westWinner.abbreviation] || 0,
      seriesSummary: series?.summary || '',
      seriesCompleted: series?.completed || false,
      games: gamesBySeries[fKey] || []
    }
  }

  return {
    east: {
      teams: eastTeams,
      firstRound: eastFirstRound,
      semiFinals: eastSemiFinals,
      confFinals: eastConfFinals
    },
    west: {
      teams: westTeams,
      firstRound: westFirstRound,
      semiFinals: westSemiFinals,
      confFinals: westConfFinals
    },
    finals,
    lastUpdated,
    updatedAt
  }
}

// 获取季后赛比赛结果
// ESPN range query 有时漏事件，改用每天单独查询确保数据完整
const PLAYOFFS_CONCURRENCY = 8

// 把一天的 scoreboard 响应并入 seriesData / gamesBySeries
const mergePlayoffEvents = (events, seriesData, gamesBySeries) => {
  let lastGameDate = null

  events.forEach(event => {
    const competition = event.competitions?.[0]
    if (!competition) return

    const series = competition.series
    if (!series?.competitors?.length) return

    const home = competition.competitors.find(c => c.homeAway === 'home')
    const away = competition.competitors.find(c => c.homeAway === 'away')
    if (!home?.team?.abbreviation || !away?.team?.abbreviation) return

    const homeAbbr = sbToTeamAbbr[home.team.abbreviation] || home.team.abbreviation
    const awayAbbr = sbToTeamAbbr[away.team.abbreviation] || away.team.abbreviation
    const key = pairKey(homeAbbr, awayAbbr)
    const teamById = {
      [home.team.id]: homeAbbr,
      [away.team.id]: awayAbbr
    }

    series.competitors.forEach(comp => {
      const abbr = teamById[comp.id]
      if (!abbr) return
      if (!seriesData[key]) {
        seriesData[key] = {
          wins: {},
          games: [],
          summary: series.summary || '',
          completed: series.completed || false
        }
        gamesBySeries[key] = []
      }
      seriesData[key].wins[abbr] = comp.wins
      seriesData[key].summary = series.summary || ''
      seriesData[key].completed = series.completed || false

      // Record per-game data (Beijing time)
      const bjDate = new Date(new Date(event.date).getTime() + 8 * 60 * 60 * 1000)
      const dateLabel = bjDate.getMonth() + 1 + '/' + bjDate.getDate()
      const gameEntry = {
        date: dateLabel,
        homeAbbr, homeScore: home.score,
        awayAbbr, awayScore: away.score,
        status: event.status.type.state === 'post' ? '已结束' : (event.status.type.shortDetail || '进行中')
      }
      const dup = gamesBySeries[key].find(g => g.date === dateLabel && g.homeAbbr === homeAbbr)
      if (!dup) gamesBySeries[key].push(gameEntry)
      lastGameDate = dateLabel
    })
  })

  return lastGameDate
}

const fetchPlayoffsData = async (forceRefresh = false) => {
  const seriesData = {}
  const gamesBySeries = {}
  let lastGameDate = null

  const now = new Date()

  // 起点固定为 4/15（季后赛最早开打日），终点用 UTC 明天确保覆盖北京时间今天的比赛。
  // 用 Date 运算而不是字符串拼接，否则月末会算出 20260432 这种非法日期。
  // 再按 6/30 封顶：总决赛最晚也就打到六月底，不封顶的话到了休赛期这里会一路查到当天，
  // 白白多发几十个请求。
  const year = now.getUTCFullYear()
  const start = new Date(Date.UTC(year, 3, 15))
  const seasonEnd = new Date(Date.UTC(year, 5, 30))
  const today = new Date(Date.UTC(year, now.getUTCMonth(), now.getUTCDate() + 1))
  const end = today < seasonEnd ? today : seasonEnd

  const dates = []
  for (let d = new Date(start); d <= end; d.setUTCDate(d.getUTCDate() + 1)) {
    const y = d.getUTCFullYear()
    const m = String(d.getUTCMonth() + 1).padStart(2, '0')
    const day = String(d.getUTCDate()).padStart(2, '0')
    dates.push(`${y}${m}${day}`)
  }

  // ESPN 的 range 查询会漏事件，只能逐日查；但可以并发，并且已结束的日期走长效缓存，
  // 否则每次进入季后赛页都是上百个串行请求。
  const fetchDay = async (dateStr) => {
    const cacheKey = `espn_playoffs_day_${dateStr}`
    if (!forceRefresh) {
      const cached = getCache(cacheKey, LONG_TTL)
      if (cached) return cached
    }
    try {
      // 旧循环中的 dateStr 是 ESPN/UTC 查询日期；服务端接收北京时间，所以向后推一天。
      const rawDate = new Date(Date.UTC(Number(dateStr.slice(0, 4)), Number(dateStr.slice(4, 6)) - 1, Number(dateStr.slice(6, 8)) + 1))
      const queryDate = `${rawDate.getUTCFullYear()}-${String(rawDate.getUTCMonth() + 1).padStart(2, '0')}-${String(rawDate.getUTCDate()).padStart(2, '0')}`
      const resp = await dataApi.get('/games', { params: { date: queryDate, refresh: forceRefresh ? 1 : undefined } })
      const events = resp.data?.events || []
      // 一整天都打完了才允许长期缓存，否则进行中的比分会被冻住
      const allFinal = events.length > 0 && events.every(e => e.status?.type?.state === 'post')
      if (allFinal) setCache(cacheKey, events)
      return events
    } catch (e) {
      console.warn('[PlayoffsData] API failed for ' + dateStr + ':', e.message)
      return []
    }
  }

  for (let i = 0; i < dates.length; i += PLAYOFFS_CONCURRENCY) {
    const batch = dates.slice(i, i + PLAYOFFS_CONCURRENCY)
    const results = await Promise.all(batch.map(fetchDay))
    results.forEach(events => {
      const last = mergePlayoffEvents(events, seriesData, gamesBySeries)
      if (last) lastGameDate = last
    })
  }

  return {
    seriesData,
    gamesBySeries,
    lastUpdated: lastGameDate ? lastGameDate + ' (北京时间)' : '暂无数据',
    updatedAt: Date.now()
  }
}
