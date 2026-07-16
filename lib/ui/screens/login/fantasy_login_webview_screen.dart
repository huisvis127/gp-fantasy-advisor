import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';

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
      ..addJavaScriptChannel(
        'F1Bridge',
        onMessageReceived: _onBridgeMessage,
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) async {
          await _fitPageToPhone();
          if (!_tokenCaptured && url.contains('formula1.com')) {
            await _tryCapture(silent: true);
          }
        },
      ))
      ..loadRequest(Uri.parse(_loginUrl));
  }

  /// Keeps a mobile viewport without applying CSS scaling: scaling the root
  /// element makes Android WebView hit targets drift away from their visuals.
  Future<void> _fitPageToPhone() async {
    try {
      await _controller.runJavaScript(r'''
(function () {
  var viewport = document.querySelector('meta[name="viewport"]');
  if (!viewport) {
    viewport = document.createElement('meta');
    viewport.name = 'viewport';
    document.head.appendChild(viewport);
  }
  viewport.content = 'width=device-width, initial-scale=1, maximum-scale=5, user-scalable=yes';
})()
''');
    } catch (_) {
      // Some intermediate identity pages block injected scripts.
    }
  }

  /// Inspecciona cookies y localStorage de la página actual buscando el
  /// subscriptionToken. Con `silent: false` informa también si no lo halla.
  Future<void> _tryCapture({required bool silent}) async {
    try {
      if (!silent) _showBridgeErrors = true;
      final currentUrl = await _controller.currentUrl();
      final currentHost = Uri.tryParse(currentUrl ?? '')?.host;
      if (currentHost != Uri.parse(_loginUrl).host) {
        if (!silent) {
          await _controller.loadRequest(Uri.parse(_loginUrl));
          if (mounted) {
            setState(() => _status =
                'Volviendo a F1 Fantasy. Espera a ver tu cuenta y pulsa Capturar.');
          }
        }
        return;
      }
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
          setState(() => _status =
              'Cuenta detectada. Pulsa Capturar para copiar equipo y ligas.');
        }
      }
      // La web recarga varias veces durante y después del login. No debemos
      // capturar ni cerrar el navegador desde onPageFinished: en ese momento
      // la sesión privada puede existir pero equipo y ligas aún no estar listos.
      if (silent) return;
      await _captureOfficialSnapshot();
      if (!silent && mounted) {
        setState(() => _status =
            'Comprobando la sesión con la web oficial. Si acabas de entrar, '
                'espera unos segundos y vuelve a pulsar "Capturar sesión".');
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(() => _status = 'Error al inspeccionar la página: $e');
      }
    }
  }

  Future<void> _captureOfficialSnapshot() async {
    await _controller.runJavaScript(r'''
(async function () {
  let stage = 'session';
  try {
    const headers = {'Content-Type':'application/json', 'entity':'Wh@t$|_||>'};
    const readJson = async (url, options) => {
      const response = await fetch(url, Object.assign({credentials:'include', headers:headers}, options || {}));
      if (!response.ok) throw new Error('HTTP ' + response.status);
      return await response.json();
    };
    const valueOf = value => value && value.Data && value.Data.Value !== undefined
      ? value.Data.Value : (value && value.Data !== undefined ? value.Data : value);
    const session = await readJson('/services/session/login', {
      method:'POST',
      body:JSON.stringify({optType:1, platformId:1, platformVersion:'1', platformCategory:'web', clientId:1})
    });
    const sessionValue = valueOf(session) || {};
    const guid = sessionValue.GUID || sessionValue.Guid || sessionValue.guid || sessionValue.UserGuid;
    if (!guid) throw new Error('Sesión abierta, pero no llegó el identificador de usuario');

    stage = 'schedule';
    const schedule = await readJson('/feeds/v2/schedule/raceday_en.json');
    const fixtures = (schedule.Data && schedule.Data.fixtures) || [];
    const current = fixtures.find(x => Number(x.GDIsCurrent) === 1) || fixtures[0] || {};
    const gameDay = Number(current.GamedayId || current.Gameday || 1);
    const schedulePhaseId = Number(current.PhaseId || current.PhaseID || current.phaseId || 1);
    stage = 'teams';
    const teams = await readJson('/services/user/gameplay/' + guid + '/getusergamedaysv1/1');
    stage = 'leagues';
    const leagues = await readJson('/services/user/league/' + guid + '/getuserleague/1');

    const findArray = node => {
      if (!node || typeof node !== 'object') return [];
      if (Array.isArray(node)) return node;
      for (const key of ['Details','leagues','Leagues','leaguesdata','Value','results']) {
        if (Array.isArray(node[key])) return node[key];
      }
      for (const value of Object.values(node)) {
        const found = findArray(value);
        if (found.length) return found;
      }
      return [];
    };
    const teamRows = findArray(valueOf(teams));
    const teamDetails = {};
    const teamDetailErrors = [];
    for (const team of teamRows.slice(0, 3)) {
      const teamNo = Number(team.teamno || team.teamNo || team.teanNo || 1);
      const md = team.mddetails || {};
      const primaryDay = Number(team.cugdid) || gameDay;
      const primaryInfo = md[String(primaryDay)] || md[primaryDay] || {};
      const candidates = [
        {day:primaryDay, phase:Number(primaryInfo.phId || primaryInfo.phaseId || schedulePhaseId || 1)},
        ...Object.entries(md).reverse().map(([key, info]) => ({
          day:Number(key),
          phase:Number((info || {}).phId || (info || {}).phaseId || schedulePhaseId || 1)
        })),
        ...fixtures.slice().reverse().map(fixture => ({
          day:Number(fixture.GamedayId || fixture.Gameday),
          phase:Number(fixture.PhaseId || fixture.PhaseID || 1)
        }))
      ];
      const seen = new Set();
      for (const candidate of candidates) {
        const candidateKey = candidate.day + ':' + candidate.phase;
        if (!candidate.day || !candidate.phase || seen.has(candidateKey)) continue;
        seen.add(candidateKey);
        try {
          const detail = await readJson(
            '/services/user/gameplay/' + guid + '/getteam/1/' + teamNo + '/' + candidate.day + '/' + candidate.phase
          );
          const detailValue = valueOf(detail) || {};
          if (Array.isArray(detailValue.userTeam) &&
              detailValue.userTeam.length > 0) {
            teamDetails[String(teamNo)] = detail;
            break;
          }
        } catch (error) {
          teamDetailErrors.push(String(error && error.message || error));
        }
      }
      if (!teamDetails[String(teamNo)]) {
        teamDetailErrors.push('NO_TEAM_DATA');
      }
    }
    const leagueRows = findArray(valueOf(leagues));
    const eventsByDay = new Map();
    for (const fixture of fixtures) {
      const day = Number(fixture.GamedayId || fixture.Gameday);
      if (!day || day > gameDay) continue;
      const label = fixture.GamedayName || fixture.RaceDayName ||
        fixture.MeetingName || fixture.CircuitName || fixture.CountryName ||
        fixture.EventName || fixture.Name || ('R' + day);
      const isComplete = Number(fixture.GDIsLocked) === 1 &&
        String(fixture.SessionType || '').toLowerCase() === 'race';
      if (!eventsByDay.has(day)) {
        eventsByDay.set(day, {gameDayId:day, label:String(label), isComplete:isComplete});
      } else if (isComplete) {
        eventsByDay.get(day).isComplete = true;
      }
    }
    if (!eventsByDay.has(gameDay)) {
      eventsByDay.set(gameDay, {gameDayId:gameDay, label:'R' + gameDay, isComplete:false});
    }
    const leagueEvents = Array.from(eventsByDay.values())
      .sort((a, b) => a.gameDayId - b.gameDayId)
      .slice(-24);
    const leaderboards = {};
    const leagueHistory = {};
    for (const league of leagueRows.slice(0, 20)) {
      const id = league.LeagueId || league.LeagueID || league.leagueId || league.league_id || league.id;
      if (!id) continue;
      const h2h = Number(league.IsHTHLeague || league.isHTHLeague || 0);
      const history = {};
      await Promise.all(leagueEvents.map(async event => {
        try {
          const board = await readJson(
            '/services/user/league/' + guid + '/getuserleaguemembers/1/' + id + '/' + h2h + '/' + event.gameDayId + '/1/100/'
          );
          history[String(event.gameDayId)] = board;
          if (event.gameDayId === gameDay) leaderboards[String(id)] = board;
        } catch (_) {}
      }));
      leagueHistory[String(id)] = history;
      if (!leaderboards[String(id)]) {
        const days = Object.keys(history).sort((a, b) => Number(a) - Number(b));
        if (days.length) leaderboards[String(id)] = history[days[days.length - 1]];
      }
    }
    F1Bridge.postMessage(JSON.stringify({
      capturedAt:new Date().toISOString(), guid:guid, gameDay:gameDay,
      session:session, teams:teams, teamDetails:teamDetails,
      teamDetailErrors:teamDetailErrors,
      leagues:leagues, leaderboards:leaderboards,
      leagueEvents:leagueEvents, leagueHistory:leagueHistory
    }));
  } catch (error) {
    F1Bridge.postMessage(JSON.stringify({
      errorStage:stage,
      error:String(error && error.message || error)
    }));
  }
})()
''');
  }

  Future<void> _onBridgeMessage(JavaScriptMessage message) async {
    try {
      final decoded = jsonDecode(message.message);
      if (kDebugMode) {
        debugPrint(
            '[F1_CAPTURE_STRUCTURE] ${jsonEncode(_structureOf(decoded))}');
      }
      if (decoded is Map && decoded['error'] != null) {
        if (kDebugMode) {
          debugPrint('[F1_CAPTURE_ERROR_STAGE] ${decoded['errorStage']}');
        }
        if (_showBridgeErrors && mounted) {
          setState(() => _status =
              'Todavía no se detecta una cuenta conectada. Inicia sesión en '
                  'la web y vuelve a pulsar "Capturar sesión".');
        }
        return;
      }
      final details = decoded is Map ? decoded['teamDetails'] : null;
      if (details is! Map || details.isEmpty) {
        if (mounted) {
          setState(() =>
              _status = 'La cuenta esta abierta, pero aun no llego el equipo. '
                  'Abre "Mi equipo", espera unos segundos y pulsa Capturar.');
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
            () => _status = 'La web respondió con datos no válidos: $error');
      }
    }
  }

  dynamic _structureOf(dynamic value, [int depth = 0]) {
    if (depth >= 4) return value.runtimeType.toString();
    if (value is Map) {
      return <String, dynamic>{
        for (final entry in value.entries.take(30))
          entry.key.toString(): _structureOf(entry.value, depth + 1),
      };
    }
    if (value is List) {
      return <String, dynamic>{
        'length': value.length,
        if (value.isNotEmpty) 'first': _structureOf(value.first, depth + 1),
      };
    }
    return value.runtimeType.toString();
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
      appBar: AppBar(
        title: const Text('Conectar F1 Fantasy'),
        actions: [
          IconButton(
            tooltip: 'Volver a F1 Fantasy',
            onPressed: () => _controller.loadRequest(Uri.parse(_loginUrl)),
            icon: const Icon(Icons.home_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: AppColors.surface2,
            child: Row(
              children: [
                Expanded(
                  child: Text(_status,
                      style: AppText.body(12, color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: () => _tryCapture(silent: false),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  child: const Text('CAPTURAR'),
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
