import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/domain/enums.dart';
import '../../../core/utils/format.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/montant.dart';
import '../../../shared/widgets/ui.dart';
import '../../auth/presentation/session_controller.dart';
import '../../paiements/encaisser_client.dart';
import '../../rappels/relance.dart';
import '../domain/dette.dart';

final detteDetailProvider = FutureProvider.autoDispose.family<Dette, int>((
  ref,
  id,
) {
  ref.watch(dataVersionProvider);
  return ref.read(detteRepositoryProvider).get(id);
});

class DetteDetailPage extends ConsumerWidget {
  const DetteDetailPage({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dette = ref.watch(detteDetailProvider(id));
    final isProprietaire = ref.watch(profilProvider)?.isProprietaire ?? false;

    return dette.when(
      loading: () => Scaffold(appBar: AppBar(), body: const LoadingState()),
      error:
          (e, _) => Scaffold(
            appBar: AppBar(),
            body: ErrorState(
              error: e,
              onRetry: () => ref.invalidate(detteDetailProvider(id)),
            ),
          ),
      data: (d) {
        final ouverte = d.statut.estOuverte;
        final client = d.client;
        return Scaffold(
          appBar: AppBar(
            title: Text(d.reference),
            actions: [
              if (d.statut != StatutDette.annulee)
                IconButton(
                  tooltip: 'Modifier',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/dettes/${d.id}/modifier'),
                ),
              // Annulation réservée au propriétaire
              if (isProprietaire && ouverte)
                IconButton(
                  tooltip: 'Annuler la dette',
                  icon: const Icon(Icons.block_rounded),
                  onPressed: () => _annuler(context, ref, d),
                ),
              const SizedBox(width: Gap.xs),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              Gap.page,
              Gap.xs,
              Gap.page,
              Gap.xxxl,
            ),
            children: [
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Resume(dette: d),
                    if (client != null) ...[
                      if (ouverte) ...[
                        const SizedBox(height: Gap.lg),
                        // Le client paie sur sa dette totale, pas achat par achat
                        FilledButton.icon(
                          onPressed:
                              () => encaisserClient(
                                context,
                                ref,
                                clientId: client.id,
                                clientNom: client.nom,
                              ),
                          icon: const Icon(Icons.payments_rounded),
                          label: const Text('Encaisser un versement'),
                        ),
                        const SizedBox(height: Gap.sm),
                        OutlinedButton.icon(
                          onPressed:
                              () => relancerClient(
                                context,
                                clientId: client.id,
                                clientNom: client.nom,
                              ),
                          icon: const Icon(Icons.campaign_rounded),
                          label: const Text('Relancer sur WhatsApp'),
                        ),
                        const SizedBox(height: Gap.md),
                        const InfoNote(
                          'Le versement s\'applique à la dette totale du client, tous achats confondus.',
                        ),
                      ],
                      const SectionHeader('Paiements'),
                      AppCard(
                        onTap: () => context.push('/clients/${client.id}'),
                        child: Row(
                          children: [
                            IconBadge(
                              Icons.history_rounded,
                              color: context.colors.success,
                            ),
                            const SizedBox(width: Gap.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Versements de ${client.nom}',
                                    style: context.text.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Historique sur la fiche du client',
                                    style: context.text.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: context.scheme.outline,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _annuler(BuildContext context, WidgetRef ref, Dette d) async {
    if (d.paiements.isNotEmpty) {
      showError(
        context,
        'Cette dette a déjà reçu des paiements : annulez d\'abord les versements concernés.',
      );
      return;
    }
    final ok = await confirmer(
      context,
      titre: 'Annuler la dette ${d.reference} ?',
      message:
          'Le client ne devra plus ${fcfa(d.montant)} pour cet achat. Cette action est définitive.',
      confirmer: 'Annuler la dette',
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(detteRepositoryProvider).annuler(d.id);
      ref.read(dataVersionProvider.notifier).bump();
      if (context.mounted) showSuccess(context, 'Dette annulée.');
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

class _Resume extends StatelessWidget {
  const _Resume({required this.dette});
  final Dette dette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.colors;
    final progression =
        dette.montant <= 0
            ? 0.0
            : (dette.montantPaye / dette.montant).clamp(0.0, 1.0);
    final client = dette.client;

    return AppCard(
      padding: const EdgeInsets.all(Gap.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (client != null) ...[
                InitialsAvatar(client.nom),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: InkWell(
                    borderRadius: Radii.smAll,
                    onTap: () => context.push('/clients/${client.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.nom,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Voir la fiche client',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else
                const Spacer(),
              StatutBadge(dette.statut),
            ],
          ),
          const SizedBox(height: Gap.xl),
          Text('Reste à payer', style: theme.textTheme.bodySmall),
          const SizedBox(height: Gap.xxs),
          MontantText(
            dette.montantRestant,
            style: theme.textTheme.headlineMedium,
            color: dette.montantRestant > 0 ? colors.danger : colors.success,
          ),
          const SizedBox(height: Gap.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.pill),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progression),
              duration: Motion.slow,
              curve: Motion.curve,
              builder:
                  (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    color: colors.success,
                    backgroundColor: scheme.surfaceContainerHighest,
                    semanticsLabel: 'Part déjà payée',
                    semanticsValue: '${(progression * 100).round()} %',
                  ),
            ),
          ),
          const SizedBox(height: Gap.sm),
          Text(
            '${(progression * 100).round()} % remboursé',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Gap.lg),
          const Divider(),
          const SizedBox(height: Gap.xs),
          InfoRow(
            icon: Icons.receipt_long_outlined,
            label: 'Montant',
            value: MontantText(dette.montant),
          ),
          InfoRow(
            icon: Icons.check_circle_outline_rounded,
            label: 'Déjà payé',
            value: MontantText(dette.montantPaye, color: colors.success),
          ),
          InfoRow(
            icon: Icons.event_outlined,
            label: 'Date',
            value: Text(dateLongue(dette.dateCreation)),
          ),
          InfoRow(
            icon: Icons.event_available_outlined,
            label: 'Échéance',
            value: Text(dateLongue(dette.dateEcheance)),
          ),
          if (dette.note != null && dette.note!.isNotEmpty) ...[
            const SizedBox(height: Gap.sm),
            InfoNote(dette.note!, icon: Icons.sticky_note_2_outlined),
          ],
        ],
      ),
    );
  }
}
