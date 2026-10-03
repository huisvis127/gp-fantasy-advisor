import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/app_providers.dart';
import '../../../core/fantasy_standings_provider.dart';
import '../../../core/team_colors.dart';
import '../../../core/theme.dart';
import '../../../domain/models/prediction.dart';
import '../../widgets/ref_widgets.dart';

class CircuitScreen extends ConsumerWidget {
  const CircuitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Theme.of(context);
    final raceAsync = ref.watch(selectedRaceProvider);
    final predictions = ref.watch(driverPredictionsProvider);
    final weekend = ref.watch(weekendDataProvider);
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
                        TagChip('Sprint', color: AppColors.orange),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, __) => const StatusBanner(
            message: 'No se pudo cargar el circuito seleccionado.',
            isError: true,
          ),
        ),
        const SizedBox(height: 16),
        const SectionHead(kicker: 'OpenF1', title: 'Inteligencia de sesión'),
        const SizedBox(height: 8),
        weekend.when(
          data: (data) {
            if (data.insights.isEmpty) {
              return const StatusBanner(
                message:
                    'El panel se activará cuando termine una sesión de '
                    'entrenamientos del GP seleccionado.',
              );
            }
            final insights = data.insights.values.toList()
              ..sort((a, b) => a.paceGapPercent.compareTo(b.paceGapPercent));
            return Column(
              children: [
                for (final insight in insights.take(6)) ...[
                  RefCard(
                    padding: const EdgeInsets.all(13),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                catalog[insight.driverId]?.name ??
                                    prettifyId(insight.driverId),
                                style: AppText.body(
                                  13.5,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${insight.totalLaps} vueltas · '
                                '${insight.sessionCount} sesiones · '
                                'dispersión larga '
                                '${insight.longRunSpreadPercent.toStringAsFixed(1)}%',
                                style: AppText.body(
                                  10,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+${insight.paceGapPercent.toStringAsFixed(2)}%',
                              style: AppText.mono(10, color: AppColors.lime),
                            ),
                            Text(
                              '1V +${insight.oneLapGapPercent.toStringAsFixed(2)}%',
                              style: AppText.mono(
                                8,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                ],
              ],
            );
          },
          loading: () => LinearProgressIndicator(
            color: AppColors.cyan,
            backgroundColor: AppColors.surface3,
          ),
          error: (error, _) => StatusBanner(
            message: 'No se pudo cargar la telemetría: $error',
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

            final sorted = [...items]
              ..sort((a, b) => circuitScore(b).compareTo(circuitScore(a)));
            return Column(
              children: [
                for (var i = 0; i < sorted.take(5).length; i++) ...[
                  RefCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Text(
                          '${i + 1}',
                          style: AppText.syne(20, color: AppColors.lime),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                catalog[sorted[i].assetId]?.name ??
                                    prettifyId(sorted[i].assetId),
                                style: AppText.body(
                                  14,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                catalog[sorted[i].assetId]?.teamName ?? '',
                                style: AppText.body(
                                  11,
                                  color: AppColors.textTertiary,
                                ),
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
