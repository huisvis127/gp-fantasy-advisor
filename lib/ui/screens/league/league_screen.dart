import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../widgets/ref_widgets.dart';
import '../login/fantasy_login_screen.dart';

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
      future: Future.wait([
        auth.readStoredToken(),
        auth.readSessionSnapshot(),
      ]),
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
        return _LeaguesList(token: token ?? '', snapshotRaw: snapshotRaw);
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
                          builder: (_) => const FantasyLoginScreen()),
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
  const _LeaguesList({required this.token, this.snapshotRaw});

  final String token;
  final String? snapshotRaw;

  @override
  ConsumerState<_LeaguesList> createState() => _LeaguesListState();
}

class _LeaguesListState extends ConsumerState<_LeaguesList> {
  late Future<Map<String, dynamic>> _request;
  Map<String, dynamic>? _snapshot;

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
        if (leagues.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(14),
            children: const [
              StatusBanner(
                message:
                    'La sesión es válida, pero la cuenta no devolvió ligas privadas.',
              ),
            ],
          );
        }

        return RefreshIndicator(
          color: AppColors.lime,
          onRefresh: () async {
            _retry();
            await _request;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              const SectionHead(
                kicker: 'Competición',
                title: 'Mis ligas',
              ),
              const SizedBox(height: 5),
              Text(
                'Toca una liga para consultar la clasificación.',
                style: AppText.body(12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              for (final league in leagues) ...[
                _leagueCard(league),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _leagueCard(Map<String, dynamic> league) {
    final id = _first(league, const ['league_id', 'leagueid', 'id']);
    final name = _first(league,
            const ['league_name', 'leaguename', 'name', 'display_name']) ??
        'Liga';
    final count =
        _first(league, const ['entry_count', 'entryCount', 'members_count']);
    final rank = _first(league, const ['rank', 'position', 'overall_rank']);
    return RefCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: id == null
            ? null
            : () => _openLeaderboard(id.toString(), name.toString()),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.lime.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.lime.withValues(alpha: .35)),
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: AppColors.lime),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.toString(),
                        style: AppText.body(14, weight: FontWeight.w700)),
                    if (count != null)
                      Text('$count participantes',
                          style:
                              AppText.body(11, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              if (rank != null) TagChip('#$rank', color: AppColors.cyan),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLeaderboard(String id, String name) async {
    final api = ref.read(fantasyApiProvider);
    final season = ref.read(currentSeasonProvider);
    final cachedLeaderboards = _snapshot?['leaderboards'];
    final cached = cachedLeaderboards is Map ? cachedLeaderboards[id] : null;
    final request = cached is Map
        ? Future.value(Map<String, dynamic>.from(cached))
        : api.getLeagueLeaderboard(
            season: season,
            leagueId: id,
            bearerToken: widget.token,
          );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      builder: (_) => _LeaderboardSheet(
        name: name,
        request: request,
      ),
    );
  }
}

class _LeaderboardSheet extends StatefulWidget {
  const _LeaderboardSheet({required this.name, required this.request});

  final String name;
  final Future<Map<String, dynamic>> request;

  @override
  State<_LeaderboardSheet> createState() => _LeaderboardSheetState();
}

class _LeaderboardSheetState extends State<_LeaderboardSheet> {
  int? _window = 6;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              decoration: BoxDecoration(
                  color: AppColors.border2,
                  borderRadius: BorderRadius.circular(9)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: Text(widget.name, style: AppText.syne(20))),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: widget.request,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  if (snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: StatusBanner(
                          message: 'No se pudo abrir la clasificación.',
                          isError: true),
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
                    return const Center(
                        child: Text('Sin participantes disponibles.'));
                  }
                  final rows = [
                    for (var index = 0; index < rawRows.length; index++)
                      _LeagueEntry.fromJson(rawRows[index], index + 1),
                  ];
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _PositionChart(
                          entries: rows,
                          window: _window,
                          onWindowChanged: (value) =>
                              setState(() => _window = value)),
                      const SizedBox(height: 12),
                      for (final entry in rows) ...[
                        _LeagueEntryCard(entry: entry),
                        const SizedBox(height: 7),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeagueEntry {
  const _LeagueEntry(
      {required this.rank,
      required this.name,
      required this.points,
      required this.members,
      required this.chipsUsed,
      required this.history});
  final int rank;
  final String name;
  final String? points;
  final List<String> members;
  final Set<String> chipsUsed;
  final List<({int round, int rank})> history;

  factory _LeagueEntry.fromJson(Map<String, dynamic> json, int fallbackRank) {
    final team = _map(_first(json, const ['team', 'entry', 'fantasy_team']));
    final rank = int.tryParse(
            (_first(json, const ['rank', 'position', 'overall_rank']) ??
                    fallbackRank)
                .toString()) ??
        fallbackRank;
    final name = (_first(json, const [
              'team_name',
              'entry_name',
              'display_name',
              'name',
              'user_name'
            ]) ??
            'Participante')
        .toString();
    final memberRows = _nestedList(
        [json, team], const ['players', 'picks', 'assets', 'lineup']);
    final members = memberRows
        .map((row) => (_first(row,
                    const ['display_name', 'full_name', 'name', 'team_name']) ??
                '')
            .toString())
        .where((name) => name.isNotEmpty)
        .toList();
    final used = <String>{};
    for (final source in [json, team]) {
      for (final key in const [
        'chips_used',
        'chipsUsed',
        'used_chips',
        'boosters_used',
        'chips',
        'boosters'
      ]) {
        final value = source[key];
        if (value is List) {
          used.addAll(value.map((item) => _slug(item is Map
              ? (_first(Map<String, dynamic>.from(item),
                      const ['name', 'chip', 'booster', 'type']) ??
                  '')
              : item.toString())));
        }
        if (value is String) used.addAll(value.split(',').map(_slug));
      }
    }
    final historyRows = _nestedList([
      json,
      team
    ], const [
      'rank_history',
      'position_history',
      'history',
      'rounds',
      'race_results'
    ]);
    final history = <({int round, int rank})>[];
    for (var index = 0; index < historyRows.length; index++) {
      final row = historyRows[index];
      final position = int.tryParse(
          (_first(row, const ['rank', 'position', 'league_rank']) ?? '')
              .toString());
      if (position == null || position < 1) continue;
      final round = int.tryParse(
              (_first(row, const ['round', 'gameweek', 'race_number']) ??
                      index + 1)
                  .toString()) ??
          index + 1;
      history.add((round: round, rank: position));
    }
    history.sort((a, b) => a.round.compareTo(b.round));
    return _LeagueEntry(
        rank: rank,
        name: name,
        points: _first(json, const [
          'points',
          'total_points',
          'score',
          'overall_points'
        ])?.toString(),
        members: members,
        chipsUsed: used.where((chip) => chip.isNotEmpty).toSet(),
        history: history);
  }
}

class _LeagueEntryCard extends StatefulWidget {
  const _LeagueEntryCard({required this.entry});
  final _LeagueEntry entry;
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
          child: Column(children: [
            Row(children: [
              SizedBox(
                  width: 35,
                  child: Text('#${entry.rank}',
                      style: AppText.mono(10, color: AppColors.lime))),
              Expanded(
                  child: Text(entry.name,
                      style: AppText.body(13, weight: FontWeight.w700))),
              if (entry.points != null)
                Text('${entry.points} pts',
                    style: AppText.mono(10, color: AppColors.cyan)),
              const SizedBox(width: 4),
              Icon(open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: AppColors.textTertiary),
            ]),
            if (open) ...[
              const Divider(height: 20),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('INTEGRANTES', style: AppText.mono(9))),
              const SizedBox(height: 7),
              if (entry.members.isEmpty)
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                        'La API no ha incluido la alineación de este equipo.',
                        style:
                            AppText.body(10.5, color: AppColors.textTertiary)))
              else
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final member in entry.members)
                    _Pill(label: member, color: AppColors.cyan)
                ]),
              const SizedBox(height: 12),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('CHIPS', style: AppText.mono(9))),
              const SizedBox(height: 7),
              Wrap(spacing: 7, runSpacing: 7, children: [
                for (final chip in _chips)
                  _ChipStatus(
                      label: chip, used: entry.chipsUsed.contains(_slug(chip)))
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}

const _chips = [
  'Limitless',
  'Wildcard',
  'Triple Boost',
  'No Negative',
  'Final Fix',
  'Autopilot'
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
                    : [
                        BoxShadow(
                            color: color.withValues(alpha: .18), blurRadius: 8)
                      ]),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_chipIcon(label), size: 14, color: color),
              const SizedBox(width: 4),
              Text(label.toUpperCase(), style: AppText.mono(6.5, color: color))
            ])));
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
          border: Border.all(color: color.withValues(alpha: .35))),
      child: Text(label, style: AppText.body(10.5, weight: FontWeight.w700)));
}

