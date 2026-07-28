CREATE TABLE IF NOT EXISTS daily_usage (
  day TEXT NOT NULL,
  daily_id TEXT NOT NULL,
  app_version TEXT NOT NULL,
  event TEXT NOT NULL,
  count INTEGER NOT NULL CHECK (count > 0),
  PRIMARY KEY (day, daily_id, app_version, event)
);

CREATE INDEX IF NOT EXISTS daily_usage_day_event
  ON daily_usage(day, event);
