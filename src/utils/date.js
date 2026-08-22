export const formatDate = (date, format = 'YYYY-MM-DD') => {
  const d = date instanceof Date ? date : parseDate(date)
  const year = d.getFullYear()
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  const hours = String(d.getHours()).padStart(2, '0')
  const minutes = String(d.getMinutes()).padStart(2, '0')

  return format
    .replace('YYYY', year)
    .replace('MM', month)
    .replace('DD', day)
    .replace('HH', hours)
    .replace('mm', minutes)
}

// 'YYYY-MM-DD' 交给 new Date() 会按 UTC 午夜解析，在东八区之外会整体偏一天，
// 这里显式按本地时间构造。
export const parseDate = (value) => {
  if (value instanceof Date) return new Date(value)
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(value))
  if (!m) return new Date(value)
  return new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]))
}

// 获取今天
// ESPN 的 scoreboard 接口的 dates 参数虽然是美国当地时间，
// 但其实我们只需直接传中国当天的日期（例如中国4月4日，传 20260404），
// ESPN 接口会自动返回转换为当地对应日期的赛事（也就是包含美国4月3日晚上到4月4日凌晨的比赛）。
// 因此我们不需要再做 -24 或 -12 小时的偏移，直接传本地当天的日期即可与国内体育平台对齐。
export const getToday = () => formatDate(new Date(), 'YYYY-MM-DD')

// 获取指定日期的偏移日期 (比如昨天、明天)
export const getOffsetDate = (dateStr, offsetDays) => {
  const d = parseDate(dateStr)
  d.setDate(d.getDate() + offsetDays)
  return formatDate(d, 'YYYY-MM-DD')
}

const WEEKDAYS = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']

export const weekdayLabel = (dateStr) => WEEKDAYS[parseDate(dateStr).getDay()]

export const dayOfMonth = (dateStr) => parseDate(dateStr).getDate()

/** 以 anchor 为中心、前后各 span 天的日期数组，用于首页日期条 */
export const dateStrip = (anchor, span = 3) =>
  Array.from({ length: span * 2 + 1 }, (_, i) => getOffsetDate(anchor, i - span))
