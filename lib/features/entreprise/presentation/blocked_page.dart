import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/ui.dart';
import '../../auth/presentation/session_controller.dart';
import 'offres_view.dart';

/// Accès coupé : abonnement expiré, compte, entreprise ou boutique désactivés.
class BlockedPage extends ConsumerWidget {
  const BlockedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final code = session.error?.code;
    final theme = Theme.of(context);
    final abonnement = code == 'SUBSCRIPTION_EXPIRED';
    final (titre, icone) = switch (code) {
      'SUBSCRIPTION_EXPIRED' => (
        'Abonnement expiré',
        Icons.event_busy_outlined,
      ),
      'BOUTIQUE_DISABLED' => (
        'Boutique désactivée',
        Icons.store_mall_directory_outlined,
      ),
      _ => ('Compte désactivé', Icons.block_rounded),
    };
    final avecSession = ref.read(tokenStoreProvider).accessToken != null;

    final c = theme.colorScheme.error;

    return Scaffold(
      bottomNavigationBar: BottomActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (avecSession) ...[
              FilledButton.icon(
                onPressed: () => ref.read(sessionProvider.notifier).restore(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
              const SizedBox(height: Gap.sm),
            ],
            OutlinedButton(
              onPressed: () => ref.read(sessionProvider.notifier).logout(),
              child: Text(
                avecSession ? 'Se déconnecter' : 'Retour à la connexion',
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.xxl),
          children: [
            ContentWidth(
              maxWidth: 560,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: Gap.lg),
                  Center(
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.withValues(alpha: 0.06),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.withValues(alpha: 0.12),
                        ),
                        child: Icon(icone, size: 36, color: c),
                      ),
                    ),
                  ),
                  const SizedBox(height: Gap.xl),
                  Text(
                    titre,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Gap.sm),
                  Text(
                    session.error?.message ?? '',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  // Le gérant ne paie pas : il prévient son propriétaire
                  if (abonnement && session.profil?.isGerant != true) ...[
                    const SectionHeader(
                      'Réactivez votre accès',
                      subtitle: 'Choisissez un forfait pour continuer.',
                    ),
                    OffresView(nomEntreprise: session.profil?.tenantName),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
