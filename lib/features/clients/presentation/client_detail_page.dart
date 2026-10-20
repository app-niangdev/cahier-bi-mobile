import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/montant.dart';
import '../../../shared/widgets/ui.dart';
import '../../auth/presentation/session_controller.dart';
import '../../boutiques/presentation/boutique_context.dart';
import '../../dettes/presentation/dette_tile.dart';
import '../../paiements/annuler_versement.dart';
import '../../paiements/paiement_row.dart';
import '../../paiements/encaisser_client.dart';
import '../../rappels/relance.dart';
import '../domain/client.dart';

final clientDetailProvider = FutureProvider.autoDispose.family<Client, int>((
  ref,
  id,
) {
  ref.watch(dataVersionProvider);
  return ref.read(clientRepositoryProvider).get(id);
});

final versementsProvider = FutureProvider.autoDispose
    .family<List<Versement>, int>((ref, id) {
      ref.watch(dataVersionProvider);
      return ref.read(clientRepositoryProvider).versements(id);
    });

/// Fiche client : situation, dettes, versements, encaissement global et relance.
class ClientDetailPage extends ConsumerWidget {
  const ClientDetailPage({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientDetailProvider(id));
    return client.when(
      loading: () => Scaffold(appBar: AppBar(), body: const LoadingState()),
      error:
          (e, _) => Scaffold(
            appBar: AppBar(),
            body: ErrorState(
              error: e,
              onRetry: () => ref.invalidate(clientDetailProvider(id)),
            ),
          ),
      data:
          (c) => DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Fiche client'),
                actions: [
                  IconButton(
                    tooltip: 'Modifier',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => context.push('/clients/${c.id}/modifier'),
                  ),
                  IconButton(
                    tooltip: 'Supprimer',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _supprimer(context, ref, c),
                  ),
                  const SizedBox(width: Gap.xs),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed:
                    () => context.push('/dettes/nouvelle?client=${c.id}'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nouvelle dette'),
              ),
              body: NestedScrollView(
                headerSliverBuilder:
                    (context, _) => [
                      SliverToBoxAdapter(child: _Entete(client: c)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            Gap.page,
                            Gap.sm,
                            Gap.page,
                            Gap.xs,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(Gap.xs),
                            decoration: BoxDecoration(
                              color: context.scheme.surfaceContainerHigh,
                              borderRadius: Radii.mdAll,
                            ),
                            child: TabBar(
                              tabs: [
                                Tab(
                                  height: 40,
                                  text: 'Achats (${c.dettes.length})',
                                ),
                                const Tab(height: 40, text: 'Versements'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                body: TabBarView(
                  children: [_Dettes(client: c), _Versements(clientId: c.id)],
                ),
              ),
            ),
          ),
    );
  }

  Future<void> _supprimer(BuildContext context, WidgetRef ref, Client c) async {
    if (c.totalDu > 0) {
      showError(
        context,
        '${c.nom} doit encore ${fcfa(c.totalDu)} : impossible de le supprimer.',
      );
      return;
    }
    final ok = await confirmer(
      context,
      titre: 'Supprimer ${c.nom} ?',
      message: 'Sa fiche et son historique ne seront plus visibles.',
      confirmer: 'Supprimer',
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(clientRepositoryProvider).delete(c.id);
      ref.read(dataVersionProvider.notifier).bump();
      if (!context.mounted) return;
      showSuccess(context, 'Client supprimé.');
      context.pop();
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

class _Entete extends ConsumerWidget {
  const _Entete({required this.client});
  final Client client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.colors;
    final boutique =
        ref
            .watch(boutiquesProvider)
            .value
            ?.where((b) => b.id == client.boutiqueId)
            .firstOrNull;
    final ouvertes = client.dettes.where((d) => d.statut.estOuverte).toList();
    final doit = client.totalDu > 0;
    final peutRelancer = doit && client.numeroWhatsapp != null;

    void relancer() =>
        relancerClient(context, clientId: client.id, clientNom: client.nom);

    Future<void> encaisserVersement() => encaisserClient(
      context,
      ref,
      clientId: client.id,
      clientNom: client.nom,
      totalDu: client.totalDu,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.page, Gap.xs, Gap.page, Gap.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Identité
          Row(
            children: [
              InitialsAvatar(client.nom, size: 60),
              const SizedBox(width: Gap.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.nom,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: Gap.xxs),
                    Text(
                      client.telephone == null
                          ? 'Sans téléphone'
                          : formatTelephone(client.telephone),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (boutique != null) ...[
                      const SizedBox(height: Gap.xxs),
                      Row(
                        children: [
                          Icon(
                            Icons.storefront_rounded,
                            size: 14,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: Gap.xs),
                          Flexible(
                            child: Text(
                              boutique.nom,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.xl),
          // Solde
          AppCard(
            color: doit ? colors.dangerContainer : colors.successContainer,
            borderColor: Colors.transparent,
            padding: const EdgeInsets.all(Gap.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Dette totale',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: doit ? colors.danger : colors.success,
                        ),
                      ),
                    ),
                    if (doit)
                      Text(
                        'Sur ${ouvertes.length} achat(s) à crédit',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.danger,
                        ),
                      )
                    else
                      Icon(
                        Icons.verified_rounded,
                        size: 20,
                        color: colors.success,
                      ),
                  ],
                ),
                const SizedBox(height: Gap.xs),
                MontantText(
                  client.totalDu,
                  style: theme.textTheme.headlineMedium,
                  color: doit ? colors.danger : colors.success,
                ),
                if (doit) ...[
                  const SizedBox(height: Gap.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: encaisserVersement,
                      icon: const Icon(Icons.payments_rounded),
                      label: const Text('Encaisser un versement'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (client.telephone != null || peutRelancer) ...[
            const SizedBox(height: Gap.md),
            Row(
              children: [
                if (client.telephone != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => appeler(context, client.telephone),
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('Appeler'),
                    ),
                  ),
                if (client.telephone != null && peutRelancer)
                  const SizedBox(width: Gap.md),
                if (peutRelancer)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: relancer,
                      icon: const Icon(Icons.campaign_rounded),
                      label: const Text('Relancer'),
                    ),
                  ),
              ],
            ),
          ],
          if (client.adresse != null || client.note != null) ...[
            const SizedBox(height: Gap.md),
            AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: Gap.lg,
                vertical: Gap.sm,
              ),
              child: Column(
                children: [
                  if (client.adresse != null)
                    _Detail(Icons.place_outlined, client.adresse!),
                  if (client.adresse != null && client.note != null)
                    const Divider(indent: 30),
                  if (client.note != null)
                    _Detail(Icons.sticky_note_2_outlined, client.note!),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Gap.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: context.scheme.onSurfaceVariant),
        const SizedBox(width: Gap.md),
        Expanded(child: Text(text, style: context.text.bodyMedium)),
      ],
    ),
  );
}

class _Dettes extends StatelessWidget {
  const _Dettes({required this.client});
  final Client client;

  @override
  Widget build(BuildContext context) {
    if (client.dettes.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_rounded,
        titre: 'Aucun achat à crédit',
        message: 'Notez un achat à crédit avec « Nouvelle dette ».',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: Gap.xs, bottom: Gap.fab),
      itemCount: client.dettes.length,
      separatorBuilder:
          (_, __) => const Divider(indent: 72, endIndent: Gap.page),
      itemBuilder:
          (context, i) =>
              DetteTile(dette: client.dettes[i], afficherClient: false),
    );
  }
}

class _Versements extends ConsumerWidget {
  const _Versements({required this.clientId});
  final int clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versements = ref.watch(versementsProvider(clientId));
    final isProprietaire = ref.watch(profilProvider)?.isProprietaire ?? false;

    return versements.when(
      loading: () => const SkeletonList(count: 3),
      error:
          (e, _) => ErrorState(
            error: e,
            onRetry: () => ref.invalidate(versementsProvider(clientId)),
          ),
      data:
          (list) =>
              list.isEmpty
                  ? const EmptyState(
                    icon: Icons.payments_outlined,
                    titre: 'Aucun versement',
                    message: 'Les paiements de ce client apparaîtront ici.',
                  )
                  : ListView.separated(
                    padding: const EdgeInsets.only(
                      top: Gap.xs,
                      bottom: Gap.fab,
                    ),
                    itemCount: list.length,
                    separatorBuilder:
                        (_, __) =>
                            const Divider(indent: 72, endIndent: Gap.page),
                    itemBuilder: (context, i) {
                      final v = list[i];
                      return PaiementRow(
                        montant: v.montant,
                        methode: v.methode,
                        lignes: [
                          '${dateCourte(v.datePaiement)} · ${v.methode.label}',
                          if (v.reference != null) 'Réf. ${v.reference}',
                          if (v.enregistrePar != null) 'Par ${v.enregistrePar}',
                        ],
                        onAnnuler:
                            isProprietaire
                                ? () => annulerVersement(
                                  context,
                                  ref,
                                  v.versement,
                                  v.montant,
                                )
                                : null,
                      );
                    },
                  ),
    );
  }
}
