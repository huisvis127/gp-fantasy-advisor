import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/app_providers.dart';
import '../../../core/fantasy_standings_provider.dart';
import '../../../core/team_colors.dart';
import '../../../core/theme.dart';
import '../../../domain/models/prediction.dart';
import '../../../domain/models/race.dart';
import '../../widgets/ref_widgets.dart';

class CircuitScreen extends ConsumerWidget {
  const CircuitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raceAsync = ref.watch(selectedRaceScheduleProvider);
    final winnersAsync = ref.watch(circuitWinnersProvider);
    final predictions = ref.watch(driverPredictionsProvider);
    final catalog = ref.watch(fantasyAssetNameProvider).valueOrNull ?? const {};

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        raceAsync.when(
          data: (race) {
            if (race == null) {
              return const StatusBanner(
                message: 'Sin calendario. Sincroniza desde Resumen.',
              );
            }
            return HeroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Kicker('Próxima parada'),
                  const SizedBox(height: 6),
                  Text(race.raceName, style: AppText.syne(30)),
                  const SizedBox(height: 5),
                  Text(
                    '${race.circuitName} · ${race.country}',
                    style: AppText.body(13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TagChip('Ronda ${race.round}', color: AppColors.lime),
                      TagChip(
                        DateFormat('dd MMM · HH:mm', 'es').format(race.date),
                        color: AppColors.cyan,
                      ),
                      if (race.hasSprint)
                        const TagChip('Sprint', color: AppColors.orange),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => const StatusBanner(
            message: 'No se pudo cargar el circuito seleccionado.',
            isError: true,
          ),
        ),
        const SizedBox(height: 16),
        raceAsync.maybeWhen(
          data: (race) => race == null
              ? const SizedBox.shrink()
              : _WeekendSchedule(race: race),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        const SectionHead(
          kicker: 'Historial reciente',
          title: 'Ganadores de los últimos 5 años',
        ),
        const SizedBox(height: 10),
        winnersAsync.when(
          data: (winners) => winners.isEmpty
              ? const StatusBanner(
                  message:
                      'Los ganadores aparecerán al terminar la sincronización histórica.',
                )
              : RefCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < winners.length; i++) ...[
                        Row(children: [
                          Text('${winners[i].season}',
                              style: AppText.mono(9, color: AppColors.lime)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              catalog[winners[i].driverId]?.name ??
                                  prettifyId(winners[i].driverId),
                              style: AppText.body(12, weight: FontWeight.w700),
                            ),
                          ),
                        ]),
                        if (i < winners.length - 1) const Divider(height: 20),
                      ],
                    ],
                  ),
                ),
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, __) => const StatusBanner(
            message: 'No se pudo cargar el historial de ganadores.',
            isError: true,
          ),
        ),
        const SizedBox(height: 16),
        const SectionHead(
          kicker: 'Afinidad',
          title: 'Especialistas del circuito',
        ),
        const SizedBox(height: 5),
        Text(
          'La nota combina historial, forma y rendimiento del equipo.',
          style: AppText.body(12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        predictions.when(
          data: (items) {
            if (items.isEmpty) {
              return const StatusBanner(
                message:
                    'Todavía no hay datos suficientes para comparar pilotos.',
              );
            }
            final maxExpected = items
                .map((item) => item.expectedPoints)
                .fold<double>(0, (best, value) => value > best ? value : best);
            double circuitScore(AssetPrediction item) {
              final affinity = item.breakdown['afinidad_circuito'];
              if (affinity != null) return affinity;
              return maxExpected <= 0
                  ? 0
                  : item.expectedPoints / maxExpected * 100;
            }

            final withHistory = items
                .where((item) =>
                    (item.breakdown['circuit_history_count'] ?? 0) > 0)
                .toList();
            if (withHistory.isEmpty) {
              return const StatusBanner(
                message:
                    'Aún no hay participaciones anteriores en este circuito para comparar.',
              );
            }
            final sorted = [...withHistory]
              ..sort((a, b) => circuitScore(b).compareTo(circuitScore(a)));
            return Column(
              children: [
                for (var i = 0; i < sorted.take(5).length; i++) ...[
                  RefCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Text('${i + 1}',
                            style: AppText.syne(20, color: AppColors.lime)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                catalog[sorted[i].assetId]?.name ??
                                    prettifyId(sorted[i].assetId),
                                style:
                                    AppText.body(14, weight: FontWeight.w700),
                              ),
                              Text(
                                '${catalog[sorted[i].assetId]?.teamName ?? ''} · ${(sorted[i].breakdown['circuit_history_count'] ?? 0).round()} participaciones',
                                style: AppText.body(11,
                                    color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                        TagChip(
                          '${circuitScore(sorted[i]).toStringAsFixed(0)}/100',
                          color: AppColors.cyan,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, __) => const StatusBanner(
            message: 'No se pudo calcular la afinidad del circuito.',
            isError: true,
          ),
        ),
      ],
    );
  }
}

class _WeekendSchedule extends StatelessWidget {
  const _WeekendSchedule({required this.race});

  final Race race;

  @override
  Widget build(BuildContext context) {
    const labels = {
      'fp1': 'Libres 1',
      'fp2': 'Libres 2',
      'fp3': 'Libres 3',
      'sprint_qualifying': 'Clasificación sprint',
      'sprint': 'Sprint',
      'qualifying': 'Clasificación',
      'race': 'Carrera',
    };
    final sessions = race.sessionTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    if (sessions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHead(kicker: 'Fin de semana', title: 'Horarios del GP'),
        const SizedBox(height: 10),
        RefCard(
          child: Column(
            children: [
              for (var i = 0; i < sessions.length; i++) ...[
                Row(children: [
                  Expanded(
                    child: Text(labels[sessions[i].key] ?? sessions[i].key,
                        style: AppText.body(11.5, weight: FontWeight.w700)),
                  ),
                  Text(
                    DateFormat('EEE dd MMM · HH:mm', 'es')
                        .format(sessions[i].value),
                    style: AppText.mono(8.5,
                        color: sessions[i].key == 'race'
                            ? AppColors.lime
                            : AppColors.cyan),
                  ),
                ]),
                if (i < sessions.length - 1) const Divider(height: 19),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