class _PositionChart extends StatelessWidget {
  const _PositionChart(
      {required this.entries,
      required this.window,
      required this.onWindowChanged});
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
              'El historial de posiciones aparecerá cuando F1 Fantasy lo incluya en la clasificación.');
    }
    final visible = window == null || rounds.length <= window!
        ? rounds
        : rounds.sublist(rounds.length - window!);
    final maxRank = entries
        .expand((entry) => entry.history.map((point) => point.rank))
        .fold(entries.length < 2 ? 2 : entries.length,
            (max, rank) => rank > max ? rank : max);
    final colors = [
      AppColors.lime,
      AppColors.cyan,
      AppColors.magenta,
      AppColors.orange,
      AppColors.violet
    ];
    return RefCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: Text('EVOLUCIÓN DE POSICIONES', style: AppText.mono(9))),
        _ChartButton(
            label: '3', active: window == 3, onTap: () => onWindowChanged(3)),
        const SizedBox(width: 4),
        _ChartButton(
            label: '6', active: window == 6, onTap: () => onWindowChanged(6)),
        const SizedBox(width: 4),
        _ChartButton(
            label: 'Todo',
            active: window == null,
            onTap: () => onWindowChanged(null))
      ]),
      const SizedBox(height: 10),
      SizedBox(
          height: 190,
          child: LineChart(LineChartData(
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
                      const FlLine(color: AppColors.border1)),
              titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 28,
                          getTitlesWidget: (value, _) =>
                              value == value.roundToDouble() && value >= 1 && value <= maxRank
                                  ? Text('P${maxRank - value.toInt() + 1}',
                                      style: AppText.mono(8))
                                  : const SizedBox.shrink())),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, _) => visible.contains(value.round())
                              ? Padding(padding: const EdgeInsets.only(top: 5), child: Text('R${value.round()}', style: AppText.mono(7)))
                              : const SizedBox.shrink()))),
              lineBarsData: [
                for (var i = 0; i < entries.length; i++)
                  if (entries[i].history.isNotEmpty)
                    LineChartBarData(
                        spots: [
                          for (final point in entries[i]
                              .history
                              .where((point) => point.round >= visible.first))
                            FlSpot(point.round.toDouble(),
                                (maxRank - point.rank + 1).toDouble())
                        ],
                        color: colors[i % colors.length],
                        barWidth: 2.3,
                        isCurved: true,
                        dotData: const FlDotData(show: false))
              ]))),
    ]));
  }
}

class _ChartButton extends StatelessWidget {
  const _ChartButton(
      {required this.label, required this.active, required this.onTap});
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
              border: Border.all(
                  color: active ? AppColors.lime : AppColors.border1)),
          child: Text(label,
              style: AppText.mono(7.5,
                  color: active ? AppColors.lime : AppColors.textSecondary))));
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
List<Map<String, dynamic>> _nestedList(
    List<Map<String, dynamic>> sources, List<String> keys) {
  for (final source in sources) {
    for (final key in keys) {
      final value = source[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }
  }
  return const [];
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
      _ => Icons.auto_awesome_rounded
    };

List<Map<String, dynamic>> _extractList(
    dynamic node, Set<String> preferredKeys) {
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
