import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/domain/enums.dart';
import '../../core/utils/format.dart';
import 'ui.dart';

/// Montant en FCFA.
class MontantText extends StatelessWidget {
  const MontantText(this.montant, {super.key, this.style, this.color});

  final num montant;
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    fcfa(montant),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: (style ?? Theme.of(context).textTheme.bodyLarge)?.copyWith(
      color: color,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );
}

/// Pastille de statut d'une dette.
class StatutBadge extends StatelessWidget {
  const StatutBadge(this.statut, {super.key});

  final StatutDette statut;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = statut.couleur(scheme);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
      decoration: BoxDecoration(
        color: statut.fond(scheme),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            statut.labelCourt,
            semanticsLabel: statut.label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w600,
              decoration:
                  statut == StatutDette.annulee
                      ? TextDecoration.lineThrough
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicateur de l'accueil : icône, libellé, valeur et précision.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.hint,
    this.onTap,
    this.horizontal = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final String? hint;
  final VoidCallback? onTap;

  /// Disposition en ligne (indicateur sur toute la largeur).
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    if (horizontal) {
      return AppCard(
        onTap: onTap,
        child: Row(
          children: [
            IconBadge(icon, color: c, size: 44),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodySmall),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (hint != null)
              Pill(hint!, color: c, background: c.withValues(alpha: 0.1)),
            if (onTap != null) ...[
              const SizedBox(width: Gap.xs),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.outline,
              ),
            ],
          ],
        ),
      );
    }
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon, color: c, size: 36),
          const SizedBox(height: Gap.md),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: Gap.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: Gap.xxs),
            Text(
              hint!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: c),
            ),
          ],
        ],
      ),
    );
  }
}
