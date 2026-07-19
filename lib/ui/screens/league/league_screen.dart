import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../domain/models/fantasy_league.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../login/fantasy_login_screen.dart';

/// Ligas, clasificación y equipos que devuelve la cuenta de F1 Fantasy.
class LeagueScreen extends ConsumerStatefulWidget {
  const LeagueScreen({super.key});

  @override
  ConsumerState<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends ConsumerState<LeagueScreen> {
  late Future<String?> _tokenFuture;

  @override
  void initState() {
    super.initState();
    _reloadSession();
  }

  void _reloadSession() =>
      _tokenFuture = ref.read(fantasyAuthServiceProvider).readStoredToken();

  Future<void> _login() async {
    await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const FantasyLoginScreen()));
    if (mounted) setState(_reloadSession);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liga')),
      body: FutureBuilder<String?>(
        future: _tokenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data == null) return _LoginPrompt(onLogin: _login);
          return _LeaguesList(token: snapshot.data!);
        },
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.onLogin});
  final VoidCallback onLogin;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Inicia sesión para ver tus ligas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: onLogin,
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
    ),
  );
}

class _LeaguesList extends ConsumerStatefulWidget {
  const _LeaguesList({required this.token});
  final String token;

  @override
  ConsumerState<_LeaguesList> createState() => _LeaguesListState();
}

class _LeaguesListState extends ConsumerState<_LeaguesList> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = ref
      .read(fantasyApiProvider)
      .getLeagueEntrants(
        season: ref.read(currentSeasonProvider),
        bearerToken: widget.token,
      );

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return EmptyState.apiDown(onRetry: () => setState(_load));
      }
      final leagues = FantasyLeague.fromEntrantsResponse(
        snapshot.data ?? const {},
      );
      if (leagues.isEmpty) {
        return const EmptyState(
          icon: Icons.groups_2_rounded,
          title: 'Sin ligas todavía',
          message: 'Únete o crea una liga en F1 Fantasy para verla aquí.',
        );
      }
      return RefreshIndicator(
        onRefresh: () async => setState(_load),
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: leagues.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, index) =>
              _LeagueCard(league: leagues[index], token: widget.token),
        ),
      );
    },
  );
}

class _LeagueCard extends ConsumerStatefulWidget {
  const _LeagueCard({required this.league, required this.token});
  final FantasyLeague league;
  final String token;
  @override
  ConsumerState<_LeagueCard> createState() => _LeagueCardState();
}

class _LeagueCardState extends ConsumerState<_LeagueCard> {
  late Future<Map<String, dynamic>> _future;
  bool _expanded = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = ref
      .read(fantasyApiProvider)
      .getLeagueLeaderboard(
        season: ref.read(currentSeasonProvider),
        leagueId: widget.league.id,
        bearerToken: widget.token,
      );

  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: () => setState(() => _expanded = !_expanded),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.groups_rounded, color: AppColors.cyan),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                widget.league.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Icon(
              _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          widget.league.memberCount == null
              ? 'Toca para cargar la clasificación'
              : '${widget.league.memberCount} miembros',
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.md),
          _Leaderboard(future: _future, onRetry: () => setState(_load)),
        ],
      ],
    ),
  );
}

class _Leaderboard extends StatefulWidget {
  const _Leaderboard({required this.future, required this.onRetry});
  final Future<Map<String, dynamic>> future;
  final VoidCallback onRetry;
  @override
  State<_Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<_Leaderboard> {
  int? _raceWindow = 6;

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: widget.future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: CircularProgressIndicator(),
          ),
        );
      }
      if (snapshot.hasError) {
        return TextButton.icon(
          onPressed: widget.onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar clasificación'),
        );
      }
      final entries = FantasyLeagueEntry.fromLeaderboardResponse(
        snapshot.data ?? const {},
      );
      if (entries.isEmpty) {
        return const Text('La liga no tiene equipos disponibles todavía.');
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PositionChart(
            entries: entries,
            raceWindow: _raceWindow,
            onWindowChanged: (value) => setState(() => _raceWindow = value),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final entry in entries) _EntryRow(entry: entry),
        ],
      );
    },
  );
}

