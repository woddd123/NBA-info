// 内置的推荐观赛入口（官方 / 主流平台）。首页和链接管理页共用同一份，
// 之前两处各抄了一份，改一处另一处不会跟着变。
export const DEFAULT_LINKS = [
  { name: '腾讯体育', url: 'https://sports.qq.com/nba/' },
  { name: 'CCTV5 体育频道', url: 'https://tv.cctv.com/live/cctv5' },
  { name: '咪咕视频 NBA', url: 'https://www.miguvideo.com/wap/resource/pc/pages/nba/index.html' },
  { name: 'NBA 官网', url: 'https://www.nba.com/watch/' }
]

export const LINKS_STORAGE_KEY = 'nba_links'
