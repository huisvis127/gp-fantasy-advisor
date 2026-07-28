import 'package:flutter/material.dart';

import '../../core/localization.dart';
import '../../core/theme.dart';

/// Componentes traducidos 1:1 del index.html de la app de referencia
/// (ver PLAN_DESARROLLO.md sección 1.1). Cada widget indica en su docstring
/// la clase CSS original que replica.

/// `.card` — tarjeta con gradiente surface-2 -> surface-1, borde b1,
/// radio 20 y sombra suave.
class RefCard extends StatelessWidget {
  const RefCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surface2, AppColors.surface1],
        ),
        border: Border.all(color: borderColor ?? AppColors.border1),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: const [
          BoxShadow(
              color: Color(0x2E000000), blurRadius: 50, offset: Offset(0, 18)),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

/// `.hero-card` — tarjeta destacada con velo de gradiente
/// lima -> cian -> magenta por encima.
class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surface2, AppColors.surface1],
        ),
        border: Border.all(color: AppColors.border1),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x21C8FF00), Color(0x0F00E5FF), Color(0x14FF3CB8)],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// `.eyebrow` / `.section-kicker` — etiqueta mono uppercase con tracking.
class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key, this.color = AppColors.lime});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(context.tr(text).toUpperCase(),
        style: AppText.mono(11, color: color));
  }
}

/// Cabecera de sección: kicker + título Syne (`.section-head`).
class SectionHead extends StatelessWidget {
  const SectionHead(
      {super.key, required this.kicker, required this.title, this.trailing});

  final String kicker;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Kicker(kicker, color: AppColors.textTertiary),
              const SizedBox(height: 4),
              Text(context.tr(title), style: AppText.syne(21)),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// `select` de la referencia: campo oscuro con flecha lima. Al tocar abre
/// un `PickerSheet` (mismo patrón que `.picker-sheet` del original).
class NeonSelect<T> extends StatelessWidget {
  const NeonSelect({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.itemColor,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;
  final Color Function(T)? itemColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr(label).toUpperCase(),
            style: AppText.body(11,
                    color: AppColors.textSecondary, weight: FontWeight.w600)
                .copyWith(letterSpacing: 0.6)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: items.isEmpty
              ? null
              : () async {
                  final selected = await showPickerSheet<T>(
                    context: context,
                    title: label,
                    items: items,
                    itemLabel: itemLabel,
                    selected: value,
                    itemColor: itemColor,
                  );
                  if (selected != null) onChanged(selected);
                },
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.surface3, AppColors.surface1],
              ),
              border: Border.all(color: AppColors.border1),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null ? '—' : itemLabel(value as T),
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(14, weight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded,
                    color: AppColors.lime, size: 26),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// `.picker-sheet` — hoja modal inferior con lista de opciones.
Future<T?> showPickerSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required String Function(T) itemLabel,
  T? selected,
  Color Function(T)? itemColor,
  String Function(T)? itemMeta,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Container(
        margin: const EdgeInsets.all(14),
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.76),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surface2, AppColors.surface1],
          ),
          border: Border.all(color: AppColors.border1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: AppText.syne(16))),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 7),
                itemBuilder: (_, i) {
                  final item = items[i];
                  final isActive = item == selected;
                  final barColor = itemColor?.call(item) ?? AppColors.violet;
                  return GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(item),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 54),
                      decoration: BoxDecoration(
                        color: AppColors.surface3,
                        border: Border.all(
                          color: isActive
                              ? AppColors.lime.withValues(alpha: 0.55)
                              : AppColors.border1,
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 38,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(itemLabel(item),
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.body(14,
                                        weight: FontWeight.w800)),
                                if (itemMeta != null)
                                  Text(itemMeta(item),
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.body(11,
                                          color: AppColors.textTertiary)),
                              ],
                            ),
                          ),
                          if (isActive)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Text('✓',
                                  style:
                                      AppText.mono(14, color: AppColors.lime)),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// `.sliderbox` — slider de peso con etiqueta y % a la derecha.
