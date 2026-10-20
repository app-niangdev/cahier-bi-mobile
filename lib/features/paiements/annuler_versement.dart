import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/feedback.dart';

/// Annule un versement entier (toutes ses lignes) après confirmation. Propriétaire seulement.
Future<void> annulerVersement(
  BuildContext context,
  WidgetRef ref,
  String versement,
  double montant,
) async {
  final ok = await confirmer(
    context,
    titre: 'Annuler ce versement ?',
    message:
        'Le versement de ${fcfa(montant)} sera retiré et les dettes concernées redeviendront dues.',
    confirmer: 'Annuler le versement',
  );
  if (!ok || !context.mounted) return;
  try {
    await ref.read(detteRepositoryProvider).annulerVersement(versement);
    ref.read(dataVersionProvider.notifier).bump();
    if (context.mounted) showSuccess(context, 'Versement annulé.');
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
}
