import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/domain/enums.dart';
import '../../../core/utils/format.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/ui.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/entreprise.dart';
import 'offres_view.dart';

final abonnementProvider = FutureProvider.autoDispose<AbonnementEntreprise>(
  (ref) => ref.read(entrepriseRepositoryProvider).abonnement(),
);

/// Forfait actuel, échéance, limite de gérants et offres disponibles.
class AbonnementPage extends ConsumerWidget {
  const AbonnementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abonnement = ref.watch(abonnementProvider);
    final tenantName = ref.watch(profilProvider)?.tenantName;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Abonnement')),
      body: abonnement.when(
        loading: () => const LoadingState(),
        error:
            (e, _) => ErrorState(
              error: e,
              onRetry: () => ref.invalidate(abonnementProvider),
            ),
        data: (a) {
          final s = a.status;
          final colors = context.colors;
          final (couleur, fond) = switch (s.state) {
            EtatAbonnement.active => (colors.success, colors.successContainer),
            EtatAbonnement.expiring => (
              colors.warning,
              colors.warningContainer,
            ),
            _ => (colors.danger, colors.dangerContainer),
          };
          final debut = s.startsAt, fin = s.endsAt;
          final progression =
              debut != null && fin != null && fin.isAfter(debut)
                  ? (DateTime.now().difference(debut).inHours /
                          fin.difference(debut).inHours)
                      .clamp(0.0, 1.0)
                  : null;

          return ListView(
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
                    AppCard(
                      padding: const EdgeInsets.all(Gap.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              IconBadge(
                                Icons.workspace_premium_rounded,
                                color: colors.accent,
                                background: colors.accentContainer,
                                size: 48,
                              ),
                              const SizedBox(width: Gap.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Votre forfait',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    Text(
                                      'Forfait ${s.plan ?? '—'}',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Gap.sm,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: fond,
                                  borderRadius: BorderRadius.circular(
                                    Radii.pill,
                                  ),
                                ),
                                child: Text(
                                  s.state.label,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: couleur,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (progression != null && s.state.estValide) ...[
                            const SizedBox(height: Gap.xl),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(Radii.pill),
                              child: LinearProgressIndicator(
                                value: progression,
                                minHeight: 6,
                                color: couleur,
                              ),
                            ),
                          ],
                          const SizedBox(height: Gap.md),
                          if (s.endsAt != null)
                            InfoRow(
                              icon: Icons.event_outlined,
                              label: 'Fin de période',
                              value: Text(
                                dateLongue(s.endsAt),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          if (s.daysLeft != null && s.state.estValide)
                            InfoRow(
                              icon: Icons.hourglass_bottom_rounded,
                              label: 'Temps restant',
                              value: Text(
                                '${s.daysLeft} jour(s)',
                                style: TextStyle(
                                  color: couleur,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          InfoRow(
                            icon: Icons.badge_outlined,
                            label: 'Gérants',
                            value: Text(
                              a.maxGerantsParBoutique == null
                                  ? 'Illimités par boutique'
                                  : '${a.maxGerantsParBoutique} max. par boutique',
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SectionHeader(
                      'Forfaits disponibles',
                      subtitle:
                          'Choisissez la formule adaptée à votre commerce.',
                    ),
                    OffresView(
                      forfaitActuel: s.plan,
                      nomEntreprise: tenantName,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
