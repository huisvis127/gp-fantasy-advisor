import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/app_providers.dart';
import '../../../core/app_locale.dart';
import '../../../core/theme.dart';
import '../../../domain/models/live_fantasy.dart';
import '../../../domain/models/my_team.dart';
import '../../widgets/ref_widgets.dart';

class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Theme.of(context);
    final live = ref.watch(liveFantasyProvider);
    final team = ref.watch(myTeamProvider).valueOrNull;
    final strings = AppStrings(ref.watch(appLocaleProvider));
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        live.when(
          data: (snapshot) => _content(context, ref, snapshot, team, strings),
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.magenta,
              ),
            ),
          ),
          error: (error, _) => StatusBanner(
            message: '${strings.t('live_unavailable')}: $error',
            isError: true,
            onRetry: () => ref.invalidate(liveFantasyProvider),
          ),
        ),
      ],
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    LiveFantasySnapshot snapshot,
    MyTeam? team,
    AppStrings strings,
  ) {
    final updated = DateFormat('HH:mm:ss').format(snapshot.updatedAt);
    final ownAssets = team == null
        ? const <LiveAssetScore>[]
        : snapshot.assets
              .where(
                (asset) =>
                    team.driverIds.contains(asset.assetId) ||
                    team.constructorIds.contains(asset.assetId),
              )
              .toList();
    var teamPoints = ownAssets.fold<double>(
      0,
      (sum, asset) => sum + asset.points,
    );
    final boosted = team?.boostedDriverId;
    if (boosted != null) {
      teamPoints += snapshot.assets
          .where((asset) => asset.assetId == boosted)
          .fold<double>(0, (sum, asset) => sum + asset.points);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: snapshot.isLive
                          ? AppColors.error
                          : AppColors.textTertiary,
                      shape: BoxShape.circle,
                      boxShadow: snapshot.isLive
                          ? [BoxShadow(color: AppColors.error, blurRadius: 10)]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Kicker(
                    snapshot.isLive
                        ? strings.t('live_now')
                        : strings.t('latest_official'),
                    color: snapshot.isLive
                        ? AppColors.error
                        : AppColors.textTertiary,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: strings.t('refresh_now'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => ref.invalidate(liveFantasyProvider),
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: AppColors.cyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(snapshot.meetingName, style: AppText.syne(18)),
              const SizedBox(height: 3),
              Text(
                '${snapshot.sessionName} · ${strings.t('updated')} $updated',
                style: AppText.body(11, color: AppColors.textSecondary),
              ),
              if (team != null && team.isComplete) ...[
                const SizedBox(height: 14),
                Text(
                  teamPoints.toStringAsFixed(0),
                  style: AppText.syne(36, color: AppColors.lime),
                ),
                Text(
                  strings.t('provisional_team_points'),
                  style: AppText.mono(9, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        StatusBanner(message: strings.t('live_caution')),
        const SizedBox(height: 12),
        SectionHead(
          kicker: strings.t('provisional_ranking'),
          title: team == null
              ? strings.t('all_assets')
              : strings.t('team_and_leaders'),
        ),
        const SizedBox(height: 8),
        for (final asset in _visibleAssets(snapshot.assets, ownAssets)) ...[
          _LiveAssetCard(
            asset: asset,
            isOwned: ownAssets.any((item) => item.assetId == asset.assetId),
            strings: strings,
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  List<LiveAssetScore> _visibleAssets(
    List<LiveAssetScore> all,
    List<LiveAssetScore> owned,
  ) {
    final result = <LiveAssetScore>[];
    final seen = <String>{};
    for (final asset in [...owned, ...all.take(10)]) {
      if (seen.add(asset.assetId)) result.add(asset);
    }
    result.sort((a, b) => b.points.compareTo(a.points));
    return result;
  }
}

class _LiveAssetCard extends StatelessWidget {
  const _LiveAssetCard({
    required this.asset,
    required this.isOwned,
    required this.strings,
  });

  final LiveAssetScore asset;
  final bool isOwned;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final completedSessions = asset.sessions
        .where((session) => session.points != null)
        .map(
          (session) =>
              '${session.sessionName} ${session.points!.toStringAsFixed(0)}',
        )
        .join(' · ');
    return RefCard(
      padding: const EdgeInsets.all(13),
      borderColor: isOwned
          ? AppColors.lime.withValues(alpha: 0.38)
          : AppColors.border1,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(asset.displayName, style: AppText.syne(13)),
                    ),
                    if (isOwned) ...[
                      const SizedBox(width: 6),
                      TagChip(
                        strings.t('your_team_tag'),
                        color: AppColors.lime,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  completedSessions.isEmpty
                      ? '${strings.t('selection')} ${asset.selectedPercentage.toStringAsFixed(0)}%'
                      : completedSessions,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(10, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                asset.points.toStringAsFixed(0),
                style: AppText.syne(18, color: AppColors.cyan),
              ),
              Text(
                strings.t('points'),
                style: AppText.mono(8, color: AppColors.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
