export function json(res, status, body, headers = {}) {
  res.statusCode = status
  res.setHeader('Content-Type', 'application/json; charset=utf-8')
  res.setHeader('Cache-Control', 'private, no-store')
  for (const [key, value] of Object.entries(headers)) res.setHeader(key, value)
  res.end(JSON.stringify(body))
}

export function methodNotAllowed(res) {
  return json(res, 405, { error: 'method_not_allowed' }, { Allow: 'GET' })
}

export function queryValue(value, fallback = '') {
  return Array.isArray(value) ? value[0] : value ?? fallback
}

export function boundedInt(value, fallback, min, max) {
  const parsed = Number.parseInt(queryValue(value), 10)
  return Number.isFinite(parsed) ? Math.min(max, Math.max(min, parsed)) : fallback
}

export async function fetchJSON(url, options = {}) {
  const controller = new AbortController()
  const timer = setTimeout(() => controller.abort(), options.timeout ?? 10_000)
  try {
    const response = await fetch(url, {
      headers: { Accept: 'application/json', ...options.headers },
      signal: controller.signal,
    })
    if (!response.ok) throw new Error(`upstream_${response.status}`)
    return await response.json()
  } finally {
    clearTimeout(timer)
  }
}

export function beijingDateKey(date = new Date()) {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Shanghai', year: 'numeric', month: '2-digit', day: '2-digit',
  }).format(date)
}

export function espnDateKey(beijingDate) {
  const [year, month, day] = beijingDate.split('-').map(Number)
  const utc = new Date(Date.UTC(year, month - 1, day) - 8 * 60 * 60 * 1000)
  return `${utc.getUTCFullYear()}${String(utc.getUTCMonth() + 1).padStart(2, '0')}${String(utc.getUTCDate()).padStart(2, '0')}`
}
