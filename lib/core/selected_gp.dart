import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/race.dart';
import 'providers.dart';
import 'sync_status.dart';

/// Selección global de temporada y Gran Premio (petición explícita de Luis:
/// "no se puede escoger carrera"). Igual que los selectores selSeason /
/// selEvent de la app de referencia: todos los cálculos (predicciones,
/// equipo ideal, sugerencias) se hacen para el GP seleccionado, usando solo
/// datos ANTERIORES a ese GP (sin mirar el futuro).

/// Temporadas disponibles en el selector.
final availableSeasonsProvider = Provider<List<int>>((ref) {
  final current = ref.watch(currentSeasonProvider);
  return [current, current - 1, current - 2];
});

final selectedSeasonProvider = StateProvider<int>((ref) {
  return ref.watch(currentSeasonProvider);
});

/// Calendario completo de la temporada seleccionada (desde la caché local,
/// que se rellena con la sincronización).
final seasonRacesProvider = FutureProvider<List<Race>>((ref) async {
  // Se re-lee tras cada sincronización.
  ref.watch(syncControllerProvider);
  final repo = ref.watch(dataRepositoryProvider);
  final season = ref.watch(selectedSeasonProvider);
  final races = await repo.allRaces(season);
  races.sort((a, b) => a.round.compareTo(b.round));
  return races;
});

/// Ronda seleccionada por el usuario (null = automático: el próximo GP).
final selectedRoundProvider = StateProvider<int?>((ref) {
  // Al cambiar de temporada se vuelve al modo automático.
  ref.watch(selectedSeasonProvider);
  return null;
});

/// El GP efectivo sobre el que trabaja toda la app.
final selectedRaceProvider = FutureProvider<Race?>((ref) async {
  final races = await ref.watch(seasonRacesProvider.future);
  if (races.isEmpty) return null;
  final round = ref.watch(selectedRoundProvider);
  if (round != null) {
    for (final race in races) {
      if (race.round == round) return race;
    }
  }
  // Automático: el próximo GP por fecha; si la temporada terminó, el último.
  final now = DateTime.now();
  for (final race in races) {
    if (race.date.add(const Duration(hours: 4)).isAfter(now)) return race;
  }
  return races.last;
});
