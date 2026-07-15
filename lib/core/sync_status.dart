import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/data_repository.dart';
import 'providers.dart';

/// Estado de la sincronización de datos, visible en la UI (queja directa de
/// Luis: "no coge ninguna información" — los fallos se tragaban en silencio).
class SyncState {
  const SyncState({
    this.syncing = false,
    this.lastSync,
    this.report,
    this.fatalError,
  });

  final bool syncing;
  final DateTime? lastSync;
  final SyncReport? report;
  final String? fatalError;

  bool get hasWarnings => (report?.errors.isNotEmpty ?? false) || fatalError != null;

  SyncState copyWith({
    bool? syncing,
    DateTime? lastSync,
    SyncReport? report,
    String? fatalError,
  }) {
    return SyncState(
      syncing: syncing ?? this.syncing,
      lastSync: lastSync ?? this.lastSync,
      report: report ?? this.report,
      fatalError: fatalError,
    );
  }
}

class SyncController extends Notifier<SyncState> {
  @override
  SyncState build() => const SyncState();

  /// Lanza la sincronización completa. Devuelve cuando termina; el estado
  /// intermedio (`syncing`) y el informe final quedan en `state`.
  Future<void> syncNow() async {
    if (state.syncing) return;
    state = state.copyWith(syncing: true, fatalError: null);
    final repo = ref.read(dataRepositoryProvider);
    final season = ref.read(currentSeasonProvider);
    try {
      final report = await repo.syncAll(currentSeason: season);
      state = SyncState(
        syncing: false,
        lastSync: DateTime.now(),
        report: report,
      );
    } catch (e) {
      state = state.copyWith(syncing: false, fatalError: e.toString());
    }
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(SyncController.new);
