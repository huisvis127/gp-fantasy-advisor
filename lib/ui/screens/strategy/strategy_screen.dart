import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_providers.dart';
import '../../../core/app_locale.dart';
import '../../../core/fantasy_standings_provider.dart';
import '../../../core/team_colors.dart';
import '../../../core/theme.dart';
import '../../../domain/models/strategy_plan.dart';
import '../../widgets/ref_widgets.dart';

class StrategyScreen extends ConsumerWidget {
  const StrategyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Theme.of(context);
    final planAsync = ref.watch(strategyPlanProvider);
    final chipsAsync = ref.watch(chipAdviceProvider);
    final reviewAsync = ref.watch(latestDecisionReviewProvider);
    final catalog = ref.watch(fantasyAssetNameProvider).valueOrNull ?? const {};
    final strings = AppStrings(ref.watch(appLocaleProvider));
    String nameOf(String id) => catalog[id]?.name ?? prettifyId(id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        RefCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHead(
                kicker: strings.t('three_gp_horizon'),
                title: strings.t('season_planner'),
              ),
              const SizedBox(height: 6),
              Text(
                strings.t('planner_intro'),
                style: AppText.body(11.5, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        planAsync.when(
          data: (plan) {
            if (plan.rounds.isEmpty) {
              return StatusBanner(message: strings.t('save_team_for_plan'));
            }
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TotalPill(
                        value: plan.totalExpectedPoints.toStringAsFixed(0),
                        label: strings.t('horizon_points'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TotalPill(
                        value:
                            '${plan.totalProjectedPriceGainMillions >= 0 ? '+' : ''}${plan.totalProjectedPriceGainMillions.toStringAsFixed(1)} M\$',
                        label: strings.t('projected_value'),
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
                    strings: strings,
                  ),
                  const SizedBox(height: 9),
                ],
              ],
            );
          },
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.lime,
              ),
            ),
          ),
          error: (error, _) => StatusBanner(
            message: '${strings.t('plan_failed')}: $error',
            isError: true,
            onRetry: () => ref.invalidate(strategyPlanProvider),
          ),
        ),
        const SizedBox(height: 8),
        SectionHead(
          kicker: strings.t('opportunity'),
          title: strings.t('chip_advisor'),
        ),
        const SizedBox(height: 8),
        chipsAsync.when(
          data: (advice) => advice.isEmpty
              ? StatusBanner(message: strings.t('chip_needs_plan'))
              : Column(
                  children: [
                    for (final item in advice) ...[
                      _ChipCard(advice: item, strings: strings),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
          loading: () => LinearProgressIndicator(
            color: AppColors.cyan,
            backgroundColor: AppColors.surface3,
          ),
          error: (error, _) => StatusBanner(
            message: '${strings.t('chips_failed')}: $error',
            isError: true,
          ),
        ),
        const SizedBox(height: 8),
        SectionHead(
          kicker: strings.t('learning'),
          title: strings.t('decision_review'),
        ),
        const SizedBox(height: 8),
        reviewAsync.when(
          data: (review) {
            if (review == null) {
              return StatusBanner(message: strings.t('review_pending'));
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
                          label: strings.t('your_points'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TotalPill(
                          value: review.optimalPoints.toStringAsFixed(0),
                          label: strings.t('optimal_points'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${strings.t('difference')} ${review.missedPoints.toStringAsFixed(0)} pts · '
                    'boost +${review.boostImpact.toStringAsFixed(0)} pts',
                    style: AppText.body(11.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${strings.t('best')}: ${nameOf(review.bestAssetId)} '
                    '${review.bestAssetPoints.toStringAsFixed(0)} pts · '
                    '${strings.t('worst')}: ${nameOf(review.worstAssetId)} '
                    '${review.worstAssetPoints.toStringAsFixed(0)} pts',
                    style: AppText.body(10.5, color: AppColors.textTertiary),
                  ),
                ],
              ),
            );
          },
          loading: () => LinearProgressIndicator(
            color: AppColors.violet,
            backgroundColor: AppColors.surface3,
          ),
          error: (error, _) => StatusBanner(
            message: '${strings.t('review_failed')}: $error',
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
    required this.strings,
  });

  final PlannedRound round;
  final int number;
  final String Function(String) nameOf;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
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
                    Icon(
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
              strings.t('keep_team'),
              style: AppText.body(11.5, color: AppColors.textSecondary),
            ),
          const SizedBox(height: 7),
          Text(
            'Boost ×2: ${nameOf(round.boostedDriverId)} · '
            '${strings.t('team_value')} ${round.projectedTeamValueMillions.toStringAsFixed(1)} M\$ · '
            'Δ ${round.projectedPriceGainMillions >= 0 ? '+' : ''}'
            '${round.projectedPriceGainMillions.toStringAsFixed(1)} M\$',
            style: AppText.body(10.5, color: AppColors.textTertiary),
          ),
          if (round.transferPenalty < 0) ...[
            const SizedBox(height: 5),
            Text(
              '${round.transferPenalty} ${strings.t('extra_transfer_penalty')}',
              style: AppText.mono(9, color: AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipCard extends StatelessWidget {
  const _ChipCard({required this.advice, required this.strings});

  final ChipAdvice advice;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final color = switch (advice.level) {
      ChipRecommendationLevel.use => AppColors.lime,
      ChipRecommendationLevel.consider => AppColors.warning,
      ChipRecommendationLevel.hold => AppColors.textTertiary,
    };
    final label = switch (advice.level) {
      ChipRecommendationLevel.use => strings.t('use'),
      ChipRecommendationLevel.consider => strings.t('consider'),
      ChipRecommendationLevel.hold => strings.t('hold'),
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
                  strings.t('chip_${advice.level.name}_reason'),
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
