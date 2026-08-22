export const config = {
  espnBaseURL: 'https://site.api.espn.com/apis',
  espnSiteBaseURL: 'https://site.api.espn.com/apis/site/v2/sports/basketball/nba',
  espnStatsBaseURL: 'https://site.web.api.espn.com/apis/common/v3/sports/basketball/nba',
  ballDontLieBaseURL: 'https://api.balldontlie.io/v1',
  ballDontLieKey: process.env.BALLDONTLIE_API_KEY || '',
  cronSecret: process.env.CRON_SECRET || '',
}

export const ttl = {
  liveGame: 20,
  todayGames: 180,
  scheduledGames: 900,
  standings: 600,
  playerList: 3600,
  player: 86400,
  playerStats: 21600,
}
