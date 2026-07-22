import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/league_selection_provider.dart';
import '../../../core/theme.dart';
import '../../../domain/services/league_snapshot_reader.dart';
import '../../widgets/ref_widgets.dart';
import '../login/fantasy_login_screen.dart';

const _leagueColors = [
  AppColors.lime,
  AppColors.cyan,
  AppColors.magenta,
  AppColors.orange,
  AppColors.violet,
];

class LeagueScreen extends ConsumerStatefulWidget {
  const LeagueScreen({super.key});

  @override
  ConsumerState<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends ConsumerState<LeagueScreen> {
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(fantasyAuthServiceProvider);
    return FutureBuilder<List<String?>>(
      key: ValueKey(_refreshKey),
      future: Future.wait([auth.readStoredToken(), auth.readSessionSnapshot()]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final token = snapshot.data?[0];
        final snapshotRaw = snapshot.data?[1];
        if ((token == null || token.isEmpty) &&
            (snapshotRaw == null || snapshotRaw.isEmpty)) {
          return _signedOut();
        }
        return _LeaguesList(
          token: token ?? '',
          snapshotRaw: snapshotRaw,
          onRefreshSession: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FantasyLoginScreen()),
            );
            if (mounted) setState(() => _refreshKey++);
          },
        );
      },
    );
  }

  Widget _signedOut() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
      children: [
        HeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Kicker('Clasificación privada'),
              const SizedBox(height: 6),
              Text('Tu liga', style: AppText.syne(32)),
              const SizedBox(height: 8),
              Text(
                'Accede con tu cuenta para ver tus ligas, posiciones y diferencias con el líder.',
                style: AppText.body(13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('INICIAR SESIÓN'),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FantasyLoginScreen(),
                      ),
                    );
                    if (mounted) setState(() => _refreshKey++);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaguesList extends ConsumerStatefulWidget {
  const _LeaguesList({
    required this.token,
    required this.onRefreshSession,
    this.snapshotRaw,
  });

  final String token;
  final String? snapshotRaw;
  final VoidCallback onRefreshSession;

  @override
  ConsumerState<_LeaguesList> createState() => _LeaguesListState();
}

class _LeaguesListState extends ConsumerState<_LeaguesList> {
  late Future<Map<String, dynamic>> _request;
  Map<String, dynamic>? _snapshot;
  final Map<String, Future<Map<String, dynamic>>> _leaderboardRequests = {};

  @override
  void initState() {
    super.initState();
    final raw = widget.snapshotRaw;
    if (raw != null && raw.isNotEmpty) {
      try {
        _snapshot = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        _snapshot = null;
      }
    }
    _load();
  }

  void _load() {
    final cachedLeagues = _snapshot?['leagues'];
    if (cachedLeagues is Map) {
      _request = Future.value(Map<String, dynamic>.from(cachedLeagues));
      return;
    }
    final api = ref.read(fantasyApiProvider);
    final season = ref.read(currentSeasonProvider);
    _request = api.getLeagueEntrants(season: season, bearerToken: widget.token);
  }

  void _retry() => setState(_load);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              StatusBanner(
                message:
                    'No se pudieron cargar tus ligas. La sesión puede haber caducado o el servicio no responde.',
                isError: true,
                onRetry: _retry,
              ),
            ],
          );
        }

        final leagues = _extractList(snapshot.data, const {
          'leagues',
          'league_entrants',
          'results',
          'details',
          'value',
        });
        final privateLeagues = leagues.where((league) {
          final count = _leagueMemberCount(league);
          return _isPrivateLeague(league) && (count == null || count <= 20);
        }).toList();
        if (privateLeagues.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(14),
            children: const [
              StatusBanner(
                message:
                    'No hay ligas privadas de hasta 20 integrantes. Las ligas generales se ocultan porque no aportan un análisis útil.',
              ),
            ],
          );
        }

        final storedSelectedId = ref.watch(selectedPrivateLeagueIdProvider);
        final availableIds = privateLeagues
            .map((league) =>
                _first(league, const ['league_id', 'leagueid', 'id'])
                    ?.toString())
            .whereType<String>()
            .toSet();
        final selectedId = availableIds.contains(storedSelectedId)
            ? storedSelectedId
            : availableIds.firstOrNull;
        final selectedLeague = selectedId == null
            ? null
            : privateLeagues.firstWhere(
                (league) =>
                    _first(league, const ['league_id', 'leagueid', 'id'])
                        ?.toString() ==
                    selectedId,
              );
        final selectedName = selectedLeague == null
            ? 'Liga privada'
            : cleanFantasyName(
                _first(selectedLeague, const [
                      'league_name',
                      'leaguename',
                      'name',
                      'display_name',
                    ]) ??
                    'Liga privada',
              );

        return RefreshIndicator(
          color: AppColors.lime,
          onRefresh: () async {
            _retry();
            await _request;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              const SectionHead(kicker: 'Competición privada', title: 'Liga'),
              const SizedBox(height: 5),
              Text(
                'Solo se muestran ligas privadas de hasta 20 integrantes.',
                style: AppText.body(12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              RefCard(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedId,
                  decoration: const InputDecoration(
                    labelText: 'Liga privada',
                    prefixIcon: Icon(Icons.emoji_events_rounded),
                  ),
                  items: [
                    for (final league in privateLeagues)
                      DropdownMenuItem(
                        value: _first(league, const [
                          'league_id',
                          'leagueid',
                          'id',
                        ]).toString(),
                        child: Text(
                          cleanFantasyName(_first(league, const [
                                'league_name',
                                'leaguename',
                                'name',
                                'display_name',
                              ]) ??
                              'Liga'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    ref.read(selectedPrivateLeagueIdProvider.notifier).state =
                        value;
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: widget.onRefreshSession,
                icon: const Icon(Icons.sync_rounded, size: 17),
                label: const Text('ACTUALIZAR DATOS DE LIGA'),
              ),
              if (selectedId != null) ...[
                const SizedBox(height: 14),
                SectionHead(
                  kicker: 'Clasificación y evolución',
                  title: selectedName,
                ),
                const SizedBox(height: 10),
                _LeaderboardSection(
                  key: ValueKey(selectedId),
                  request: _leaderboardRequest(selectedId),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _leaderboardRequest(String id) {
    return _leaderboardRequests.putIfAbsent(id, () {
      final api = ref.read(fantasyApiProvider);
      final season = ref.read(currentSeasonProvider);
      final cachedLeaderboards = _snapshot?['leaderboards'];
      final cached = cachedLeaderboards is Map ? cachedLeaderboards[id] : null;
      return cached is Map
          ? Future.value(Map<String, dynamic>.from(cached))
          : api.getLeagueLeaderboard(
              season: season,
              leagueId: id,
              bearerToken: widget.token,
            );
    });
  }
}

class _LeaderboardSection extends StatefulWidget {
  const _LeaderboardSection({super.key, required this.request});

  final Future<Map<String, dynamic>> request;

  @override
  State<_LeaderboardSection> createState() => _LeaderboardSectionState();
}

class _LeaderboardSectionState extends State<_LeaderboardSection> {
  int? _window = 6;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: widget.request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasError) {
          return const StatusBanner(
            message: 'No se pudo abrir la clasificación.',
            isError: true,
          );
        }
        final rawRows = _extractList(snapshot.data, const {
          'leaderboards',
          'leaderboard',
          'entries',
          'results',
          'member',
          'details',
          'value',
        });
        if (rawRows.isEmpty) {
          return const StatusBanner(
            message: 'Sin participantes disponibles. Actualiza la liga.',
          );
        }
        final enrichedRows = _enrichLeagueRows(snapshot.data, rawRows);
        final rows = [
          for (var index = 0; index < enrichedRows.length; index++)
            _LeagueEntry.fromJson(enrichedRows[index], index + 1),
        ];
        return Column(
          children: [
            _PositionChart(
              entries: rows,
              window: _window,
              onWindowChanged: (value) => setState(() => _window = value),
            ),
            const SizedBox(height: 12),
            _PointsChart(entries: rows, window: _window),
            const SizedBox(height: 12),
            _RacePositionTable(entries: rows),
            const SizedBox(height: 12),
            for (var i = 0; i < rows.length; i++) ...[
              _LeagueEntryCard(
                entry: rows[i],
                color: _leagueColors[i % _leagueColors.length],
              ),
              const SizedBox(height: 7),
            ],
          ],
        );
      },
    );
  }
}

class _LeagueEntry {
  const _LeagueEntry({
    required this.rank,
    required this.name,
    required this.points,
    required this.members,
    required this.chipsUsed,
    required this.history,
    required this.pointsHistory,
  });
  final int rank;
  final String name;
  final String? points;
  final List<String> members;
  final Set<String> chipsUsed;
  final List<({int round, int rank})> history;
  final List<({int round, double points})> pointsHistory;

  factory _LeagueEntry.fromJson(Map<String, dynamic> json, int fallbackRank) {
    final team = _map(_first(json, const ['team', 'entry', 'fantasy_team']));
    final rank = int.tryParse(
          (_first(json, const [
                    'rank',
                    'position',
                    'overall_rank',
                    'cur_rank',
                  ]) ??
                  fallbackRank)
              .toString(),
        ) ??
        fallbackRank;
    final name = cleanFantasyName(
      _first(json, const [
            'team_name',
            'entry_name',
            'display_name',
            'name',
            'user_name',
          ]) ??
          'Participante',
    );
    final memberRows = _nestedList(
      [json, team],
      const [
        'players',
        'picks',
        'assets',
        'lineup',
        'pickedplayers',
        'picked_players',
        'playerspicked',
      ],
    );
    final members = memberRows
        .map(
          (row) => cleanFantasyName(
            _first(row, const [
                  'display_name',
                  'displayname',
                  'full_name',
                  'fullname',
                  'name',
                  'playername',
                  'drivername',
                  'team_name',
                  'teamname',
                ]) ??
                '',
          ),
        )
        .where((name) => name.isNotEmpty)
        .toList();
    final used = <String>{};
    _collectUsedChips(json, used);
    _collectUsedChips(team, used);
    final historyRows = _nestedList(
      [json, team],
      const [
        'rank_history',
        'position_history',
        'history',
        'rounds',
        'race_results',
      ],
    );
    final history = <({int round, int rank})>[];
    final pointsHistory = <({int round, double points})>[];
    for (var index = 0; index < historyRows.length; index++) {
      final row = historyRows[index];
      final position = int.tryParse(
        (_first(row, const ['rank', 'position', 'league_rank']) ?? '')
            .toString(),
      );
      if (position == null || position < 1) continue;
      final round = int.tryParse(
            (_first(row, const ['round', 'gameweek', 'race_number']) ??
                    index + 1)
                .toString(),
          ) ??
          index + 1;
      history.add((round: round, rank: position));
      final points = double.tryParse(
        (_first(row, const ['points', 'cur_points', 'score']) ?? '').toString(),
      );
      if (points != null) pointsHistory.add((round: round, points: points));
    }
    history.sort((a, b) => a.round.compareTo(b.round));
    pointsHistory.sort((a, b) => a.round.compareTo(b.round));
    var accumulatedPoints = 0.0;
    final accumulatedHistory = <({int round, double points})>[];
    for (final point in pointsHistory) {
      accumulatedPoints += point.points;
      accumulatedHistory.add((round: point.round, points: accumulatedPoints));
    }
    return _LeagueEntry(
      rank: rank,
      name: name,
      points: _first(json, const [
        'points',
        'cur_points',
        'total_points',
        'score',
        'overall_points',
      ])?.toString(),
      members: members,
      chipsUsed: used.where((chip) => chip.isNotEmpty).toSet(),
      history: history,
      pointsHistory: accumulatedHistory,
    );
  }
}

class _RacePositionTable extends StatelessWidget {
  const _RacePositionTable({required this.entries});

  final List<_LeagueEntry> entries;

  @override
  Widget build(BuildContext context) {
    final rounds = entries
        .expand((entry) => entry.history.map((point) => point.round))
        .toSet()
        .toList()
      ..sort();
    if (rounds.isEmpty) return const SizedBox.shrink();

    Color medalColor(int? rank) => switch (rank) {
          1 => const Color(0xFFFFD54F),
          2 => const Color(0xFFCFD8DC),
          3 => const Color(0xFFCD7F32),
          _ => AppColors.textSecondary,
        };

    return RefCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MEDALLERO · POSICIÓN POR CARRERA', style: AppText.mono(9)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 34,
              dataRowMinHeight: 34,
              dataRowMaxHeight: 38,
              horizontalMargin: 8,
              columnSpacing: 18,
              columns: [
                DataColumn(label: Text('EQUIPO', style: AppText.mono(7.5))),
                for (final round in rounds)
                  DataColumn(label: Text('R$round', style: AppText.mono(7.5))),
              ],
              rows: [
                for (var i = 0; i < entries.length; i++)
                  DataRow(cells: [
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 135),
                        child: Text(
                          entries[i].name,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(9.5,
                              color: _leagueColors[i % _leagueColors.length],
                              weight: FontWeight.w700),
                        ),
                      ),
                    ),
                    for (final round in rounds)
                      DataCell(Builder(builder: (_) {
                        final matches = entries[i]
                            .history
                            .where((point) => point.round == round);
                        final rank =
                            matches.isEmpty ? null : matches.first.rank;
                        return Text(
                          rank == null ? '—' : 'P$rank',
                          style: AppText.mono(8.5, color: medalColor(rank)),
                        );
                      })),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeagueEntryCard extends StatefulWidget {
  const _LeagueEntryCard({required this.entry, required this.color});
  final _LeagueEntry entry;
  final Color color;
  @override
  State<_LeagueEntryCard> createState() => _LeagueEntryCardState();
}

class _LeagueEntryCardState extends State<_LeagueEntryCard> {
  bool open = false;
  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return RefCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: () => setState(() => open = !open),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 35,
                    child: Text(
                      '#${entry.rank}',
                      style: AppText.mono(10, color: AppColors.lime),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.name,
                      style: AppText.body(13,
                          color: widget.color, weight: FontWeight.w700),
                    ),
                  ),
                  if (entry.points != null)
                    Text(
                      '${entry.points} pts',
                      style: AppText.mono(10, color: AppColors.cyan),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              if (open) ...[
                const Divider(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('INTEGRANTES', style: AppText.mono(9)),
                ),
                const SizedBox(height: 7),
                if (entry.members.isEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'La API no ha incluido la alineación de este equipo.',
                      style: AppText.body(10.5, color: AppColors.textTertiary),
                    ),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final member in entry.members)
                        _Pill(label: member, color: AppColors.cyan),
                    ],
                  ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('CHIPS', style: AppText.mono(9)),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final chip in _chips)
                      _ChipStatus(
                        label: chip,
                        used: entry.chipsUsed.contains(_slug(chip)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

const _chips = [
  'Limitless',
  'Wildcard',
  'Extra DRS',
  'No Negative',
  'Final Fix',
  'Autopilot',
];

class _ChipStatus extends StatelessWidget {
  const _ChipStatus({required this.label, required this.used});
  final String label;
  final bool used;
  @override
  Widget build(BuildContext context) {
    final color = used ? AppColors.textTertiary : AppColors.lime;
    return Opacity(
      opacity: used ? .35 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: .65)),
          boxShadow: used
              ? null
              : [BoxShadow(color: color.withValues(alpha: .18), blurRadius: 8)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_chipIcon(label), size: 14, color: color),
            const SizedBox(width: 4),
            Text(label.toUpperCase(), style: AppText.mono(6.5, color: color)),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Text(label, style: AppText.body(10.5, weight: FontWeight.w700)),
      );
}

class _PositionChart extends StatelessWidget {
  const _PositionChart({
    required this.entries,
    required this.window,
    required this.onWindowChanged,
  });
  final List<_LeagueEntry> entries;
  final int? window;
  final ValueChanged<int?> onWindowChanged;
  @override
  Widget build(BuildContext context) {
    final rounds = entries
        .expand((entry) => entry.history.map((point) => point.round))
        .toSet()
        .toList()
      ..sort();
    if (rounds.isEmpty) {
      return const StatusBanner(
        message:
            'El historial de posiciones aparecerá cuando F1 Fantasy lo incluya en la clasificación.',
      );
    }
    final visible = window == null || rounds.length <= window!
        ? rounds
        : rounds.sublist(rounds.length - window!);
    final maxRank = entries
        .expand((entry) => entry.history.map((point) => point.rank))
        .fold(
          entries.length < 2 ? 2 : entries.length,
          (max, rank) => rank > max ? rank : max,
        );
    return RefCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('EVOLUCIÓN DE POSICIONES', style: AppText.mono(9)),
              ),
              _ChartButton(
                label: '3',
                active: window == 3,
                onTap: () => onWindowChanged(3),
              ),
              const SizedBox(width: 4),
              _ChartButton(
                label: '6',
                active: window == 6,
                onTap: () => onWindowChanged(6),
              ),
              const SizedBox(width: 4),
              _ChartButton(
                label: 'Todo',
                active: window == null,
                onTap: () => onWindowChanged(null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ChartLegend(entries: entries, colors: _leagueColors),
          const SizedBox(height: 10),
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                minX: visible.first.toDouble(),
                maxX: visible.last == visible.first
                    ? visible.last + 1.0
                    : visible.last.toDouble(),
                minY: 1,
                maxY: maxRank.toDouble(),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.border1),
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
                      reservedSize: 28,
                      getTitlesWidget: (value, _) =>
                          value == value.roundToDouble() &&
                                  value >= 1 &&
                                  value <= maxRank
                              ? Text(
                                  'P${maxRank - value.toInt() + 1}',
                                  style: AppText.mono(8),
                                )
                              : const SizedBox.shrink(),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, _) =>
                          visible.contains(value.round())
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(
                                    'R${value.round()}',
                                    style: AppText.mono(7),
                                  ),
                                )
                              : const SizedBox.shrink(),
                    ),
                  ),
                ),
                lineBarsData: [
                  for (var i = 0; i < entries.length; i++)
                    if (entries[i].history.isNotEmpty)
                      LineChartBarData(
                        spots: [
                          for (final point in entries[i].history.where(
                                (point) => point.round >= visible.first,
                              ))
                            FlSpot(
                              point.round.toDouble(),
                              (maxRank - point.rank + 1).toDouble(),
                            ),
                        ],
                        color: _leagueColors[i % _leagueColors.length],
                        barWidth: 2.3,
                        isCurved: false,
                        dotData: const FlDotData(show: false),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsChart extends StatelessWidget {
  const _PointsChart({required this.entries, required this.window});

  final List<_LeagueEntry> entries;
  final int? window;

  @override
  Widget build(BuildContext context) {
    final rounds = entries
        .expand((entry) => entry.pointsHistory.map((point) => point.round))
        .toSet()
        .toList()
      ..sort();
    if (rounds.isEmpty) {
      return const StatusBanner(
        message: 'Los puntos por carrera aparecerán tras actualizar la liga.',
      );
    }
    final visible = window == null || rounds.length <= window!
        ? rounds
        : rounds.sublist(rounds.length - window!);
    final values = entries
        .expand((entry) => entry.pointsHistory)
        .where((point) => visible.contains(point.round))
        .map((point) => point.points)
        .toList();
    final rawMin = values.reduce((a, b) => a < b ? a : b);
    final rawMax = values.reduce((a, b) => a > b ? a : b);
    final span = (rawMax - rawMin).abs();
    final interval = span <= 40
        ? 10.0
        : span <= 100
            ? 25.0
            : span <= 250
                ? 50.0
                : 100.0;
    final minY = (rawMin / interval).floorToDouble() * interval;
    var maxY = (rawMax / interval).ceilToDouble() * interval;
    if (maxY <= minY) maxY = minY + interval;
    return RefCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PUNTOS ACUMULADOS', style: AppText.mono(9)),
          const SizedBox(height: 10),
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                minX: visible.first.toDouble(),
                maxX: visible.last == visible.first
                    ? visible.last + 1.0
                    : visible.last.toDouble(),
                minY: minY,
                maxY: maxY,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.border1),
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
                      interval: interval,
                      reservedSize: 34,
                      getTitlesWidget: (value, _) => Text(
                        value.round().toString(),
                        style: AppText.mono(7),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, _) =>
                          visible.contains(value.round())
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(
                                    'R${value.round()}',
                                    style: AppText.mono(7),
                                  ),
                                )
                              : const SizedBox.shrink(),
                    ),
                  ),
                ),
                lineBarsData: [
                  for (var i = 0; i < entries.length; i++)
                    if (entries[i].pointsHistory.isNotEmpty)
                      LineChartBarData(
                        spots: [
                          for (final point in entries[i].pointsHistory.where(
                                (point) => visible.contains(point.round),
                              ))
                            FlSpot(point.round.toDouble(), point.points),
                        ],
                        color: _leagueColors[i % _leagueColors.length],
                        barWidth: 2.3,
                        isCurved: false,
                        dotData: const FlDotData(show: false),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.entries, required this.colors});

  final List<_LeagueEntry> entries;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 5,
        children: [
          for (var i = 0; i < entries.length; i++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors[i % colors.length],
                  ),
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    entries[i].name,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(8.5, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
        ],
      );
}

class _ChartButton extends StatelessWidget {
  const _ChartButton({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: BoxDecoration(
            color: active
                ? AppColors.lime.withValues(alpha: .12)
                : AppColors.surface3,
            borderRadius: BorderRadius.circular(7),
            border:
                Border.all(color: active ? AppColors.lime : AppColors.border1),
          ),
          child: Text(
            label,
            style: AppText.mono(
              7.5,
              color: active ? AppColors.lime : AppColors.textSecondary,
            ),
          ),
        ),
      );
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
List<Map<String, dynamic>> _nestedList(
  List<Map<String, dynamic>> sources,
  List<String> keys,
) {
  for (final source in sources) {
    final result = _findNamedList(
      source,
      keys.map((key) => key.toLowerCase()).toSet(),
    );
    if (result.isNotEmpty) return result;
  }
  return const [];
}

List<Map<String, dynamic>> _findNamedList(dynamic node, Set<String> keys) {
  if (node is Map) {
    for (final entry in node.entries) {
      if (keys.contains(entry.key.toString().toLowerCase()) &&
          entry.value is List) {
        final rows = (entry.value as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        if (rows.isNotEmpty) return rows;
      }
    }
    for (final value in node.values) {
      final rows = _findNamedList(value, keys);
      if (rows.isNotEmpty) return rows;
    }
  } else if (node is List) {
    for (final value in node) {
      final rows = _findNamedList(value, keys);
      if (rows.isNotEmpty) return rows;
    }
  }
  return const [];
}

void _collectUsedChips(dynamic node, Set<String> output) {
  if (node is Map) {
    for (final entry in node.entries) {
      final key = entry.key.toString().toLowerCase();
      final isChipField = key.contains('chip') || key.contains('booster');
      final value = entry.value;
      if (isChipField && value is String && value.isNotEmpty) {
        output.addAll(value.split(',').map(_slug));
      } else if (isChipField && value is List) {
        for (final item in value) {
          if (item is Map) {
            final name = _first(Map<String, dynamic>.from(item), const [
              'name',
              'chip',
              'booster',
              'type',
              'boostername',
            ]);
            final active = _first(Map<String, dynamic>.from(item), const [
              'used',
              'isused',
              'activated',
              'gamedayid',
            ]);
            if (name != null && active != false && active != 0) {
              output.add(_slug(name.toString()));
            }
          } else {
            output.add(_slug(item.toString()));
          }
        }
      }
      _collectUsedChips(value, output);
    }
  } else if (node is List) {
    for (final value in node) {
      _collectUsedChips(value, output);
    }
  }
}

List<Map<String, dynamic>> _enrichLeagueRows(
  Map<String, dynamic>? response,
  List<Map<String, dynamic>> currentRows,
) {
  if (response == null) return currentRows;
  final roundsRaw = response['rounds'];
  final teamsRaw = response['teams'];
  final rounds = roundsRaw is Map
      ? Map<String, dynamic>.from(roundsRaw)
      : const <String, dynamic>{};
  final teams = teamsRaw is Map
      ? Map<String, dynamic>.from(teamsRaw)
      : const <String, dynamic>{};

  return currentRows.map((original) {
    final row = Map<String, dynamic>.from(original);
    final key = _leagueMemberKey(row);
    final history = <Map<String, dynamic>>[];
    for (final roundEntry in rounds.entries) {
      final round = int.tryParse(roundEntry.key);
      if (round == null) continue;
      final roundRows = _extractList(roundEntry.value, const {
        'leaderboards',
        'leaderboard',
        'entries',
        'results',
        'member',
        'details',
        'value',
      });
      for (final roundRow in roundRows) {
        if (_leagueMemberKey(roundRow) != key) continue;
        final rank = _first(roundRow, const [
          'rank',
          'cur_rank',
          'position',
          'overall_rank',
          'overallrank',
          'leaguerank',
        ]);
        if (rank != null) {
          history.add({
            'round': round,
            'rank': rank,
            'points': _first(roundRow, const ['points', 'cur_points', 'score']),
          });
        }
        break;
      }
    }
    if (history.isNotEmpty) row['rank_history'] = history;
    final team = teams[key] ??
        teams[_first(row, const ['teamid', 'entryid', 'userid'])?.toString()];
    if (team is Map) row['team'] = Map<String, dynamic>.from(team);
    return row;
  }).toList();
}

String _leagueMemberKey(Map<String, dynamic> row) {
  final id = _first(row, const [
    'teamid',
    'team_id',
    'entryid',
    'entry_id',
    'userid',
    'user_id',
    'userguid',
    'user_guid',
    'user_team',
    'guid',
    'managerid',
  ]);
  if (id != null && id.toString().isNotEmpty) return id.toString();
  return (_first(row, const [
            'team_name',
            'teamname',
            'entry_name',
            'entryname',
            'display_name',
            'displayname',
            'name',
            'user_name',
            'username',
          ]) ??
          '')
      .toString()
      .trim()
      .toLowerCase();
}

int? _leagueMemberCount(Map<String, dynamic> league) => int.tryParse(
      (_first(league, const [
                'entry_count',
                'entrycount',
                'members_count',
                'memberscount',
                'membercount',
                'member_count',
                'totalmembers',
                'leaguesize',
              ]) ??
              '')
          .toString(),
    );

bool _isPrivateLeague(Map<String, dynamic> league) {
  final explicitPrivate = _first(league, const [
    'isprivateleague',
    'isprivate',
    'private',
  ]);
  if (explicitPrivate == true || explicitPrivate?.toString() == '1') {
    return true;
  }
  final explicitGlobal = _first(league, const [
    'isgloballeague',
    'isglobal',
    'global',
  ]);
  if (explicitGlobal == true || explicitGlobal?.toString() == '1') return false;
  final type =
      (_first(league, const ['leaguetype', 'league_type', 'type']) ?? '')
          .toString()
          .toLowerCase();
  if (type.isNotEmpty) return type.contains('private');
  return !type.contains('global') && !type.contains('general');
}

String _slug(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');
IconData _chipIcon(String chip) => switch (_slug(chip)) {
      'limitless' => Icons.all_inclusive_rounded,
      'wildcard' => Icons.shuffle_rounded,
      'triple_boost' => Icons.bolt_rounded,
      'no_negative' => Icons.shield_rounded,
      'final_fix' => Icons.build_circle_rounded,
      'extra_drs' => Icons.speed_rounded,
      _ => Icons.auto_awesome_rounded,
    };

List<Map<String, dynamic>> _extractList(
  dynamic node,
  Set<String> preferredKeys,
) {
  if (node is Map) {
    for (final entry in node.entries) {
      if (preferredKeys.contains(entry.key.toString().toLowerCase()) &&
          entry.value is List) {
        final maps = (entry.value as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (maps.isNotEmpty) return maps;
      }
    }
    for (final value in node.values) {
      final result = _extractList(value, preferredKeys);
      if (result.isNotEmpty) return result;
    }
  } else if (node is List) {
    final maps =
        node.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    if (maps.isNotEmpty) return maps;
  }
  return const [];
}

dynamic _first(Map<String, dynamic> map, List<String> keys) {
  final wanted = keys.map((key) => key.toLowerCase()).toSet();
  for (final entry in map.entries) {
    if (!wanted.contains(entry.key.toLowerCase())) continue;
    final value = entry.value;
    if (value != null && value.toString().isNotEmpty) return value;
  }
  return null;
}
