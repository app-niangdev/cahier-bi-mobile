import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/feedback.dart';
import 'paiement_sheet.dart';

/// Versement d'un client sur sa dette totale (toutes ses dettes cumulées) :
/// un seul paiement enregistré, quel que soit le nombre d'achats à crédit.
/// [totalDu] évite un rechargement quand la fiche du client est déjà affichée.
Future<void> encaisserClient(
  BuildContext context,
  WidgetRef ref, {
  required int clientId,
  required String clientNom,
  double? totalDu,
}) async {
  final repo = ref.read(clientRepositoryProvider);
  var total = totalDu;
  if (total == null) {
    try {
      total = (await repo.get(clientId)).totalDu;
    } catch (e) {
      if (context.mounted) showError(context, e);
      return;
    }
  }
  if (!context.mounted) return;
  if (total <= 0) {
    showSuccess(context, '$clientNom ne doit plus rien.');
    return;
  }

  final montant = await encaisser(
    context,
    titre: 'Versement de $clientNom',
    resteDu: total,
    enregistrer: (p) => repo.payer(clientId, p),
  );
  if (montant == null) return;

  ref.read(dataVersionProvider.notifier).bump();
  final reste = total - montant;
  if (context.mounted) {
    showSuccess(
      context,
      reste <= 0.001
          ? 'Versement de ${fcfa(montant)} enregistré : dette soldée.'
          : 'Versement de ${fcfa(montant)} enregistré. Reste ${fcfa(reste)}.',
    );
  }
}
