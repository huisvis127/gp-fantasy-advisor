const ALLOWED_EVENTS = new Set([
  "app_open",
  "screen_home",
  "screen_analysis",
  "screen_fantasy",
  "screen_fantasy_ideal",
  "screen_fantasy_team",
  "screen_fantasy_history",
  "screen_standings",
  "screen_circuit",
  "screen_league",
  "screen_settings",
  "screen_about",
  "screen_privacy",
  "screen_fantasy_login",
  "analytics_enabled",
  "sync_requested",
  "model_weights_reset",
  "fantasy_login_opened",
  "local_data_deleted",
]);

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === "POST" && url.pathname === "/collect") {
      return collect(request, env);
    }
    if (request.method === "GET" && url.pathname === "/summary") {
      return summary(request, env, url);
    }
    return new Response("Not found", { status: 404 });
  },

  async scheduled(_event, env) {
    await env.DB.prepare(
      "DELETE FROM daily_usage WHERE day < date('now', '-180 days')",
    ).run();
  },
};

async function collect(request, env) {
  if (request.headers.get("content-type")?.split(";")[0] !== "application/json") {
    return json({ error: "invalid_content_type" }, 415);
  }

  let body;
  try {
    body = await request.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }

  if (
    body?.schema !== 1 ||
    !/^\d{4}-\d{2}-\d{2}$/.test(body.day ?? "") ||
    !/^[A-Za-z0-9_-]{16}$/.test(body.daily_id ?? "") ||
    !/^\d+\.\d+\.\d+$/.test(body.app_version ?? "") ||
    !Array.isArray(body.events) ||
    body.events.length > 30
  ) {
    return json({ error: "invalid_payload" }, 400);
  }

  const statements = [];
  for (const item of body.events) {
    if (
      !ALLOWED_EVENTS.has(item?.name) ||
      !Number.isInteger(item?.count) ||
      item.count < 1 ||
      item.count > 10000
    ) {
      return json({ error: "invalid_event" }, 400);
    }
    statements.push(
      env.DB.prepare(
        `INSERT INTO daily_usage(day, daily_id, app_version, event, count)
         VALUES (?, ?, ?, ?, ?)
         ON CONFLICT(day, daily_id, app_version, event)
         DO UPDATE SET count = count + excluded.count`,
      ).bind(
        body.day,
        body.daily_id,
        body.app_version,
        item.name,
        item.count,
      ),
    );
  }

  if (statements.length > 0) await env.DB.batch(statements);
  return new Response(null, { status: 204 });
}

async function summary(request, env, url) {
  const supplied = request.headers.get("authorization");
  if (!env.ADMIN_TOKEN || supplied !== `Bearer ${env.ADMIN_TOKEN}`) {
    return json({ error: "unauthorized" }, 401);
  }

  const requestedDays = Number.parseInt(url.searchParams.get("days") ?? "30", 10);
  const days = Math.min(Math.max(requestedDays || 30, 1), 180);
  const usage = await env.DB.prepare(
    `SELECT day, event, SUM(count) AS count
     FROM daily_usage
     WHERE day >= date('now', ?)
     GROUP BY day, event
     ORDER BY day DESC, count DESC`,
  ).bind(`-${days - 1} days`).all();
  const active = await env.DB.prepare(
    `SELECT day, COUNT(DISTINCT daily_id) AS active_devices
     FROM daily_usage
     WHERE day >= date('now', ?)
     GROUP BY day
     ORDER BY day DESC`,
  ).bind(`-${days - 1} days`).all();

  return json({
    privacy: "Daily identifiers cannot be linked across different days.",
    days,
    active_devices: active.results,
    event_counts: usage.results,
  });
}

function json(value, status = 200) {
  return new Response(JSON.stringify(value), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      "x-content-type-options": "nosniff",
    },
  });
}
