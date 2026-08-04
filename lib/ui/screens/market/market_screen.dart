import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_providers.dart';
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
    final forecastsAsync = ref.watch(priceForecastsProvider);
    final catalog = ref.watch(fantasyAssetNameProvider).valueOrNull ?? const {};

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        RefCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHead(
                kicker: 'Ventana móvil de 3 GP',
                title: 'Mercado y precios',
              ),
              const SizedBox(height: 6),
              Text(
                'Combina los dos últimos resultados oficiales con la '
                'predicción del próximo GP. La probabilidad es estimada; '
                'los puntos anteriores y los umbrales son oficiales.',
                style: AppText.body(11.5, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 12),
              SubTabs(
                labels: const ['Pilotos', 'Constructores'],
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
              return const StatusBanner(
                message: 'Sin datos de mercado. Sincroniza desde Resumen.',
              );
            }
            return Column(
              children: [
                if (filtered.any((item) => !item.hasOfficialHistory)) ...[
                  const StatusBanner(
                    message:
                        'Aún faltan dos jornadas oficiales en la caché. '
                        'Los activos marcados como estimados usan la predicción '
                        'también como referencia histórica.',
                  ),
                  const SizedBox(height: 10),
                ],
                for (final forecast in filtered) ...[
                  _MarketCard(
                    forecast: forecast,
                    name:
                        catalog[forecast.assetId]?.name ??
                        prettifyId(forecast.assetId),
                  ),
                  const SizedBox(height: 8),
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
            message: 'No se pudo calcular el mercado: $error',
            isError: true,
            onRetry: () => ref.invalidate(priceForecastsProvider),
          ),
        ),
      ],
    );
  }
}

class _MarketCard extends StatelessWidget {
  const _MarketCard({required this.forecast, required this.name});

  final PriceForecast forecast;
  final String name;

  @override
  Widget build(BuildContext context) {
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
                      '· últimos puntos $history',
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
                  'Subida ${(forecast.riseProbability * 100).toStringAsFixed(0)}%',
                  style: AppText.mono(9, color: color),
                ),
              ),
              Text(
                '≥${forecast.requiredForGood} pts sube · '
                '>${forecast.requiredForGreat} pts máximo',
                style: AppText.body(10, color: AppColors.textSecondary),
              ),
            ],
          ),
          if (!forecast.hasOfficialHistory) ...[
            const SizedBox(height: 5),
            Text(
              'HISTÓRICO ESTIMADO',
              style: AppText.mono(8, color: AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }
}
