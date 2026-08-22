// 30 支球队的规范化数据：品牌色、中文名、ESPN logo slug。
//
// 关于 `color`：用的不是死板的官方主色，而是「在近黑底上仍然可读」的品牌色变体。
// 篮网、马刺的官方主色是黑色，凯尔特人、雄鹿的绿太深，直接用会在深色 UI 上糊成一团，
// 所以这几支改用其品牌色系里更亮的那一支（银色 / 亮绿）。
const TEAMS = {
  ATL: { name: '老鹰', city: '亚特兰大', color: '#E03A3E', slug: 'atl' },
  BOS: { name: '凯尔特人', city: '波士顿', color: '#00A650', slug: 'bos' },
  BKN: { name: '篮网', city: '布鲁克林', color: '#D6D9DE', slug: 'bkn' },
  CHA: { name: '黄蜂', city: '夏洛特', color: '#00A5B5', slug: 'cha' },
  CHI: { name: '公牛', city: '芝加哥', color: '#CE1141', slug: 'chi' },
  CLE: { name: '骑士', city: '克利夫兰', color: '#C41E4A', slug: 'cle' },
  DAL: { name: '独行侠', city: '达拉斯', color: '#0064B1', slug: 'dal' },
  DEN: { name: '掘金', city: '丹佛', color: '#FEC524', slug: 'den' },
  DET: { name: '活塞', city: '底特律', color: '#ED174C', slug: 'det' },
  GSW: { name: '勇士', city: '金州', color: '#FDB927', slug: 'gs' },
  HOU: { name: '火箭', city: '休斯顿', color: '#CE1141', slug: 'hou' },
  IND: { name: '步行者', city: '印第安纳', color: '#FDBB30', slug: 'ind' },
  LAC: { name: '快船', city: '洛杉矶', color: '#ED174C', slug: 'lac' },
  LAL: { name: '湖人', city: '洛杉矶', color: '#F9A01B', slug: 'lal' },
  MEM: { name: '灰熊', city: '孟菲斯', color: '#7399C6', slug: 'mem' },
  MIA: { name: '热火', city: '迈阿密', color: '#F9423A', slug: 'mia' },
  MIL: { name: '雄鹿', city: '密尔沃基', color: '#00A94F', slug: 'mil' },
  MIN: { name: '森林狼', city: '明尼苏达', color: '#78BE20', slug: 'min' },
  NOP: { name: '鹈鹕', city: '新奥尔良', color: '#C8102E', slug: 'no' },
  NYK: { name: '尼克斯', city: '纽约', color: '#F58426', slug: 'ny' },
  OKC: { name: '雷霆', city: '俄克拉荷马城', color: '#007AC1', slug: 'okc' },
  ORL: { name: '魔术', city: '奥兰多', color: '#0B77BD', slug: 'orl' },
  PHI: { name: '76人', city: '费城', color: '#1D74C4', slug: 'phi' },
  PHX: { name: '太阳', city: '菲尼克斯', color: '#E56020', slug: 'phx' },
  POR: { name: '开拓者', city: '波特兰', color: '#E03A3E', slug: 'por' },
  SAC: { name: '国王', city: '萨克拉门托', color: '#7B4EA8', slug: 'sac' },
  SAS: { name: '马刺', city: '圣安东尼奥', color: '#C4CED4', slug: 'sa' },
  TOR: { name: '猛龙', city: '多伦多', color: '#CE1141', slug: 'tor' },
  UTA: { name: '爵士', city: '犹他', color: '#4E9BD6', slug: 'utah' },
  WAS: { name: '奇才', city: '华盛顿', color: '#E31837', slug: 'wsh' }
}

// ESPN 的 standings / scoreboard / 老代码里混用了多套缩写，统一收敛到上面的 key
const ALIASES = {
  GS: 'GSW', GSW: 'GSW',
  NO: 'NOP', NOH: 'NOP', NOP: 'NOP',
  NY: 'NYK', NYK: 'NYK',
  SA: 'SAS', SAS: 'SAS',
  UT: 'UTA', UTAH: 'UTA', UTA: 'UTA',
  WSH: 'WAS', WAS: 'WAS',
  PHO: 'PHX', PHX: 'PHX',
  BRK: 'BKN', BKN: 'BKN',
  CHO: 'CHA', CHA: 'CHA',
  LA: 'LAL'
}

export const normalizeAbbr = (abbr) => {
  if (!abbr) return ''
  const upper = String(abbr).toUpperCase()
  return ALIASES[upper] || upper
}

export const getTeam = (abbr) => TEAMS[normalizeAbbr(abbr)] || null

/** 球队品牌色，未知球队回落到中性灰 */
export const teamColor = (abbr) => getTeam(abbr)?.color || '#8A8F98'

/** 中文队名，未知时原样返回缩写 */
export const teamName = (abbr) => getTeam(abbr)?.name || abbr || '待定'

/** ESPN CDN 上的球队 logo；加载失败时组件会回落到色块缩写 */
export const teamLogo = (abbr) => {
  const team = getTeam(abbr)
  return team ? `https://a.espncdn.com/i/teamlogos/nba/500/${team.slug}.png` : null
}

/** 把 hex 转成 `r, g, b` 字符串，方便在 CSS 里拼 rgba() 做光晕 */
export const teamRgb = (abbr) => {
  const hex = teamColor(abbr).replace('#', '')
  const int = parseInt(hex, 16)
  return `${(int >> 16) & 255}, ${(int >> 8) & 255}, ${int & 255}`
}

export default TEAMS