class SliderBox extends StatelessWidget {
  const SliderBox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.accent = AppColors.lime,
  });

  final String label;

  /// 0-100 (porcentaje).
  final double value;
  final ValueChanged<double> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppText.body(12.5, color: AppColors.textSecondary)),
            Text('${value.round()}%',
                style: AppText.body(12.5, weight: FontWeight.w800)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accent,
            thumbColor: accent,
            overlayColor: accent.withValues(alpha: 0.12),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value.clamp(0, 100),
            min: 0,
            max: 100,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// `.rec` — tarjeta de recomendación pequeña con borde/fondo de color
/// (pick lima, capitán cian, valor violeta, evitar rojo, marca naranja).
class RecCard extends StatelessWidget {
  const RecCard({
    super.key,
    required this.tag,
    required this.color,
    required this.name,
    required this.subtitle,
    required this.score,
  });

  final String tag;
  final Color color;
  final String name;
  final String subtitle;
  final String score;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 98),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr(tag).toUpperCase(), style: AppText.mono(9.5, color: color)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 64),
                child: Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.syne(17)),
              ),
              const SizedBox(height: 5),
              Text(subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(12.5, color: AppColors.textSecondary)),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Text(score, style: AppText.syne(21, color: color)),
          ),
        ],
      ),
    );
  }
}

/// `.chip` — pastilla pequeña uppercase con borde de color.
class TagChip extends StatelessWidget {
  const TagChip(this.label, {super.key, this.color = AppColors.textSecondary});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(
            color:
                color == AppColors.textSecondary ? AppColors.border1 : color),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(context.tr(label).toUpperCase(), style: AppText.mono(8.5, color: color)),
    );
  }
}

/// `.scbar` — barrita de puntuación con gradiente cian -> lima.
class ScoreBar extends StatelessWidget {
  const ScoreBar({super.key, required this.fraction, this.width = 60});

  final double fraction;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 5,
      decoration: BoxDecoration(
        color: AppColors.border1,
        borderRadius: BorderRadius.circular(99),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: fraction.clamp(0.02, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient:
                const LinearGradient(colors: [AppColors.cyan, AppColors.lime]),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }
}

/// `.vpill` — precio y puntos-por-millón.
class ValuePill extends StatelessWidget {
  const ValuePill(
      {super.key, required this.priceMillions, required this.pointsPerMillion});

  final double priceMillions;
  final double pointsPerMillion;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('${priceMillions.toStringAsFixed(1)} M\$',
            style: AppText.syne(12, color: AppColors.textSecondary)),
        const SizedBox(width: 6),
        Text('${pointsPerMillion.toStringAsFixed(2)} pts/M',
            style: AppText.body(10,
                color: AppColors.cyan, weight: FontWeight.w700)),
      ],
    );
  }
}

/// `.ri` — fila del ranking: puesto, barra de color del equipo, nombre,
/// chips, puntuación grande + scbar + vpill.
class RankingRow extends StatelessWidget {
  const RankingRow({
    super.key,
    required this.rank,
    required this.teamColor,
    required this.name,
    required this.teamName,
    required this.score,
    required this.maxScore,
    required this.priceMillions,
    this.chips = const <TagChip>[],
    this.onTap,
    this.expanded,
  });

