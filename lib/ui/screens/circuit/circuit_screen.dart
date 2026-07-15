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
    final raceAsync = ref.watch(selectedRaceProvider);
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
                                catalog[sorted[i].assetId]?.teamName ?? '',
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
