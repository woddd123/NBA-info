import { neon } from '@neondatabase/serverless'

let sqlClient
export function database() {
  if (!process.env.DATABASE_URL) return null
  sqlClient ||= neon(process.env.DATABASE_URL)
  return sqlClient
}

export async function readSnapshot(key) {
  const sql = database()
  if (!sql) return null
  const rows = await sql`SELECT payload, fetched_at FROM api_snapshots WHERE cache_key = ${key} LIMIT 1`
  return rows[0] ?? null
}

export async function writeSnapshot(key, resource, payload) {
  const sql = database()
  if (!sql) return
  await sql`
    INSERT INTO api_snapshots (cache_key, resource, payload, fetched_at)
    VALUES (${key}, ${resource}, ${JSON.stringify(payload)}::jsonb, now())
    ON CONFLICT (cache_key) DO UPDATE
    SET payload = EXCLUDED.payload, resource = EXCLUDED.resource, fetched_at = now()
  `
}

export async function persistGames(payload, beijingDate) {
  const sql = database()
  if (!sql) return
  for (const event of payload.events ?? []) {
    const competition = event.competitions?.[0]
    const home = competition?.competitors?.find(item => item.homeAway === 'home')
    const away = competition?.competitors?.find(item => item.homeAway === 'away')
    if (!home?.team || !away?.team) continue
    await upsertTeam(sql, home.team)
    await upsertTeam(sql, away.team)
    await sql`
      INSERT INTO games (
        external_id, game_date, starts_at, status, status_detail,
        home_team_id, away_team_id, home_score, away_score, raw_payload, updated_at
      ) VALUES (
        ${event.id}, ${beijingDate}, ${event.date || null}, ${event.status?.type?.state || 'pre'},
        ${event.status?.type?.shortDetail || ''}, ${home.team.id}, ${away.team.id},
        ${Number(home.score) || 0}, ${Number(away.score) || 0}, ${JSON.stringify(event)}::jsonb, now()
      )
      ON CONFLICT (external_id) DO UPDATE SET
        status = EXCLUDED.status, status_detail = EXCLUDED.status_detail,
        home_score = EXCLUDED.home_score, away_score = EXCLUDED.away_score,
        raw_payload = EXCLUDED.raw_payload, updated_at = now()
    `
  }
}

export async function persistStandings(payload) {
  const sql = database()
  if (!sql) return
  const season = Number(payload.season?.year) || new Date().getUTCFullYear()
  // 十分钟一个快照，与排名缓存 TTL 对齐，避免同一刷新窗口重复写历史记录。
  const now = new Date()
  const snapshotAt = new Date(Math.floor(now.getTime() / 600_000) * 600_000).toISOString()
  for (const conference of payload.children ?? []) {
    for (const entry of conference.standings?.entries ?? []) {
      if (!entry.team) continue
      await upsertTeam(sql, entry.team)
      const stat = name => entry.stats?.find(item => item.name === name)
      await sql`
        INSERT INTO standings_history
          (season, snapshot_at, conference, team_id, wins, losses, win_percent, streak, raw_payload)
        VALUES
          (${season}, ${snapshotAt}, ${conference.name || ''}, ${entry.team.id},
           ${Number(stat('wins')?.value) || 0}, ${Number(stat('losses')?.value) || 0},
           ${Number(stat('winPercent')?.value) || 0}, ${stat('streak')?.displayValue || ''},
           ${JSON.stringify(entry)}::jsonb)
        ON CONFLICT (season, snapshot_at, team_id) DO NOTHING
      `
    }
  }
}

export async function persistPlayers(players) {
  const sql = database()
  if (!sql || !players.length) return
  await sql`
    INSERT INTO players (external_id, first_name, last_name, position, jersey_number, team_payload, raw_payload, updated_at)
    SELECT input.id, input.first_name, input.last_name, input.position, input.jersey_number,
      input.team, input.raw_payload, now()
    FROM jsonb_to_recordset(${JSON.stringify(players.map(player => ({
      id: String(player.id), first_name: player.first_name || '', last_name: player.last_name || '',
      position: player.position || '', jersey_number: player.jersey_number || '',
      team: player.team ?? {}, raw_payload: player,
    })))}::jsonb) AS input(
      id text, first_name text, last_name text, position text, jersey_number text,
      team jsonb, raw_payload jsonb
    )
    ON CONFLICT (external_id) DO UPDATE SET
      first_name = EXCLUDED.first_name, last_name = EXCLUDED.last_name,
      position = EXCLUDED.position, jersey_number = EXCLUDED.jersey_number,
      team_payload = EXCLUDED.team_payload, raw_payload = EXCLUDED.raw_payload, updated_at = now()
  `
}

export async function persistPlayerStats(season, stats, source = 'balldontlie') {
  const sql = database()
  if (!sql || !stats.length) return
  const rows = stats.map(row => ({
    player_id: String(row.player_id ?? row.player?.id ?? ''),
    stats: row,
  })).filter(row => row.player_id)
  if (!rows.length) return
  await sql`
    INSERT INTO player_season_stats (player_external_id, season, source, stats, updated_at)
    SELECT input.player_id, ${season}, ${source}, input.stats, now()
    FROM jsonb_to_recordset(${JSON.stringify(rows)}::jsonb) AS input(player_id text, stats jsonb)
    ON CONFLICT (player_external_id, season, source) DO UPDATE
    SET stats = EXCLUDED.stats, updated_at = now()
  `
}

async function upsertTeam(sql, team) {
  await sql`
    INSERT INTO teams (external_id, abbreviation, display_name, raw_payload, updated_at)
    VALUES (${String(team.id)}, ${team.abbreviation || ''}, ${team.displayName || ''}, ${JSON.stringify(team)}::jsonb, now())
    ON CONFLICT (external_id) DO UPDATE SET
      abbreviation = EXCLUDED.abbreviation, display_name = EXCLUDED.display_name,
      raw_payload = EXCLUDED.raw_payload, updated_at = now()
  `
}
