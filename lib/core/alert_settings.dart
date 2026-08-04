import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alert_service.dart';
import 'app_providers.dart';
import '../domain/models/prediction.dart';

final alertServiceProvider = Provider<AlertService>((ref) => AlertService());

final alertSettingsProvider =
    AsyncNotifierProvider<AlertSettingsNotifier, bool>(
      AlertSettingsNotifier.new,
    );

class AlertSettingsNotifier extends AsyncNotifier<bool> {
  static const _preferenceKey = 'deadline_alerts_enabled';

  @override
  Future<bool> build() async {
    final preferences = await SharedPreferences.getInstance();
    final enabled = preferences.getBool(_preferenceKey) ?? false;
    if (enabled) await _scheduleCurrentDeadline();
    return enabled;
  }

  Future<bool> setEnabled(bool enabled) async {
    final service = ref.read(alertServiceProvider);
    try {
      if (enabled) {
        final granted = await service.requestPermission();
        if (!granted) {
          state = const AsyncData(false);
          return false;
        }
        await _scheduleCurrentDeadline();
      } else {
        await service.cancelDeadlineAlerts();
      }
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_preferenceKey, enabled);
      state = AsyncData(enabled);
      return true;
    } catch (_) {
      state = const AsyncData(false);
      return false;
    }
  }

  Future<void> _scheduleCurrentDeadline() async {
    final snapshot = await ref.read(liveFantasyProvider.future);
    final deadline = snapshot.deadline;
    if (deadline == null || !deadline.isAfter(DateTime.now())) return;
    await ref
        .read(alertServiceProvider)
        .scheduleDeadline(deadline: deadline, raceName: snapshot.meetingName);
  }

  Future<void> notifyIfRecommendationChanged(
    List<AssetPrediction> predictions,
    String stage,
  ) async {
    final enabled = state.valueOrNull ?? await future;
    if (!enabled || predictions.isEmpty) return;
    final sorted = [...predictions]
      ..sort((a, b) => b.expectedPoints.compareTo(a.expectedPoints));
    final topId = sorted.first.assetId;
    final preferences = await SharedPreferences.getInstance();
    final previousId = preferences.getString('last_recommended_driver');
    final previousStage = preferences.getString('last_recommendation_stage');
    await preferences.setString('last_recommended_driver', topId);
    await preferences.setString('last_recommendation_stage', stage);
    if (previousId == null || previousId == topId || previousStage == stage) {
      return;
    }
    await ref
        .read(alertServiceProvider)
        .showRecommendationChanged(
          driverName: topId.replaceAll('_', ' '),
          stage: stage,
        );
  }
}
