const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');

const dartPath = path.resolve(
  __dirname,
  '../../lib/ui/screens/login/fantasy_login_webview_screen.dart',
);
const dartSource = fs.readFileSync(dartPath, 'utf8');
const invocation = "await _controller.runJavaScript(r'''";
const captureMethodIndex = dartSource.indexOf('Future<void> _captureOfficialSnapshot()');
assert.notEqual(captureMethodIndex, -1, 'capture method exists');
const invocationIndex = dartSource.indexOf(invocation, captureMethodIndex);
assert.notEqual(invocationIndex, -1, 'capture script invocation exists');
const scriptStart = invocationIndex + invocation.length;
const scriptEnd = dartSource.indexOf("''');", scriptStart);
assert.notEqual(scriptEnd, -1, 'capture script terminator exists');
const captureScript = dartSource.slice(scriptStart, scriptEnd);

const fixtures = [
  {
    GamedayId: 1,
    GamedayName: 'Round 1',
    GDIsLocked: 1,
    SessionType: 'race',
    PhaseId: 1,
  },
  {
    GamedayId: 2,
    GamedayName: 'Round 2',
    GDIsCurrent: 1,
    GDIsLocked: 1,
    SessionType: 'race',
    PhaseId: 1,
  },
];

function memberRows(count) {
  return Array.from({ length: count }, (_, index) => ({
    yUserGuid: index === 0 ? 'self' : `user-${index}`,
    teamNo: 1,
    userRank: index + 1,
  }));
}

async function capture({
  leagues,
  requestedId,
  boardSizes = {},
  boardReportedSizes = {},
  malformedBoards = [],
  boardDelayMs = 0,
}) {
  const calls = [];
  let historyInFlight = 0;
  let maxHistoryInFlight = 0;
  let posted;
  const context = {
    window: { f1RequestedLeagueId: requestedId },
    F1Bridge: {
      postMessage(message) {
        posted = JSON.parse(message);
      },
    },
    fetch: async (url) => {
      const pathname = String(url);
      calls.push(pathname);
      if (pathname.includes('/feeds/leaderboard/privateleague/list_2_')) {
        historyInFlight++;
        maxHistoryInFlight = Math.max(maxHistoryInFlight, historyInFlight);
        await new Promise((resolve) => setTimeout(resolve, 2));
        historyInFlight--;
      }
      if (pathname.includes('/feeds/leaderboard/privateleague/list_1_')) {
        if (boardDelayMs) {
          await new Promise((resolve) => setTimeout(resolve, boardDelayMs));
        }
        const leagueId = pathname.match(/list_1_(.+?)_0_1\.json/)[1];
        if (malformedBoards.includes(leagueId)) {
          return jsonResponse({ Data: { Value: { status: 'unexpected-shape' } } });
        }
        const value = { userRank: memberRows(boardSizes[leagueId] ?? 2) };
        if (boardReportedSizes[leagueId] !== undefined) {
          value.total_records = boardReportedSizes[leagueId];
        }
        return jsonResponse({
          Data: { Value: value },
        });
      }
      if (pathname.startsWith('/services/session/login')) {
        return jsonResponse({ Data: { Value: { GUID: 'self' } } });
      }
      if (pathname.startsWith('/feeds/v2/schedule/')) {
        return jsonResponse({ Data: { fixtures } });
      }
      if (pathname.includes('/getusergamedaysv1/')) {
        return jsonResponse({
          Data: {
            Value: [
              { teamno: 1, cugdid: 2, mddetails: { '2': { phId: 1 } } },
            ],
          },
        });
      }
      if (pathname.includes('/leaguelandingv1')) {
        return jsonResponse({ Data: { Value: leagues } });
      }
      if (pathname.includes('/getteam/') || pathname.includes('/opponentteam/')) {
        return jsonResponse({ Data: { Value: { userTeam: [{ driverId: 'd1' }] } } });
      }
      if (pathname.includes('/list_2_')) {
        return jsonResponse({ Data: { Value: { userRank: [] } } });
      }
      throw new Error(`Unexpected fetch: ${pathname}`);
    },
  };

  await vm.runInNewContext(captureScript, context, { timeout: 5000 });
  assert.ok(posted, 'capture script posts its snapshot');
  return { posted, calls, maxHistoryInFlight };
}

function jsonResponse(body) {
  return {
    ok: true,
    status: 200,
    async json() {
      return body;
    },
  };
}

