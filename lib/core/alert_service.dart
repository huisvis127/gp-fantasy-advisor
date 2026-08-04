import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class AlertService {
  AlertService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_gp'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final androidGranted = await android?.requestNotificationsPermission();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return androidGranted ?? iosGranted ?? true;
  }

  Future<void> scheduleDeadline({
    required DateTime deadline,
    required String raceName,
  }) async {
    await initialize();
    await cancelDeadlineAlerts();
    final now = DateTime.now();
    final alerts = <(int, Duration, String)>[
      (7101, const Duration(hours: 24), 'Queda un día'),
      (7102, const Duration(hours: 1), 'Queda una hora'),
    ];
    for (final alert in alerts) {
      final when = deadline.subtract(alert.$2);
      if (!when.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id: alert.$1,
        title: '${alert.$3} para cerrar tu equipo',
        body: '$raceName: revisa cambios, boost y chips antes del cierre.',
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'fantasy_deadlines',
            'Cierres de F1 Fantasy',
            channelDescription: 'Avisos antes del cierre de cada jornada',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'fantasy_deadline',
      );
    }
  }

  Future<void> cancelDeadlineAlerts() async {
    await _plugin.cancel(id: 7101);
    await _plugin.cancel(id: 7102);
  }

  Future<void> showRecommendationChanged({
    required String driverName,
    required String stage,
  }) async {
    await initialize();
    await _plugin.show(
      id: 7103,
      title: 'Ha cambiado el piloto recomendado',
      body: '$stage: $driverName es ahora la primera opción. Revisa tu plan.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'fantasy_strategy',
          'Cambios de estrategia',
          channelDescription: 'Avisos al cambiar una recomendación importante',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'strategy_changed',
    );
  }
}
