import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fantasy_standings_provider.dart';
import '../../../core/localization.dart';
import '../../../core/providers.dart';
import '../../../core/team_colors.dart';
import '../../../core/theme.dart';
import '../../widgets/ref_widgets.dart';

class ChampionshipStandingsScreen extends ConsumerStatefulWidget {
  const ChampionshipStandingsScreen({super.key});

  @override
  ConsumerState<ChampionshipStandingsScreen> createState() =>
      _ChampionshipStandingsScreenState();
}

class _ChampionshipStandingsScreenState
    extends ConsumerState<ChampionshipStandingsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final season = ref.watch(currentSeasonProvider);
    final drivers = ref.watch(fantasyDriverAssetInfoProvider);
    final constructors = ref.watch(fantasyConstructorAssetInfoProvider);
    final constructorRows = constructors.valueOrNull ?? const [];

    return RefreshIndicator(
      color: AppColors.lime,
      onRefresh: () async {
        ref.invalidate(fantasyDriverAssetInfoProvider);
        ref.invalidate(fantasyConstructorAssetInfoProvider);
        await Future.wait([
          ref.read(fantasyDriverAssetInfoProvider.future),
          ref.read(fantasyConstructorAssetInfoProvider.future),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          HeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Kicker('Campeonato del mundo'),
                const SizedBox(height: 7),
                Text(context.tr('Clasificacion {season}', values: {'season': season}), style: AppText.syne(32)),
                const SizedBox(height: 7),
                Text(
                  context.tr('Puntos oficiales de pilotos y constructores. Desliza hacia abajo para actualizar.'),
                  style: AppText.body(14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SubTabs(
            labels: const ['Pilotos', 'Constructores'],
            selectedIndex: _tab,
            onSelected: (value) => setState(() => _tab = value),
          ),
          const SizedBox(height: 14),
          if (_tab == 0)
            _StandingsList(
              rows: drivers,
              constructors: constructorRows,
            )
          else
            _StandingsList(
              rows: constructors,
              constructors: constructorRows,
            ),
        ],
      ),
    );
  }
}

class _StandingsList extends StatelessWidget {
  const _StandingsList({required this.rows, required this.constructors});

  final AsyncValue<List<FantasyAssetInfo>> rows;
  final List<FantasyAssetInfo> constructors;

  @override
  Widget build(BuildContext context) {
    return rows.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(36),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.lime,
          ),
        ),
      ),
      error: (_, __) => const StatusBanner(
        message: 'No se pudo cargar la clasificacion general.',
        isError: true,
      ),
      data: (items) {
        final sorted = [...items]
          ..sort((a, b) => a.position.compareTo(b.position));
        if (sorted.isEmpty) {
          return const StatusBanner(
            message: 'Todavia no hay clasificacion disponible.',
          );
        }
        final leaderPoints = sorted.first.seasonPoints;
        return Column(
          children: [
            for (var index = 0; index < sorted.length; index++) ...[
              _StandingCard(
                info: sorted[index],
                color: _assetColor(sorted[index], constructors),
                gap: index == 0
                    ? null
                    : leaderPoints - sorted[index].seasonPoints,
              ),
              if (index < sorted.length - 1) const SizedBox(height: 9),
            ],
          ],
        );
      },
    );
  }

  Color _assetColor(
    FantasyAssetInfo info,
    List<FantasyAssetInfo> constructors,
  ) {
    if (info.kind == FantasyAssetKind.constructor) return teamColor(info.id);
    final teamKey = _normalize(info.teamName);
    for (final constructor in constructors) {
      if (_normalize(constructor.name) == teamKey) {
        return teamColor(constructor.id);
      }
    }
    return teamColor(teamKey.replaceAll(' ', '_'));
  }
}

class _StandingCard extends StatelessWidget {
  const _StandingCard({
    required this.info,
    required this.color,
    required this.gap,
  });

  final FantasyAssetInfo info;
  final Color color;
  final double? gap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        border: Border.all(color: AppColors.border1),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: color),
              SizedBox(
                width: 56,
                child: Center(
                  child: Text(
                    '${info.position}',
                    style: AppText.syne(
                      25,
                      color: info.position <= 3
                          ? AppColors.lime
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(16, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        info.kind == FantasyAssetKind.driver
                            ? info.teamName
                            : '${info.wins} victorias',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 14, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _points(info.seasonPoints),
                      style: AppText.syne(23),
                    ),
                    Text(context.tr('PUNTOS'), style: AppText.mono(7.5)),
                    if (gap != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '-${_points(gap!)}',
                        style: AppText.body(
                          11,
                          color: AppColors.textTertiary,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _points(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1);
}

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
