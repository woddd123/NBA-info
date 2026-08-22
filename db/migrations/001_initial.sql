CREATE TABLE IF NOT EXISTS api_snapshots (
  cache_key text PRIMARY KEY,
  resource text NOT NULL,
  payload jsonb NOT NULL,
  fetched_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS teams (
  external_id text PRIMARY KEY,
  abbreviation text NOT NULL,
  display_name text NOT NULL,
  raw_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS games (
  external_id text PRIMARY KEY,
  game_date date NOT NULL,
  starts_at timestamptz,
  status text NOT NULL,
  status_detail text NOT NULL DEFAULT '',
  home_team_id text NOT NULL REFERENCES teams(external_id),
  away_team_id text NOT NULL REFERENCES teams(external_id),
  home_score integer NOT NULL DEFAULT 0,
  away_score integer NOT NULL DEFAULT 0,
  raw_payload jsonb NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS games_date_idx ON games (game_date);
CREATE INDEX IF NOT EXISTS games_status_idx ON games (status);

CREATE TABLE IF NOT EXISTS standings_history (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  season integer NOT NULL,
  snapshot_at timestamptz NOT NULL,
  conference text NOT NULL,
  team_id text NOT NULL REFERENCES teams(external_id),
  wins integer NOT NULL,
  losses integer NOT NULL,
  win_percent numeric(6,5) NOT NULL,
  streak text NOT NULL DEFAULT '',
  raw_payload jsonb NOT NULL,
  UNIQUE (season, snapshot_at, team_id)
);
CREATE INDEX IF NOT EXISTS standings_season_idx ON standings_history (season, snapshot_at DESC);

CREATE TABLE IF NOT EXISTS players (
  external_id text PRIMARY KEY,
  first_name text NOT NULL,
  last_name text NOT NULL,
  position text NOT NULL DEFAULT '',
  jersey_number text NOT NULL DEFAULT '',
  team_payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  raw_payload jsonb NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS player_season_stats (
  player_external_id text NOT NULL,
  season integer NOT NULL,
  source text NOT NULL,
  stats jsonb NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (player_external_id, season, source)
);
