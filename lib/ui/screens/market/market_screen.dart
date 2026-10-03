import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_providers.dart';
import '../../../core/app_locale.dart';
import '../../../core/fantasy_standings_provider.dart';
import '../../../core/team_colors.dart';
import '../../../core/theme.dart';
import '../../../domain/models/price_forecast.dart';
import '../../widgets/ref_widgets.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final forecastsAsync = ref.watch(priceForecastsProvider);
    final catalog = ref.watch(fantasyAssetNameProvider).valueOrNull ?? const {};
    final strings = AppStrings(ref.watch(appLocaleProvider));

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        RefCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHead(
                kicker: strings.t('market_window'),
                title: strings.t('market_prices'),
              ),
              const SizedBox(height: 6),
              Text(
                strings.t('market_intro'),
                style: AppText.body(11.5, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 12),
              SubTabs(
                labels: [strings.t('drivers'), strings.t('constructors')],
                selectedIndex: _tab,
                onSelected: (value) => setState(() => _tab = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        forecastsAsync.when(
          data: (forecasts) {
            final filtered = forecasts.where((forecast) {
              final kind = catalog[forecast.assetId]?.kind;
              return _tab == 0
                  ? kind == FantasyAssetKind.driver
                  : kind == FantasyAssetKind.constructor;
            }).toList();
            if (filtered.isEmpty) {
              return StatusBanner(message: strings.t('no_market'));
            }
            return Column(
              children: [
                if (filtered.any((item) => !item.hasOfficialHistory)) ...[
                  StatusBanner(message: strings.t('estimated_history_note')),
                  const SizedBox(height: 10),
                ],
                for (final forecast in filtered) ...[
                  _MarketCard(
                    forecast: forecast,
                    strings: strings,
                    name:
                        catalog[forecast.assetId]?.name ??
                        prettifyId(forecast.assetId),
                  ),
                  const SizedBox(height: 8),
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
            message: '${strings.t('market_failed')}: $error',
            isError: true,
            onRetry: () => ref.invalidate(priceForecastsProvider),
          ),
        ),
      ],
    );
  }
}

class _MarketCard extends StatelessWidget {
  const _MarketCard({
    required this.forecast,
    required this.name,
    required this.strings,
  });

  final PriceForecast forecast;
  final String name;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final delta = forecast.projectedDeltaMillions;
    final color = delta > 0
        ? AppColors.lime
        : delta < 0
        ? AppColors.error
        : AppColors.textSecondary;
    final history = forecast.previousPoints.join(' · ');
    return RefCard(
      padding: const EdgeInsets.all(14),
      borderColor: color.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppText.syne(15)),
                    const SizedBox(height: 3),
                    Text(
                      '${forecast.currentPriceMillions.toStringAsFixed(1)} M\$ '
                      '· ${strings.t('last_points')} $history',
                      style: AppText.body(10.5, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  border: Border.all(color: color.withValues(alpha: 0.45)),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} M\$',
                  style: AppText.mono(11, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: forecast.riseProbability.clamp(0, 1),
              backgroundColor: AppColors.surface3,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${strings.t('rise')} ${(forecast.riseProbability * 100).toStringAsFixed(0)}%',
                  style: AppText.mono(9, color: color),
                ),
              ),
              Text(
                '${strings.t('rises_at')} ≥${forecast.requiredForGood} pts · '
                '${strings.t('maximum_at')} >${forecast.requiredForGreat} pts',
                style: AppText.body(10, color: AppColors.textSecondary),
              ),
            ],
          ),
          if (!forecast.hasOfficialHistory) ...[
            const SizedBox(height: 5),
            Text(
              strings.t('estimated_history'),
              style: AppText.mono(8, color: AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }
}
