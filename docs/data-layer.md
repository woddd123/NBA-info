# NBAASS 数据层

客户端统一调用 `/api/v1`。读取顺序为 Redis → PostgreSQL（历史不可变数据或第三方异常兜底）→ ESPN / BallDontLie。第三方成功响应会同步写入 PostgreSQL 快照、业务表和 Redis。

## 环境变量

复制 `.env.example` 并在 Vercel 项目中配置：

- `DATABASE_URL`: Neon PostgreSQL 连接串。
- `UPSTASH_REDIS_REST_URL`、`UPSTASH_REDIS_REST_TOKEN`: Upstash Redis REST 凭证（也兼容 Vercel KV 的 `KV_REST_API_*` 名称）。
- `BALLDONTLIE_API_KEY`: 服务端球员数据凭证。
- `CRON_SECRET`: Vercel Cron 请求校验密钥。

## 初始化

1. 在 Neon SQL Editor 执行 `db/migrations/001_initial.sql`。
2. 在 Vercel 配置以上环境变量。
3. 部署项目，检查 `/api/v1/games?date=2026-08-12` 和 `/api/v1/standings`。
4. 将 iOS 主程序和 Widget Target 的 `NBAASS_API_BASE` 设置为 `https://你的域名/api/v1`。
5. 如果部署计划支持高频 Cron，再为 `/api/cron/sync` 配置每 5～10 分钟触发；未配置时仍会在客户端请求时刷新。

没有 Redis 或 PostgreSQL 时，API 会退化为直接请求第三方；没有 BallDontLie Key 时，球员接口返回 503，但赛事接口不受影响。

## 接口

- `GET /api/v1/games?date=YYYY-MM-DD`
- `GET /api/v1/standings`
- `GET /api/v1/players?page=0&per_page=25`
- `GET /api/v1/player?id=PLAYER_ID`
- `GET /api/v1/player-stats?season=2025&player_ids=1,2`

响应头 `X-Data-Source` 会显示 `redis`、`database` 或 `upstream`；`X-Data-Stale: true` 表示第三方失败后返回了数据库里的最后可用数据。

## 缓存与持久化

- 实时比赛：Redis 20 秒。
- 今日比赛：Redis 3 分钟；数据库持续更新。
- 未来赛程：Redis 15 分钟。
- 历史赛程：数据库永久保存，Redis 作为热缓存。
- 排名：Redis 10 分钟，每次回源写入历史快照。
- 球员列表：Redis 1 小时，数据库持久化。
- 球员资料：Redis 24 小时，数据库持久化。
- 赛季数据：Redis 6 小时，按球员和赛季持久化。
