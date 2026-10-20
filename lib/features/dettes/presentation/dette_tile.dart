import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../shared/widgets/montant.dart';
import '../../../shared/widgets/ui.dart';
import '../domain/dette.dart';

/// Ligne d'une dette : client (ou référence), échéance, reste à payer et statut.
class DetteTile extends StatelessWidget {
  const DetteTile({super.key, required this.dette, this.afficherClient = true});

  final Dette dette;
  final bool afficherClient;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final ouverte = dette.statut.estOuverte;
    final titre =
        afficherClient
            ? (dette.client?.nom ?? dette.reference)
            : dette.reference;
    return InkWell(
      onTap: () => context.push('/dettes/${dette.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.page,
          vertical: Gap.md,
        ),
        child: Row(
          children: [
            if (afficherClient && dette.client != null)
              InitialsAvatar(dette.client!.nom)
            else
              IconBadge(
                Icons.receipt_long_rounded,
                color: dette.statut.couleur(scheme),
                background: dette.statut.fond(scheme),
                size: 44,
              ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Gap.xxs),
                  Text(
                    [
                      if (afficherClient) dette.reference,
                      'Le ${dateCourte(dette.dateCreation)}',
                      if (dette.dateEcheance != null && ouverte)
                        'échéance ${dateCourte(dette.dateEcheance)}',
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Gap.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MontantText(
                  ouverte ? dette.montantRestant : dette.montant,
                  color: ouverte ? scheme.onSurface : scheme.outline,
                ),
                const SizedBox(height: Gap.xs),
                StatutBadge(dette.statut),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
