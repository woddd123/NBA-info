import axios from 'axios'
import { getCache, setCache } from '../utils/cache'
import { getStorage } from '../utils/storage'
import { mockTeams, mockPlayers, mockPlayerDetail, getChineseTeamName } from './mockData'

// ESPN 免费且无需 API Key 的公共接口
const espnApi = axios.create({
  baseURL: 'https://site.api.espn.com/apis',
  timeout: 10000
})

// BallDontLie 官方真实球员数据接口 (需要 API Key)
const bdlApi = axios.create({
  baseURL: 'https://api.balldontlie.io/v1',
  timeout: 10000
})

// 添加请求拦截器注入 API Key
bdlApi.interceptors.request.use(config => {
  // 我们直接读取用户填写的 key 或者使用你提供的 key 作为默认兜底
  const apiKey = getStorage('nba_api_key', '6a9a5654-93f0-4591-a262-bde5da88153d')
  if (apiKey) {
    config.headers['Authorization'] = apiKey
  }
  return config
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
  // 注意：用户界面上传入的 date 是中国当地日期 (如 2026-04-04)
  // 但是 ESPN 的 /scoreboard?dates=20260404 接口返回的是【美国时间 4月4日】的比赛，
  // 这实际上对应的是【中国时间 4月5日】的比赛！
  // 所以我们需要把请求发给 ESPN 的前一天（也就是美国时间 4月3日），才能获取到中国时间 4月4日 的比赛。
  
  const targetDate = new Date(date)
  targetDate.setDate(targetDate.getDate() - 1) // 减去一天以对齐 ESPN 的赛程表
  
  const year = targetDate.getFullYear()
  const month = String(targetDate.getMonth() + 1).padStart(2, '0')
  const day = String(targetDate.getDate()).padStart(2, '0')
  const formattedDate = `${year}${month}${day}` // ESPN 需要 YYYYMMDD 格式
  
  const data = await requestWithCache(
    `espn_games_${formattedDate}`, 
    () => espnApi.get(`/site/v2/sports/basketball/nba/scoreboard?dates=${formattedDate}`),
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
      timeStr = '已结束'
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
    () => espnApi.get('/v2/sports/basketball/nba/standings'),
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
    () => bdlApi.get('/players', { params: { page, per_page } }),
    { data: mockPlayers(per_page) }, // 如果 API 失效返回 mock
    forceRefresh
  )
}

// 获取指定球员详情 (真实数据)
export const getPlayerDetail = (id, forceRefresh = false) => {
  return requestWithCache(
    `bdl_player_${id}`,
    () => bdlApi.get(`/players/${id}`),
    { data: mockPlayerDetail(id) },
    forceRefresh
  )
}

// 获取赛季场均数据 (真实数据)
export const getSeasonAverages = (season, playerIds = [], forceRefresh = false) => {
  return requestWithCache(
    `bdl_season_averages_${season}_${playerIds.join(',')}`,
    () => bdlApi.get('/season_averages', { 
      params: { 
        season, 
        'player_ids[]': playerIds 
      } 
    }),
    { data: [] }, 
    forceRefresh
  )
}
