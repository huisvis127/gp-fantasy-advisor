import 'dart:convert';

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
          if (!_tokenCaptured && url.contains('formula1.com')) {
            await _tryCapture(silent: true);
          }
        },
      ))
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
              () => _status = 'Sesión detectada. Descargando equipo y ligas…');
        }
      }
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
  try {
    const headers = {'Content-Type':'application/json', 'entity':'Wh@t$|_||>'};
    const readJson = async (url, options) => {
      const response = await fetch(url, Object.assign({credentials:'include', headers:headers}, options || {}));
      if (!response.ok) throw new Error(url + ' -> ' + response.status);
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

    const schedule = await readJson('/feeds/v2/schedule/raceday_en.json');
    const fixtures = (schedule.Data && schedule.Data.fixtures) || [];
    const current = fixtures.find(x => Number(x.GDIsCurrent) === 1) || fixtures[0] || {};
    const gameDay = Number(current.GamedayId || current.Gameday || 1);
    const teams = await readJson('/services/user/gameplay/' + guid + '/getusergamedaysv1/1');
    const leagues = await readJson('/services/user/league/' + guid + '/getuserleague/1');

    const findArray = node => {
      if (!node || typeof node !== 'object') return [];
      for (const key of ['Details','leagues','Leagues','Value','results']) {
        if (Array.isArray(node[key])) return node[key];
      }
      for (const value of Object.values(node)) {
        const found = findArray(value);
        if (found.length) return found;
      }
      return [];
    };
    const leagueRows = findArray(valueOf(leagues));
    const leaderboards = {};
    for (const league of leagueRows.slice(0, 20)) {
      const id = league.LeagueId || league.LeagueID || league.league_id || league.id;
      if (!id) continue;
      const h2h = Number(league.IsHTHLeague || league.isHTHLeague || 0);
      try {
        leaderboards[String(id)] = await readJson(
          '/services/user/league/' + guid + '/getuserleaguemembers/1/' + id + '/' + h2h + '/' + gameDay + '/1/100/'
        );
      } catch (_) {}
    }
    F1Bridge.postMessage(JSON.stringify({
      capturedAt:new Date().toISOString(), guid:guid, gameDay:gameDay,
      session:session, teams:teams, leagues:leagues, leaderboards:leaderboards
    }));
  } catch (error) {
    F1Bridge.postMessage(JSON.stringify({error:String(error && error.message || error)}));
  }
})()
''');
  }

  Future<void> _onBridgeMessage(JavaScriptMessage message) async {
    try {
      final decoded = jsonDecode(message.message);
      if (decoded is Map && decoded['error'] != null) {
        if (_showBridgeErrors && mounted) {
          setState(() => _status =
              'Todavía no se detecta una cuenta conectada. Inicia sesión en '
              'la web y vuelve a pulsar "Capturar sesión".');
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
      appBar: AppBar(title: const Text('Iniciar sesión (navegador)')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: AppColors.surface2,
            child: Row(
              children: [
                Expanded(
                  child: Text(_status,
                      style: AppText.body(12, color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _tryCapture(silent: false),
                  child: const Text('CAPTURAR SESIÓN'),
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
