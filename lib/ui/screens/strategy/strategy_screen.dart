import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_providers.dart';
import '../../../core/fantasy_standings_provider.dart';
import '../../../core/team_colors.dart';
import '../../../core/theme.dart';
import '../../../domain/models/strategy_plan.dart';
import '../../widgets/ref_widgets.dart';

class StrategyScreen extends ConsumerWidget {
  const StrategyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(strategyPlanProvider);
    final chipsAsync = ref.watch(chipAdviceProvider);
    final reviewAsync = ref.watch(latestDecisionReviewProvider);
    final catalog = ref.watch(fantasyAssetNameProvider).valueOrNull ?? const {};
    String nameOf(String id) => catalog[id]?.name ?? prettifyId(id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        RefCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHead(
                kicker: 'Horizonte de 3 GP',
                title: 'Planificador de temporada',
              ),
              const SizedBox(height: 6),
              Text(
                'Encadena cambios, boost y crecimiento de presupuesto. '
                'El primer GP incorpora las sesiones disponibles; los '
                'siguientes son proyecciones pre-fin de semana.',
                style: AppText.body(11.5, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        planAsync.when(
          data: (plan) {
            if (plan.rounds.isEmpty) {
              return const StatusBanner(
                message:
                    'Guarda o importa un equipo completo para crear '
                    'el plan de los próximos Grandes Premios.',
              );
            }
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TotalPill(
                        value: plan.totalExpectedPoints.toStringAsFixed(0),
                        label: 'pts en el horizonte',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TotalPill(
                        value:
                            '${plan.totalProjectedPriceGainMillions >= 0 ? '+' : ''}${plan.totalProjectedPriceGainMillions.toStringAsFixed(1)} M\$',
                        label: 'valor proyectado',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (var index = 0; index < plan.rounds.length; index++) ...[
                  _RoundCard(
                    round: plan.rounds[index],
                    number: index + 1,
                    nameOf: nameOf,
                  ),
                  const SizedBox(height: 9),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.lime,
              ),
            ),
          ),
          error: (error, _) => StatusBanner(
            message: 'No se pudo construir el plan: $error',
            isError: true,
            onRetry: () => ref.invalidate(strategyPlanProvider),
          ),
        ),
        const SizedBox(height: 8),
        const SectionHead(kicker: 'Oportunidad', title: 'Asesor de chips'),
        const SizedBox(height: 8),
        chipsAsync.when(
          data: (advice) => advice.isEmpty
              ? const StatusBanner(
                  message: 'El asesor necesita un equipo y un plan válidos.',
                )
              : Column(
                  children: [
                    for (final item in advice) ...[
                      _ChipCard(advice: item),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
          loading: () => const LinearProgressIndicator(
            color: AppColors.cyan,
            backgroundColor: AppColors.surface3,
          ),
          error: (error, _) => StatusBanner(
            message: 'No se pudo evaluar los chips: $error',
            isError: true,
          ),
        ),
        const SizedBox(height: 8),
        const SectionHead(
          kicker: 'Aprendizaje',
          title: 'Revisión de decisiones',
        ),
        const SizedBox(height: 8),
        reviewAsync.when(
          data: (review) {
            if (review == null) {
              return const StatusBanner(
                message:
                    'La revisión aparecerá después de una jornada para '
                    'la que hayas guardado tu equipo.',
              );
            }
            return RefCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Kicker(review.raceName, color: AppColors.violet),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TotalPill(
                          value: review.teamPoints.toStringAsFixed(0),
                          label: 'tus puntos',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TotalPill(
                          value: review.optimalPoints.toStringAsFixed(0),
                          label: 'óptimo posible',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Diferencia ${review.missedPoints.toStringAsFixed(0)} pts · '
                    'boost +${review.boostImpact.toStringAsFixed(0)} pts',
                    style: AppText.body(11.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Mejor: ${nameOf(review.bestAssetId)} '
                    '${review.bestAssetPoints.toStringAsFixed(0)} pts · '
                    'Peor: ${nameOf(review.worstAssetId)} '
                    '${review.worstAssetPoints.toStringAsFixed(0)} pts',
                    style: AppText.body(10.5, color: AppColors.textTertiary),
                  ),
                ],
              ),
            );
          },
          loading: () => const LinearProgressIndicator(
            color: AppColors.violet,
            backgroundColor: AppColors.surface3,
          ),
          error: (error, _) => StatusBanner(
            message: 'No se pudo revisar la última jornada: $error',
            isError: true,
          ),
        ),
      ],
    );
  }
}

class _RoundCard extends StatelessWidget {
  const _RoundCard({
    required this.round,
    required this.number,
    required this.nameOf,
  });

  final PlannedRound round;
  final int number;
  final String Function(String) nameOf;

  @override
  Widget build(BuildContext context) {
    final hasTransfers = round.transfersIn.isNotEmpty;
    return RefCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Kicker('GP $number', color: AppColors.cyan),
              const SizedBox(width: 8),
              Expanded(
                child: Text(round.projection.raceName, style: AppText.syne(14)),
              ),
              Text(
                '${round.expectedPoints.toStringAsFixed(0)} pts',
                style: AppText.mono(11, color: AppColors.lime),
              ),
            ],
          ),
          const SizedBox(height: 9),
          if (hasTransfers)
            for (var i = 0; i < round.transfersIn.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz_rounded,
                      size: 15,
                      color: AppColors.violet,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${nameOf(round.transfersOut[i])} → '
                        '${nameOf(round.transfersIn[i])}',
                        style: AppText.body(11.5),
                      ),
                    ),
                  ],
                ),
              )
          else
            Text(
              'Mantener el equipo',
              style: AppText.body(11.5, color: AppColors.textSecondary),
            ),
          const SizedBox(height: 7),
          Text(
            'Boost ×2: ${nameOf(round.boostedDriverId)} · '
            'valor ${round.projectedTeamValueMillions.toStringAsFixed(1)} M\$ · '
            'Δ ${round.projectedPriceGainMillions >= 0 ? '+' : ''}'
            '${round.projectedPriceGainMillions.toStringAsFixed(1)} M\$',
            style: AppText.body(10.5, color: AppColors.textTertiary),
          ),
          if (round.transferPenalty < 0) ...[
            const SizedBox(height: 5),
            Text(
              '${round.transferPenalty} pts por cambios adicionales',
              style: AppText.mono(9, color: AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipCard extends StatelessWidget {
  const _ChipCard({required this.advice});

  final ChipAdvice advice;

  @override
  Widget build(BuildContext context) {
    final color = switch (advice.level) {
      ChipRecommendationLevel.use => AppColors.lime,
      ChipRecommendationLevel.consider => AppColors.warning,
      ChipRecommendationLevel.hold => AppColors.textTertiary,
    };
    final label = switch (advice.level) {
      ChipRecommendationLevel.use => 'USAR',
      ChipRecommendationLevel.consider => 'VALORAR',
      ChipRecommendationLevel.hold => 'GUARDAR',
    };
    return RefCard(
      padding: const EdgeInsets.all(13),
      borderColor: color.withValues(alpha: 0.28),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(advice.chip, style: AppText.syne(13)),
                const SizedBox(height: 3),
                Text(
                  advice.reason,
                  style: AppText.body(10.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(label, style: AppText.mono(9, color: color)),
              const SizedBox(height: 3),
              Text(
                '${advice.score}/100',
                style: AppText.mono(10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
