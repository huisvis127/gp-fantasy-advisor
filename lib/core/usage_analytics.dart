import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';
import 'providers.dart';

enum UsageConsent {
  unknown,
  denied,
  allowed,
}

/// Telemetría deliberadamente mínima y anónima.
///
/// Solo admite nombres incluidos en [_allowedEvents]. No acepta parámetros,
/// texto libre, identificadores de cuenta ni datos de Fantasy. Los eventos se
/// agrupan por día antes de salir del dispositivo y el identificador diario
/// se renueva cada medianoche, por lo que no permite seguir a una instalación
/// entre días.
class UsageAnalyticsController extends AsyncNotifier<UsageConsent> {
  static const _consentKey = 'usage_analytics_consent_v1';
  static const _queueKey = 'usage_analytics_queue_v1';
  static const _dailyIdKey = 'usage_analytics_daily_id_v1';
  static const _dailyIdDateKey = 'usage_analytics_daily_id_date_v1';

  static const Set<String> _allowedEvents = {
    'app_open',
    'screen_home',
    'screen_analysis',
    'screen_fantasy',
    'screen_fantasy_ideal',
    'screen_fantasy_team',
    'screen_fantasy_history',
    'screen_standings',
    'screen_circuit',
    'screen_league',
    'screen_settings',
    'screen_about',
    'screen_privacy',
    'screen_fantasy_login',
    'analytics_enabled',
    'sync_requested',
    'model_weights_reset',
    'fantasy_login_opened',
    'local_data_deleted',
  };

  @override
  Future<UsageConsent> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_consentKey);
    final consent = switch (stored) {
      'allowed' => UsageConsent.allowed,
      'denied' => UsageConsent.denied,
      _ => UsageConsent.unknown,
    };
    await _setFirebaseCollectionEnabled(consent == UsageConsent.allowed);
    if (consent == UsageConsent.allowed) {
      Future<void>.microtask(flush);
    }
    return consent;
  }

  Future<void> setConsent(UsageConsent consent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_consentKey, consent.name);
    state = AsyncData(consent);

    if (consent == UsageConsent.allowed) {
      await _setFirebaseCollectionEnabled(true);
      await track('analytics_enabled');
    } else {
      await _setFirebaseCollectionEnabled(false);
      await clearPendingData();
    }
  }

  Future<void> track(String event) async {
    if (!_allowedEvents.contains(event) ||
        state.valueOrNull != UsageConsent.allowed) {
      return;
    }

    await _logFirebaseEvent(event);

    final prefs = await SharedPreferences.getInstance();
    final queue = _readQueue(prefs);
    queue[event] = (queue[event] ?? 0) + 1;
    await prefs.setString(_queueKey, jsonEncode(queue));

    final total = queue.values.fold<int>(0, (sum, count) => sum + count);
    if (total >= 8) {
      await flush();
    }
  }

  Future<void> flush() async {
    if (state.valueOrNull != UsageConsent.allowed) return;

    final config = ref.read(remoteConfigProvider);
    final endpoint = config.analyticsEndpoint;
    if (!config.analyticsEnabled || endpoint.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final queue = _readQueue(prefs);
    if (queue.isEmpty) return;

    final day = _today();
    final payload = <String, dynamic>{
      'schema': 1,
      'day': day,
      'daily_id': await _dailyId(prefs, day),
      'app_version': AppMeta.appVersion,
      'events': [
        for (final entry in queue.entries)
          {'name': entry.key, 'count': entry.value},
      ],
    };

    try {
      await ref.read(dioProvider).post<void>(
            endpoint,
            data: payload,
            options: Options(
              headers: const {'Content-Type': 'application/json'},
              sendTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 4),
            ),
          );
      await prefs.remove(_queueKey);
    } catch (_) {
      // La analítica nunca debe afectar al funcionamiento de la app.
      // Conservamos el agregado local para reintentar más adelante.
    }
  }

  Future<void> clearPendingData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
    await prefs.remove(_dailyIdKey);
    await prefs.remove(_dailyIdDateKey);
  }

  Future<void> _setFirebaseCollectionEnabled(bool enabled) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
    } on FirebaseException {
      // Firebase nunca debe afectar al funcionamiento de la app.
    }
  }

  Future<void> _logFirebaseEvent(String event) async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseAnalytics.instance.logEvent(name: event);
    } on FirebaseException {
      // La cola anónima propia sigue funcionando si Firebase no está listo.
    }
  }

  Map<String, int> _readQueue(SharedPreferences prefs) {
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return <String, int>{};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final entry in decoded.entries)
          if (_allowedEvents.contains(entry.key) && entry.value is num)
            entry.key: (entry.value as num).toInt(),
      };
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<String> _dailyId(SharedPreferences prefs, String day) async {
    if (prefs.getString(_dailyIdDateKey) == day) {
      final existing = prefs.getString(_dailyIdKey);
      if (existing != null && existing.isNotEmpty) return existing;
    }

    final random = Random.secure();
    final bytes = List<int>.generate(12, (_) => random.nextInt(256));
    final id = base64UrlEncode(bytes).replaceAll('=', '');
    await prefs.setString(_dailyIdDateKey, day);
    await prefs.setString(_dailyIdKey, id);
    return id;
  }

  String _today() {
    final now = DateTime.now().toUtc();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }
}

final usageAnalyticsProvider =
    AsyncNotifierProvider<UsageAnalyticsController, UsageConsent>(
  UsageAnalyticsController.new,
);