test('known oversized requested league is marked blocked before board/history/team requests', async () => {
  const { posted, calls } = await capture({
    requestedId: 'large',
    leagues: [
      { LeagueId: 'large', LeagueType: 'private', TeamCount: 21, MaxTeams: 50 },
      { LeagueId: 'small', LeagueType: 'private', TeamCount: 2 },
    ],
  });

  assert.deepEqual(posted.leagueAccess.large, { teamCount: 21, blocked: true });
  assert.deepEqual(posted.leaderboards, {});
  assert.deepEqual(posted.leagueHistory, {});
  assert.deepEqual(posted.leagueTeamDetails, {});
  assert.equal(calls.some((url) => url.includes('list_1_large_')), false);
  assert.equal(calls.some((url) => url.includes('list_2_large_')), false);
  assert.equal(calls.some((url) => url.includes('/opponentteam/')), false);
  assert.equal(calls.some((url) => url.includes('list_1_small_')), false);
});

test('unknown size is checked from one board and oversized league data is not cached', async () => {
  const { posted, calls } = await capture({
    requestedId: 'unknown',
    boardSizes: { unknown: 20 },
    boardReportedSizes: { unknown: 21 },
    leagues: [{ LeagueId: 'unknown', LeagueType: 'private', MaxTeams: 100 }],
  });

  assert.deepEqual(posted.leagueAccess.unknown, { teamCount: 21, blocked: true });
  assert.deepEqual(posted.leaderboards, {});
  assert.deepEqual(posted.leagueHistory, {});
  assert.deepEqual(posted.leagueTeamDetails, {});
  assert.equal(calls.filter((url) => url.includes('list_1_unknown_')).length, 1);
  assert.equal(calls.some((url) => url.includes('list_2_unknown_')), false);
  assert.equal(calls.some((url) => url.includes('/opponentteam/')), false);
});

test('nested board total overrides a first page of only twenty entries', async () => {
  const { posted, calls } = await capture({
    requestedId: 'paged',
    boardSizes: { paged: 20 },
    boardReportedSizes: { paged: 5000 },
    leagues: [{ LeagueId: 'paged', LeagueType: 'private' }],
  });

  assert.deepEqual(posted.leagueAccess.paged, { teamCount: 5000, blocked: true });
  assert.deepEqual(posted.leaderboards, {});
  assert.deepEqual(posted.leagueHistory, {});
  assert.deepEqual(posted.leagueTeamDetails, {});
  assert.equal(calls.filter((url) => url.includes('list_1_paged_')).length, 1);
  assert.equal(calls.some((url) => url.includes('list_2_paged_')), false);
  assert.equal(calls.some((url) => url.includes('/opponentteam/')), false);
});

test('captures only the requested permitted league with bounded sequential history', async () => {
  const { posted, calls, maxHistoryInFlight } = await capture({
    requestedId: 'selected',
    boardSizes: { selected: 2, other: 3 },
    leagues: [
      { LeagueId: 'other', LeagueType: 'private', TeamCount: 3 },
      { LeagueId: 'selected', LeagueType: 'private', TeamCount: 2 },
    ],
  });

  assert.deepEqual(posted.leagueAccess.selected, { teamCount: 2, blocked: false });
  assert.deepEqual(posted.leagueAccess.other, { teamCount: 3, blocked: false });
  assert.ok(posted.leaderboards.selected);
  assert.equal(posted.leaderboards.other, undefined);
  assert.ok(posted.leagueHistory.selected);
  assert.equal(posted.leagueHistory.other, undefined);
  assert.equal(calls.some((url) => url.includes('list_1_other_')), false);
  assert.equal(calls.some((url) => url.includes('list_2_other_')), false);
  assert.equal(calls.filter((url) => url.includes('list_2_selected_')).length, 2);
  assert.equal(maxHistoryInFlight, 1);
});

test('blocked selected league does not fall back to another allowed league', async () => {
  const { posted, calls } = await capture({
    requestedId: 'large',
    leagues: [
      { LeagueId: 'large', LeagueType: 'private', MemberCount: 30 },
      { LeagueId: 'allowed', LeagueType: 'private', MemberCount: 2 },
    ],
  });

  assert.equal(posted.error, undefined);
  assert.deepEqual(posted.leagueAccess.large, { teamCount: 30, blocked: true });
  assert.equal(calls.some((url) => url.includes('list_1_allowed_')), false);
  assert.equal(calls.some((url) => url.includes('list_2_allowed_')), false);
  assert.deepEqual(posted.leaderboards, {});
});

test('unverifiable board fails visibly without requesting history or opponent teams', async () => {
  const { posted, calls } = await capture({
    requestedId: 'unknown-shape',
    malformedBoards: ['unknown-shape'],
    leagues: [
      { LeagueId: 'unknown-shape', LeagueType: 'private', TeamCount: 4 },
    ],
  });

  assert.equal(posted.errorStage, 'league');
  assert.match(posted.error, /verificar el tamaño/);
  assert.equal(posted.teams, undefined);
  assert.equal(calls.some((url) => url.includes('list_2_unknown-shape_')), false);
  assert.equal(calls.some((url) => url.includes('/opponentteam/')), false);
});
