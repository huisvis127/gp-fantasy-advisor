import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/localization.dart';

/// Login Plan B (sección 3.1 del plan): el usuario se loguea en la web
/// oficial dentro de un WebView (el anti-bot ve un navegador real) y la app
/// captura el `subscriptionToken` de la sesión.
///
/// La web de F1 guarda tras el login una cookie `login` en .formula1.com
/// cuyo valor es un JSON URL-encoded con `data.subscriptionToken` (documentado
/// por la comunidad; es lo que usan los proyectos f1-fantasy-api). Estrategia:
/// tras CADA página cargada se inspeccionan document.cookie y localStorage
/// buscando `subscriptionToken`. Si no aparece solo, hay botón de captura
/// manual y una barra de estado que dice exactamente qué está pasando
/// (nada de fallos silenciosos).
class FantasyLoginWebViewScreen extends ConsumerStatefulWidget {
  const FantasyLoginWebViewScreen({super.key});

  @override
  ConsumerState<FantasyLoginWebViewScreen> createState() =>
      _FantasyLoginWebViewScreenState();
}

class _FantasyLoginWebViewScreenState
    extends ConsumerState<FantasyLoginWebViewScreen> {
  late final WebViewController _controller;
  bool _tokenCaptured = false;
  bool _showBridgeErrors = false;
  String _status =
      'Inicia sesión con tu cuenta. La app detectará la sesión sola.';

  static const _loginUrl = 'https://fantasy.formula1.com/';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('F1Bridge', onMessageReceived: _onBridgeMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            if (!_tokenCaptured && url.contains('formula1.com')) {
              await _tryCapture(silent: true);
            }
          },
          onUrlChange: (change) {
            final url = change.url ?? '';
            if (!_tokenCaptured && url.contains('fantasy.formula1.com')) {
              Future<void>.delayed(const Duration(seconds: 2), () async {
                if (mounted && !_tokenCaptured) {
                  await _tryCapture(silent: true);
                }
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_loginUrl));
  }

  /// Inspecciona cookies y localStorage de la página actual buscando el
  /// subscriptionToken. Con `silent: false` informa también si no lo halla.
  Future<void> _tryCapture({required bool silent}) async {
    try {
      if (!silent) _showBridgeErrors = true;
      final raw = await _controller.runJavaScriptReturningResult(r'''
(function () {
  var out = { cookie: document.cookie || '', ls: {} };
  try {
    for (var i = 0; i < localStorage.length; i++) {
      var k = localStorage.key(i);
      var v = localStorage.getItem(k) || '';
      if (v.indexOf('subscriptionToken') >= 0 || v.indexOf('SubscriptionToken') >= 0) {
        out.ls[k] = v.substring(0, 4000);
      }
    }
  } catch (e) {}
  return JSON.stringify(out);
})()
''');
      final text = _decodeJsResult(raw.toString());
      final token = _extractToken(text);
      if (token != null && token.length > 20) {
        final auth = ref.read(fantasyAuthServiceProvider);
        await auth.saveExternalToken(token);
        if (mounted) {
          setState(
            () => _status = 'Sesión detectada. Descargando equipo y ligas…',
          );
        }
      }
      await _captureOfficialSnapshot();
      if (!silent && mounted) {
        setState(
          () => _status =
              'Comprobando la sesión con la web oficial. Si acabas de entrar, '
                  'espera unos segundos y vuelve a pulsar "Capturar sesión".',
        );
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(
          () => _status = context.tr('Error: {error}', values: {'error': e}),
        );
      }
    }
  }

  Future<void> _captureOfficialSnapshot() async {
    await _controller.runJavaScript(r'''
(async function () {
  if (window.__f1CompanionCaptureRunning) return;
  window.__f1CompanionCaptureRunning = true;
  try {
    const jsonHeaders = {'Content-Type':'application/json', 'entity':'Wh@t$|_||>'};
    const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
    const readJson = async (url, options) => {
      let lastError = null;
      for (let attempt = 0; attempt < 3; attempt++) {
        try {
          const separator = url.includes('?') ? '&' : '?';
          const freshUrl = url + separator + 'companion=' + Date.now() + '-' + attempt;
          const response = await fetch(freshUrl, Object.assign({
            credentials:'include', cache:'no-store'
          }, options || {}));
          if (!response.ok) throw new Error(url + ' -> ' + response.status);
          const body = await response.json();
          if (body && body.Meta && body.Meta.Success === false) {
            throw new Error(url + ' -> ' + (body.Meta.Message || 'respuesta no válida'));
          }
          return body;
        } catch (error) {
          lastError = error;
          if (attempt < 2) await pause(450 * (attempt + 1));
        }
      }
      throw lastError || new Error('No se pudo leer ' + url);
    };
    const valueOf = value => value && value.Data && value.Data.Value !== undefined
      ? value.Data.Value : (value && value.Value !== undefined
        ? value.Value : (value && value.Data !== undefined ? value.Data : value));
    const firstGuid = node => {
      if (!node) return null;
      if (typeof node === 'string') {
        const match = node.match(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i);
        return match && match[0];
      }
      if (Array.isArray(node)) {
        for (const value of node) {
          const found = firstGuid(value);
          if (found) return found;
        }
        return null;
      }
      if (typeof node === 'object') {
        for (const key of ['GUID','Guid','guid','UserGUID','UserGuid','user_guid','userGuid']) {
          if (node[key]) {
            const found = firstGuid(String(node[key]));
            if (found) return found;
          }
        }
        for (const [key, value] of Object.entries(node)) {
          if (!/user|guid|profile|session/i.test(key)) continue;
          const found = firstGuid(value);
          if (found) return found;
        }
      }
      return null;
    };
    let session = null;
    let guid = null;
    try {
      session = await readJson('/services/session/login', {
        method:'POST', headers:jsonHeaders,
        body:JSON.stringify({optType:1, platformId:1, platformVersion:'1', platformCategory:'web', clientId:1})
      });
      guid = firstGuid(valueOf(session));
    } catch (_) {}
    if (!guid) {
      const stores = [];
      try {
        for (let i = 0; i < localStorage.length; i++) {
          const key = localStorage.key(i);
          if (/user|guid|profile|session|login/i.test(key || '')) {
            stores.push(localStorage.getItem(key) || '');
          }
        }
      } catch (_) {}
      stores.push(document.cookie || '');
      for (const raw of stores) {
        let decoded = raw;
        try { decoded = decodeURIComponent(raw); } catch (_) {}
        if (!/user|guid|profile|session|login/i.test(decoded)) continue;
        guid = firstGuid(decoded);
        if (guid) break;
      }
    }
    if (!guid) throw new Error('Sesión abierta, pero no se encontró el identificador de usuario');

    const schedule = await readJson('/feeds/v2/schedule/raceday_en.json');
    const fixtures = (schedule.Data && schedule.Data.fixtures) || [];
    const current = fixtures.find(x => Number(x.GDIsCurrent) === 1) || fixtures[0] || {};
    const gameDay = Number(current.GamedayId || current.Gameday || 1);
    const teamHistory = await readJson('/services/user/gameplay/' + guid + '/getusergamedaysv1/1');
    const teams = await readJson(
      '/services/user/gameplay/' + guid + '/getteam/1/1/' + gameDay + '/1'
    );
    const leagues = await readJson('/services/user/league/' + guid + '/leaguelandingv1');
    const drivers = await readJson('/feeds/drivers/' + gameDay + '_en.json');

    const findArray = node => {
      if (!node || typeof node !== 'object') return [];
      if (Array.isArray(node)) return node;
      for (const key of ['user_leagues','leaderboard','Details','leagues','Leagues','Value','results','userTeam']) {
        if (Array.isArray(node[key])) return node[key];
      }
      for (const value of Object.values(node)) {
        const found = findArray(value);
        if (found.length) return found;
      }
      return [];
    };
    const allLeagueRows = findArray(valueOf(leagues));
    const numberOf = (row, keys) => {
      for (const key of keys) {
        const value = Number(row && row[key]);
        if (Number.isFinite(value) && value > 0) return value;
      }
      return 0;
    };
    const isPrivateLeague = league => {
      const explicitPrivate = Number(league.IsPrivateLeague || league.IsPrivate || league.isPrivate || 0) === 1;
      const explicitGlobal = Number(league.IsGlobalLeague || league.IsGlobal || league.isGlobal || 0) === 1;
      const type = String(league.league_type || league.LeagueType || league.Type || league.type || '').toLowerCase();
      return explicitPrivate || (!explicitGlobal && type === 'private');
    };
    const leagueRows = allLeagueRows.filter(league => {
      const count = numberOf(league, ['member_count','MemberCount','MembersCount','TotalMembers','EntryCount','LeagueSize']);
      return isPrivateLeague(league) && (count === 0 || count <= 20);
    });
    const playerRows = findArray(valueOf(drivers));
    const playersById = new Map();
    for (const player of playerRows) {
      const id = String(player.PlayerId || player.playerId || player.id || '');
      if (id) playersById.set(id, player);
    }
    const normalizedPlayers = roster => {
      const rows = findArray(valueOf(roster));
      const team = rows[0] || {};
      const ids = Array.isArray(team.playerid) ? team.playerid : [];
      return ids.map(pick => {
        const id = String((pick && (pick.id || pick.PlayerId)) || pick || '');
        const player = playersById.get(id) || {};
        return {
          id:id,
          display_name:player.DisplayName || player.FUllName || player.FullName || player.TeamName || ('#' + id),
          position_name:player.PositionName || '',
          team_name:player.TeamName || '',
          is_captain:Number(pick && pick.iscaptain || 0) === 1,
          is_megacaptain:Number(pick && pick.ismgcaptain || 0) === 1
        };
      });
    };
    const firstValue = (row, keys) => {
      if (!row || typeof row !== 'object') return null;
      const wanted = new Set(keys.map(key => String(key).toLowerCase().replace(/[^a-z0-9]/g, '')));
      for (const [key, value] of Object.entries(row)) {
        const normalized = String(key).toLowerCase().replace(/[^a-z0-9]/g, '');
        if (wanted.has(normalized) && value !== undefined && value !== null) return value;
      }
      for (const value of Object.values(row)) {
        if (value && typeof value === 'object') {
          const found = firstValue(value, keys);
          if (found !== null) return found;
        }
      }
      return null;
    };
    const usedChips = history => {
      const value = valueOf(history) || {};
      const definitions = [
        ['wildcard', ['isWildcardtaken','iswildcardtaken'], ['wildCardtakengd','wildcardtakengd']],
        ['limitless', ['isLimitlesstaken','islimitlesstaken'], ['limitLesstakengd','limitlesstakengd']],
        ['final_fix', ['isFinalfixtaken','isfinalfixtaken'], ['finalFixtakengd','finalfixtakengd']],
        ['triple_boost', ['isExtradrstaken','isextradrstaken'], ['extraDrstakengd','extradrstakengd']],
        ['no_negative', ['isNonigativetaken','isnonigativetaken'], ['noNigativetakengd','nonigativetakengd']],
        ['autopilot', ['isAutopilottaken','isautopilottaken'], ['isAutopilottakengd','autopilottakengd']]
      ];
      return definitions
        .filter(item => Number(firstValue(value, item[1]) || 0) === 1)
        .map(item => ({name:item[0], round:Number(firstValue(value, item[2]) || 0)}));
    };
    const leaderboards = {};
    for (const league of leagueRows) {
      const id = league.league_id || league.LeagueId || league.LeagueID || league.id;
      if (!id) continue;
      try {
        const rounds = {};
        const currentBoard = await readJson(
          '/feeds/leaderboard/privateleague/list_1_' + id + '_0_1.json'
        );

        const memberTeams = {};
        const currentRows = findArray(valueOf(currentBoard));
        for (const member of currentRows.slice(0, 20)) {
          const memberGuid = member.user_guid || member.UserGuid || member.UserGUID || member.guid || '';
          if (!memberGuid) continue;
          try {
            const history = await readJson(
              '/services/user/opponentteam/opponentgamedayget/1/' + memberGuid + '/1'
            );
            let roster = null;
            try {
              roster = await readJson(
                '/services/user/opponentteam/opponentgamedayplayerteamget/1/' + memberGuid + '/1/' + gameDay + '/1'
              );
            } catch (_) {
              for (let round = gameDay - 1; round >= 1 && !roster; round--) {
                try {
                  roster = await readJson(
                    '/services/user/opponentteam/opponentgamedayplayerteamget/1/' + memberGuid + '/1/' + round + '/1'
                  );
                } catch (_) {}
              }
            }
            memberTeams[String(memberGuid)] = {
              history:history,
              roster:roster,
              players:normalizedPlayers(roster),
              chipsUsed:usedChips(history)
            };
          } catch (_) {}
        }
        const cumulative = new Map();
        for (let round = 1; round <= gameDay; round++) {
          const eventRows = currentRows.map(member => {
            const memberGuid = String(member.user_guid || member.UserGuid || member.UserGUID || member.guid || '');
            const teamData = memberTeams[memberGuid] || {};
            const historyValue = valueOf(teamData.history) || {};
            const details = historyValue.mdDetails || historyValue.MdDetails || {};
            const detail = details[String(round)] || details[round] || {};
            const eventPoints = Number(detail.pts || detail.Points || 0);
            const total = (cumulative.get(memberGuid) || 0) + eventPoints;
            cumulative.set(memberGuid, total);
            return {...member, event_points:eventPoints, cumulative_points:total, _has_event:Object.keys(detail).length > 0};
          });
          if (!eventRows.some(row => row._has_event)) continue;
          const byEvent = [...eventRows].sort((a,b) => b.event_points - a.event_points);
          const eventRank = new Map(byEvent.map((row,index) => [String(row.user_guid || row.UserGuid || row.guid || ''), index + 1]));
          const byTotal = [...eventRows].sort((a,b) => b.cumulative_points - a.cumulative_points);
          const totalRank = new Map(byTotal.map((row,index) => [String(row.user_guid || row.UserGuid || row.guid || ''), index + 1]));
          rounds[String(round)] = {Value:{leaderboard:eventRows.map(row => {
            const key = String(row.user_guid || row.UserGuid || row.guid || '');
            return {...row, points:row.event_points, rank:totalRank.get(key), race_rank:eventRank.get(key)};
          })}};
        }
        leaderboards[String(id)] = {current:currentBoard, rounds:rounds, teams:memberTeams};
      } catch (_) {}
    }
    if (leagueRows.length > 0 && Object.keys(leaderboards).length === 0) {
      throw new Error('La web devolvió las ligas, pero no sus clasificaciones');
    }
    F1Bridge.postMessage(JSON.stringify({
      capturedAt:new Date().toISOString(), guid:guid, gameDay:gameDay,
      session:session, teams:teams, teamHistory:teamHistory,
      leagues:leagues, leaderboards:leaderboards
    }));
  } catch (error) {
    F1Bridge.postMessage(JSON.stringify({error:String(error && error.message || error)}));
  } finally {
    window.__f1CompanionCaptureRunning = false;
  }
})()
''');
  }

  Future<void> _onBridgeMessage(JavaScriptMessage message) async {
    try {
      final decoded = jsonDecode(message.message);
      if (decoded is Map && decoded['error'] != null) {
        if (mounted) {
          final detail = decoded['error'].toString();
          setState(
            () => _status = _showBridgeErrors
                ? 'No se pudo sincronizar: $detail'
                : 'La sesión todavía no está lista. Esperando a la web oficial…',
          );
        }
        return;
      }
      final auth = ref.read(fantasyAuthServiceProvider);
      await auth.saveSessionSnapshot(message.message);
      _tokenCaptured = true;
      _showBridgeErrors = false;
      if (mounted) {
        setState(() => _status = 'Equipo y ligas sincronizados correctamente.');
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _status = context.tr('Error: {error}', values: {'error': error}),
        );
      }
    }
  }

  /// runJavaScriptReturningResult devuelve el JSON con comillas escapadas
  /// según plataforma; se decodifica de forma tolerante.
  String _decodeJsResult(String raw) {
    var text = raw;
    for (var i = 0; i < 2; i++) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is String) {
          text = decoded;
          continue;
        }
        return jsonEncode(decoded);
      } catch (_) {
        break;
      }
    }
    return text;
  }

  String? _extractToken(String haystack) {
    // El valor puede venir URL-encoded (cookie) y/o con comillas escapadas.
    var text = haystack;
    try {
      text = Uri.decodeFull(text);
    } catch (_) {}
    text = text.replaceAll(r'\"', '"');
    final match =
        RegExp('"subscriptionToken"\\s*:\\s*"([^"]+)"').firstMatch(text) ??
            RegExp('subscriptionToken=([A-Za-z0-9._-]+)').firstMatch(text);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Iniciar sesión (navegador)'))),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: AppColors.surface2,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr(_status),
                    style: AppText.body(12, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _tryCapture(silent: false),
                  child: Text(context.tr('CAPTURAR SESIÓN')),
                ),
              ],
            ),
          ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
