export const formatDate = (date, format = 'YYYY-MM-DD') => {
  const d = new Date(date)
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

// 获取今天 
// ESPN 的 scoreboard 接口的 dates 参数虽然是美国当地时间，
// 但其实我们只需直接传中国当天的日期（例如中国4月4日，传 20260404），
// ESPN 接口会自动返回转换为当地对应日期的赛事（也就是包含美国4月3日晚上到4月4日凌晨的比赛）。
// 因此我们不需要再做 -24 或 -12 小时的偏移，直接传本地当天的日期即可与国内体育平台对齐。
export const getToday = () => {
  const d = new Date()
  return formatDate(d, 'YYYY-MM-DD')
}

// 获取指定日期的偏移日期 (比如昨天、明天)
export const getOffsetDate = (dateStr, offsetDays) => {
  const d = new Date(dateStr)
  d.setDate(d.getDate() + offsetDays)
  return formatDate(d, 'YYYY-MM-DD')
}