class _EntryRow extends StatefulWidget {
  const _EntryRow({required this.entry});
  final FantasyLeagueEntry entry;
  @override
  State<_EntryRow> createState() => _EntryRowState();
}

class _EntryRowState extends State<_EntryRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    entry.rank == null ? '–' : '#${entry.rank}',
                    style: AppText.mono(11, color: AppColors.lime),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.teamName.isEmpty
                            ? 'Equipo sin nombre'
                            : entry.teamName,
                      ),
                      if (entry.managerName.isNotEmpty)
                        Text(
                          entry.managerName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.points.toStringAsFixed(1)} pts',
                      style: AppText.body(13, weight: FontWeight.w700),
                    ),
                    if (entry.teamValue != null)
                      Text(
                        '${entry.teamValue!.toStringAsFixed(1)} M',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: _TeamDetails(entry: entry),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _PositionChart extends StatelessWidget {
  const _PositionChart({
    required this.entries,
    required this.raceWindow,
    required this.onWindowChanged,
  });

  final List<FantasyLeagueEntry> entries;
  final int? raceWindow;
  final ValueChanged<int?> onWindowChanged;

  static const _colors = [
    AppColors.lime,
    AppColors.cyan,
    AppColors.magenta,
    AppColors.orange,
    AppColors.violet,
    AppColors.ok,
    AppColors.gold,
    AppColors.silver,
  ];

  @override
  Widget build(BuildContext context) {
    final allRounds =
        entries
            .expand((e) => e.positionHistory.map((p) => p.round))
            .toSet()
            .toList()
          ..sort();
    final latestRound = allRounds.isEmpty ? 1 : allRounds.last;
    final visibleRounds = raceWindow == null || allRounds.length <= raceWindow!
        ? allRounds
        : allRounds.sublist(allRounds.length - raceWindow!);
    final minRound = visibleRounds.isEmpty ? latestRound : visibleRounds.first;
    final maxRound = visibleRounds.isEmpty ? latestRound : visibleRounds.last;
    var maxRank = entries.length < 2 ? 2 : entries.length;
    for (final entry in entries) {
      if ((entry.rank ?? 0) > maxRank) maxRank = entry.rank!;
      for (final point in entry.positionHistory) {
        if (point.rank > maxRank) maxRank = point.rank;
      }
    }
    final labels = <int, String>{};
    for (final point in entries.expand((e) => e.positionHistory)) {
      labels[point.round] = point.label;
    }

    List<LeaguePosition> pointsFor(FantasyLeagueEntry entry) {
      final history = entry.positionHistory
          .where((point) => point.round >= minRound)
          .toList();
      if (history.isNotEmpty) return history;
      return entry.rank == null
          ? const []
          : [
              LeaguePosition(
                round: latestRound,
                label: 'Actual',
                rank: entry.rank!,
              ),
            ];
    }

    final bars = <LineChartBarData>[];
    for (var i = 0; i < entries.length; i++) {
      final points = pointsFor(entries[i]);
      if (points.isEmpty) continue;
      bars.add(
        LineChartBarData(
          spots: [
            for (final p in points)
              FlSpot(p.round.toDouble(), (maxRank - p.rank + 1).toDouble()),
          ],
          color: _colors[i % _colors.length],
          barWidth: 2.4,
          isCurved: points.length > 2,
          curveSmoothness: .22,
          dotData: FlDotData(show: points.length <= 6),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'EVOLUCIÓN DE POSICIONES',
                  style: AppText.mono(9, color: AppColors.textSecondary),
                ),
              ),
              _WindowButton(
                label: '3',
                selected: raceWindow == 3,
                onTap: () => onWindowChanged(3),
              ),
              const SizedBox(width: 5),
              _WindowButton(
                label: '6',
                selected: raceWindow == 6,
                onTap: () => onWindowChanged(6),
              ),
              const SizedBox(width: 5),
              _WindowButton(
                label: 'Todo',
                selected: raceWindow == null,
                onTap: () => onWindowChanged(null),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (bars.isEmpty)
            Text(
              'El historial aparecerá cuando F1 Fantasy publique la primera carrera.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            SizedBox(
              height: 210,
              child: LineChart(
                LineChartData(
                  minX: minRound.toDouble(),
                  maxX: maxRound == minRound
                      ? maxRound + 1.0
                      : maxRound.toDouble(),
                  minY: 1,
                  maxY: maxRank.toDouble(),
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: AppColors.border1, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((spot) {
                        final rank = maxRank - spot.y.round() + 1;
                        return LineTooltipItem(
                          'P$rank',
                          AppText.mono(
                            10,
                            color: spot.bar.color ?? AppColors.lime,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value != value.roundToDouble() ||
                              value < 1 ||
                              value > maxRank) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            'P${maxRank - value.toInt() + 1}',
                            style: AppText.mono(8),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 25,
                        getTitlesWidget: (value, meta) {
                          final round = value.round();
                          if (value != round.toDouble() ||
                              !visibleRounds.contains(round)) {
                            return const SizedBox.shrink();
                          }
                          final label = labels[round] ?? 'R$round';
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label.length > 4
                                  ? 'R$round'
                                  : label.toUpperCase(),
                              style: AppText.mono(7),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: bars,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              for (var i = 0; i < entries.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _colors[i % _colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      entries[i].teamName.isEmpty
                          ? 'Equipo ${i + 1}'
                          : entries[i].teamName,
                      style: AppText.body(9.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WindowButton extends StatelessWidget {
  const _WindowButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(7),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.lime.withValues(alpha: .14)
            : AppColors.surface3,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: selected ? AppColors.lime : AppColors.border1,
        ),
      ),
      child: Text(
        label,
        style: AppText.mono(
          8,
          color: selected ? AppColors.lime : AppColors.textSecondary,
        ),
      ),
    ),
  );
}

class _TeamDetails extends StatelessWidget {
  const _TeamDetails({required this.entry});
  final FantasyLeagueEntry entry;

  static const _icons = <String, IconData>{
    'limitless': Icons.all_inclusive_rounded,
    'wildcard': Icons.shuffle_rounded,
    'triple_boost': Icons.bolt_rounded,
    'no_negative': Icons.shield_rounded,
    'final_fix': Icons.build_circle_rounded,
    'autopilot': Icons.auto_awesome_rounded,
  };

  String _slug(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface2,
      borderRadius: BorderRadius.circular(AppRadii.sm),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INTEGRANTES',
          style: AppText.mono(9, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        if (entry.members.isEmpty)
          Text(
            'F1 Fantasy no ha incluido la alineación de este equipo.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final member in entry.members)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface3,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        member.isConstructor
                            ? Icons.precision_manufacturing_rounded
                            : Icons.sports_motorsports_rounded,
                        size: 14,
                        color: member.isConstructor
                            ? AppColors.orange
                            : AppColors.cyan,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        member.name,
                        style: AppText.body(10.5, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        const SizedBox(height: 12),
        Text('CHIPS', style: AppText.mono(9, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final chip in GameRules.chipNames)
              _ChipState(
                label: chip,
                icon: _icons[_slug(chip)] ?? Icons.bolt_rounded,
                used: entry.chipsUsed.contains(_slug(chip)),
              ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          'Iluminado: disponible  ·  apagado: usado',
          style: AppText.body(9.5, color: AppColors.textTertiary),
        ),
      ],
    ),
  );
}

class _ChipState extends StatelessWidget {
  const _ChipState({
    required this.label,
    required this.icon,
    required this.used,
  });
  final String label;
  final IconData icon;
  final bool used;

  @override
  Widget build(BuildContext context) {
    final color = used ? AppColors.textTertiary : AppColors.lime;
    return AnimatedOpacity(
      opacity: used ? .38 : 1,
      duration: const Duration(milliseconds: 180),
      child: Container(
        width: 74,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: used ? .06 : .11),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: used ? .25 : .8)),
          boxShadow: used
              ? null
              : [BoxShadow(color: color.withValues(alpha: .2), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.mono(6.5, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
