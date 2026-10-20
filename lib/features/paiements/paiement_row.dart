import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/domain/enums.dart';
import '../../shared/widgets/montant.dart';
import '../../shared/widgets/ui.dart';

/// Ligne d'un paiement reçu : moyen, montant, précisions et annulation (propriétaire).
class PaiementRow extends StatelessWidget {
  const PaiementRow({
    super.key,
    required this.montant,
    required this.methode,
    required this.lignes,
    this.onAnnuler,
  });

  final double montant;
  final MethodePaiement methode;
  final List<String> lignes;
  final VoidCallback? onAnnuler;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Gap.page,
        Gap.md,
        onAnnuler == null ? Gap.page : Gap.xs,
        Gap.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(
            methode.icone,
            color: colors.success,
            background: colors.successContainer,
            size: 44,
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MontantText(montant, color: colors.success),
                const SizedBox(height: Gap.xxs),
                Text(lignes.join('\n'), style: context.text.bodySmall),
              ],
            ),
          ),
          if (onAnnuler != null)
            IconButton(
              tooltip: 'Annuler ce versement',
              icon: const Icon(Icons.undo_rounded),
              color: context.scheme.onSurfaceVariant,
              onPressed: onAnnuler,
            ),
        ],
      ),
    );
  }
}
