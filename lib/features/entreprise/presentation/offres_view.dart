import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/ui.dart';
import '../domain/entreprise.dart';

final offresProvider = FutureProvider.autoDispose<Offres>(
  (ref) => ref.read(entrepriseRepositoryProvider).offres(),
);

/// Forfaits proposés et contact pour payer (Wave, Orange Money…).
class OffresView extends ConsumerWidget {
  const OffresView({super.key, this.forfaitActuel, this.nomEntreprise});

  final String? forfaitActuel;
  final String? nomEntreprise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offres = ref.watch(offresProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return offres.when(
      loading: () => const LoadingState(),
      error:
          (e, _) => ErrorState(
            error: e,
            onRetry: () => ref.invalidate(offresProvider),
          ),
      data:
          (o) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final f in o.forfaits) ...[
                _ForfaitCard(forfait: f, actuel: f.name == forfaitActuel),
                const SizedBox(height: Gap.md),
              ],
              const SizedBox(height: Gap.sm),
              AppCard(
                color: scheme.primaryContainer,
                borderColor: Colors.transparent,
                padding: const EdgeInsets.all(Gap.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconBadge(
                          Icons.support_agent_rounded,
                          color: scheme.onPrimaryContainer,
                          size: 40,
                        ),
                        const SizedBox(width: Gap.md),
                        Expanded(
                          child: Text(
                            'Pour changer de forfait ou renouveler',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Gap.md),
                    Text(
                      'Payez par ${o.moyensPaiement ?? 'Wave ou Orange Money'} puis contactez ${o.contactNom ?? "l'administrateur"} : votre abonnement est activé dès réception.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    if (o.contactWhatsapp != null ||
                        o.contactTelephone != null) ...[
                      const SizedBox(height: Gap.lg),
                      FilledButton.icon(
                        onPressed: () => _contacter(context, o),
                        icon: const Icon(Icons.chat_rounded),
                        label: Text(
                          'Contacter ${formatTelephone(o.contactWhatsapp ?? o.contactTelephone)}',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _contacter(BuildContext context, Offres o) async {
    final numero = nationalNumber(o.contactWhatsapp);
    final message =
        'Bonjour, je souhaite souscrire un forfait Cahier Bi${nomEntreprise == null ? '' : ' pour $nomEntreprise'}.';
    final uri =
        numero != null
            ? Uri.parse(
              'https://wa.me/221$numero?text=${Uri.encodeComponent(message)}',
            )
            : Uri(scheme: 'tel', path: o.contactTelephone);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      showError(context, 'Impossible d\'ouvrir WhatsApp sur cet appareil.');
    }
  }
}

/// Carte d'un forfait : prix mis en avant, durée et avantages.
class _ForfaitCard extends StatelessWidget {
  const _ForfaitCard({required this.forfait, required this.actuel});

  final Forfait forfait;
  final bool actuel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final f = forfait;
    final avantages = [
      f.gerantsLibelle,
      if (f.description != null && f.description!.isNotEmpty) f.description!,
    ];
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: Radii.lgAll,
        border: Border.all(
          color: actuel ? scheme.primary : scheme.outlineVariant,
          width: actuel ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(Gap.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  f.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (actuel)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Gap.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Text(
                    'Actuel',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: f.price == 0 ? 'Gratuit' : fcfa(f.price),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                TextSpan(
                  text: ' / ${f.dureeLibelle}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.md),
          for (final a in avantages)
            Padding(
              padding: const EdgeInsets.only(top: Gap.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: context.colors.success,
                  ),
                  const SizedBox(width: Gap.sm),
                  Expanded(child: Text(a, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
