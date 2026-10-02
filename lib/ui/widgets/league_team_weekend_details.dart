import 'package:flutter/material.dart';

import '../../core/league_colors.dart';
import '../../core/theme.dart';
import '../../domain/models/league_team_details.dart';

String leaguePointsLabel(double? points) => points == null
    ? 'Pendiente'
    : '${points == points.roundToDouble() ? points.toInt() : points.toStringAsFixed(1)} pts';

class LeagueTeamStandingCard extends StatelessWidget {
  const LeagueTeamStandingCard({
    super.key,
    required this.name,
    required this.rank,
    required this.totalPoints,
    required this.color,
    required this.details,
    required this.onChooseColor,
    required this.onRefresh,
  });

  final String name;
  final int rank;
  final double? totalPoints;
  final Color color;
  final LeagueTeamDetails details;
  final VoidCallback onChooseColor;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final textColor = LeagueColors.textColor(
      color,
      Theme.of(context).brightness,
    );
    return Material(
      color: AppColors.surface1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: .5)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: textColor,
          collapsedIconColor: textColor,
          leading: Text('#$rank', style: AppText.mono(11, color: textColor)),
          title: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(13, weight: FontWeight.w700, color: textColor),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fin de semana: ${leaguePointsLabel(details.weekendPoints)}',
                style: AppText.body(
                  11,
                  color: textColor,
                  weight: FontWeight.w700,
                ),
              ),
              Text(
                'Temporada: ${leaguePointsLabel(totalPoints)}',
                style: AppText.body(10, color: textColor),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Cambiar color de $name',
                icon: Icon(Icons.palette_outlined, color: textColor, size: 19),
                onPressed: onChooseColor,
              ),
              Icon(Icons.expand_more_rounded, color: textColor, size: 20),
            ],
          ),
          children: [
            LeagueTeamWeekendDetails(
              details: details,
              color: color,
              onRefresh: onRefresh,
            ),
          ],
        ),
      ),
    );
  }
}

class LeagueTeamWeekendDetails extends StatelessWidget {
  const LeagueTeamWeekendDetails({
    super.key,
    required this.details,
    required this.color,
    required this.onRefresh,
  });

  final LeagueTeamDetails details;
  final Color color;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final textColor = LeagueColors.textColor(
      color,
      Theme.of(context).brightness,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: color.withValues(alpha: .25)),
        Text(
          'PUNTOS DEL FIN DE SEMANA · GP ${details.gameDayId}',
          style: AppText.mono(9, color: textColor),
        ),
        const SizedBox(height: 6),
        Text(
          leaguePointsLabel(details.weekendPoints),
          style: AppText.syne(22, color: textColor),
        ),
        const SizedBox(height: 10),
        if (!details.available || details.assets.isEmpty) ...[
          Text(
            'La captura no incluye la alineación de este equipo. '
            'Actualiza la liga para consultar los pilotos y constructores disponibles.',
            style: AppText.body(12, color: AppColors.textSecondary),
          ),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.sync_rounded, size: 16),
            label: const Text('Actualizar alineaciones'),
          ),
        ] else ...[
          Text(
            'Pilotos',
            style: AppText.body(12, color: textColor, weight: FontWeight.w700),
          ),
          for (final asset in details.drivers) _assetRow(asset, textColor),
          const SizedBox(height: 10),
          Text(
            'Constructores',
            style: AppText.body(12, color: textColor, weight: FontWeight.w700),
          ),
          for (final asset in details.constructors) _assetRow(asset, textColor),
          const SizedBox(height: 6),
          Text(
            'Puntos oficiales del GP capturado. Las cifras pueden cambiar '
            'hasta que se publique el resultado definitivo.',
            style: AppText.body(10, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _assetRow(LeagueTeamAssetDetails asset, Color textColor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                asset.name,
                style: AppText.body(12, color: textColor),
              ),
            ),
            if (asset.boostMultiplier > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '×${asset.boostMultiplier.toInt()}',
                  style: AppText.mono(10, color: textColor),
                ),
              ),
            Text(
              leaguePointsLabel(asset.boostedPoints),
              style: AppText.body(
                12,
                color: textColor,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (asset.sessions.isNotEmpty)
          Wrap(
            spacing: 10,
            runSpacing: 3,
            children: [
              for (final session in asset.sessions)
                Text(
                  '${session.name}: ${leaguePointsLabel(session.points)}',
                  style: AppText.body(10, color: AppColors.textSecondary),
                ),
            ],
          ),
      ],
    ),
  );
}