  final int rank;
  final Color teamColor;
  final String name;
  final String teamName;
  final double score;
  final double maxScore;
  final double priceMillions;
  final List<TagChip> chips;
  final VoidCallback? onTap;
  final Widget? expanded;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface3,
          border: Border.all(color: AppColors.border1),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 5, color: teamColor),
                    const SizedBox(width: 7),
                    SizedBox(
                      width: 30,
                      child: Center(
                        child: Text(
                          '$rank',
                          style: AppText.syne(16,
                              color: rank <= 3
                                  ? AppColors.lime
                                  : AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body(14.5,
                                    weight: FontWeight.w600)),
                            Text(teamName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body(11,
                                    color: AppColors.textTertiary)),
                            if (chips.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Wrap(spacing: 5, runSpacing: 4, children: chips),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(score.toStringAsFixed(1),
                              style: AppText.syne(19)),
                          Text(
                            context.tr('PTS ESP.'),
                            style: AppText.mono(
                              8,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ScoreBar(
                              fraction: maxScore <= 0 ? 0 : score / maxScore),
                          const SizedBox(height: 4),
                          ValuePill(
                            priceMillions: priceMillions,
                            pointsPerMillion:
                                priceMillions <= 0 ? 0 : score / priceMillions,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (expanded != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: expanded!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.barrow` — barra horizontal del desglose "por qué" (una por feature).
class FeatureBarRow extends StatelessWidget {
  const FeatureBarRow({super.key, required this.label, required this.value});

  final String label;

  /// 0-100.
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 118,
            child: Text(context.tr(label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(11, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.border1,
                borderRadius: BorderRadius.circular(99),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (value / 100).clamp(0.02, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.cyan, AppColors.lime]),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 26,
            child: Text('${value.round()}',
                textAlign: TextAlign.right,
                style: AppText.body(11, color: AppColors.textTertiary)),
          ),
        ],
      ),
    );
  }
}

/// `.total-pill` — píldora grande con el total esperado.
class TotalPill extends StatelessWidget {
  const TotalPill({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.lime.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.lime),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.lime.withValues(alpha: 0.14), blurRadius: 24),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(value, style: AppText.syne(21, color: AppColors.lime)),
          const SizedBox(width: 8),
          Text(context.tr(label).toUpperCase(),
              style: AppText.mono(9, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// `.loaded-card` — carta de piloto/constructor del equipo.
class AssetCard extends StatelessWidget {
  const AssetCard({
    super.key,
    required this.tag,
    required this.name,
    required this.subtitle,
    required this.barColor,
    this.tagColor,
    this.onTap,
  });

  final String tag;
  final String name;
  final String subtitle;
  final Color barColor;
  final Color? tagColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.surface3,
          border: Border.all(color: AppColors.border1),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Row(
            children: [
              Container(width: 5, color: barColor),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr(tag).toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.mono(9,
                            color: tagColor ?? AppColors.textSecondary)),
                    const SizedBox(height: 5),
                    Text(name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.syne(15)),
                    const SizedBox(height: 4),
                    Text(context.tr(subtitle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppText.body(11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.transfer-note` — nota informativa lima (o roja si `isError`).
class TransferNote extends StatelessWidget {
  const TransferNote({super.key, required this.child, this.isError = false});

  final Widget child;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.lime;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isError ? 0.08 : 0.06),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: DefaultTextStyle(
        style: AppText.body(12, color: AppColors.textSecondary),
        child: child,
      ),
    );
  }
}

/// `.subtb` — subpestañas (Pilotos / Constructores).
class SubTabs extends StatelessWidget {
  const SubTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => onSelected(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: i == selectedIndex
                      ? AppColors.lime.withValues(alpha: 0.07)
                      : AppColors.surface3,
                  border: Border.all(
                    color:
                        i == selectedIndex ? AppColors.lime : AppColors.border1,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                alignment: Alignment.center,
                child: Text(
                  context.tr(labels[i]),
                  style: AppText.body(13,
                      weight: FontWeight.w600,
                      color: i == selectedIndex
                          ? AppColors.lime
                          : AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Banner de estado de sincronización (`.status` de la referencia, pero
/// siempre visible cuando hay algo que contar: sin fallos silenciosos).
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.isError = false,
    this.isLoading = false,
    this.onRetry,
  });

  final String message;
  final bool isError;
  final bool isLoading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.error.withValues(alpha: 0.08)
            : AppColors.surface2,
        border:
            Border.all(color: isError ? AppColors.error : AppColors.border1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        children: [
          if (isLoading)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.lime),
            )
          else
            Icon(
              isError
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline_rounded,
              size: 16,
              color: isError ? AppColors.error : AppColors.ok,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(context.tr(message),
                style: AppText.body(12,
                    color:
                        isError ? AppColors.error : AppColors.textSecondary)),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(context.tr('Reintentar'),
                  style: AppText.body(12, color: AppColors.cyan)),
            ),
        ],
      ),
    );
  }
}

/// Fondo con los brillos radiales de la referencia (lima arriba-izquierda,
/// cian arriba-derecha) sobre --bg.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.background),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.lime.withValues(alpha: 0.10),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -110,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.cyan.withValues(alpha: 0.09),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
