import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/subscription_status.dart';
import '../../../core/utils/format.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/montant.dart';
import '../../../shared/widgets/ui.dart';
import '../../auth/presentation/session_controller.dart';
import '../../boutiques/presentation/boutique_context.dart';
import '../../boutiques/presentation/boutique_switcher.dart';
import '../../rappels/relance.dart';
import '../domain/dashboard.dart';
import 'recherche_date.dart';

final dashboardProvider = FutureProvider.autoDispose<Dashboard>((ref) {
  ref.watch(dataVersionProvider);
  return ref
      .read(dashboardRepositoryProvider)
      .load(boutiqueId: ref.watch(boutiqueFiltreProvider));
});

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final profil = ref.watch(profilProvider);
    return Scaffold(
      appBar: AppBar(title: const BoutiqueSwitcher(titre: 'Accueil')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dettes/nouvelle'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle dette'),
      ),
      body: dashboard.when(
        skipLoadingOnRefresh: true,
        loading: () => const LoadingState(),
        error:
            (e, _) => ErrorState(
              error: e,
              onRetry: () => ref.invalidate(dashboardProvider),
            ),
        data:
            (d) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(boutiquesProvider);
                ref.invalidate(activiteProvider);
                return ref.refresh(dashboardProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Gap.page,
                  Gap.xs,
                  Gap.page,
                  Gap.fab,
                ),
                children: [
                  _Salutation(prenom: profil?.firstName),
                  const SizedBox(height: Gap.lg),
                  if (profil?.isProprietaire == true)
                    _AbonnementBanner(d.subscription),
                  _TotalCard(d),
                  const SizedBox(height: Gap.md),
                  _Grille(
                    children: [
                      StatCard(
                        label: "Encaissé aujourd'hui",
                        value: fcfa(d.encaisseAujourdhui),
                        icon: Icons.south_west_rounded,
                        color: context.colors.success,
                      ),
                      StatCard(
                        label: 'Encaissé ce mois',
                        value: fcfa(d.encaisseMois),
                        icon: Icons.calendar_month_rounded,
                        color: context.colors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.md),
                  StatCard(
                    horizontal: true,
                    label: 'Clients',
                    value: '${d.clientsCount}',
                    icon: Icons.people_alt_rounded,
                    hint: '${d.clientsDebiteursCount} doivent encore',
                    onTap: () => context.go('/clients'),
                  ),
                  const RechercheParDate(),
                  SectionHeader(
                    'Dettes en cours',
                    action: TextButton(
                      onPressed: () => context.go('/dettes'),
                      child: const Text('Tout voir'),
                    ),
                    padding: const EdgeInsets.only(
                      top: Gap.xxl,
                      bottom: Gap.xs,
                    ),
                  ),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _StatutRow(StatutDette.enRetard, d.enRetard),
                        const Divider(indent: 68),
                        _StatutRow(StatutDette.aAujourdhui, d.aAujourdhui),
                        const Divider(indent: 68),
                        _StatutRow(StatutDette.enAttente, d.enAttente),
                      ],
                    ),
                  ),
                  SectionHeader(
                    'À relancer',
                    subtitle:
                        d.aRelancer.isEmpty
                            ? null
                            : 'Dettes échues, à rappeler à vos clients',
                  ),
                  if (d.aRelancer.isEmpty)
                    AppCard(
                      child: Row(
                        children: [
                          IconBadge(
                            Icons.verified_rounded,
                            color: context.colors.success,
                          ),
                          const SizedBox(width: Gap.md),
                          const Expanded(
                            child: Text('Aucune dette échue. Bravo !'),
                          ),
                        ],
                      ),
                    )
                  else
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final (i, dette)
                              in _parClient(d.aRelancer).indexed) ...[
                            if (i > 0) const Divider(indent: 72),
                            _ARelancerTile(dette),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }
}

/// « Bonjour Awa » et la date du jour.
class _Salutation extends StatelessWidget {
  const _Salutation({this.prenom});
  final String? prenom;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          date[0].toUpperCase() + date.substring(1),
          style: context.text.labelLarge?.copyWith(
            color: context.scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Gap.xxs),
        Text(
          'Bonjour ${prenom ?? ''} 👋',
          style: context.text.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Grille responsive des indicateurs : 2 colonnes, une seule sur très petit écran.
class _Grille extends StatelessWidget {
  const _Grille({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final columns = c.maxWidth >= 280 ? 2 : 1;
      final width = (c.maxWidth - (columns - 1) * Gap.md) / columns;
      final orphan = children.length % columns != 0;
      return Wrap(
        spacing: Gap.md,
        runSpacing: Gap.md,
        children: [
          for (final (i, child) in children.indexed)
            SizedBox(
              width: orphan && i == children.length - 1 ? c.maxWidth : width,
              child: child,
            ),
        ],
      );
    },
  );
}

/// Carte principale : total à récupérer et sa répartition par statut.
class _TotalCard extends StatelessWidget {
  const _TotalCard(this.d);
  final Dashboard d;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final on = colors.onHero;
    final count = d.enRetard.count + d.aAujourdhui.count + d.enAttente.count;
    final parts = [
      (StatutDette.enRetard, d.enRetard, const Color(0xFFFCA5A5)),
      (StatutDette.aAujourdhui, d.aAujourdhui, const Color(0xFFFCD34D)),
      (StatutDette.enAttente, d.enAttente, on.withValues(alpha: 0.55)),
    ];
    final somme = parts.fold<double>(0, (s, p) => s + p.$2.total);

    return Material(
      color: colors.hero,
      borderRadius: Radii.xlAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/dettes'),
        child: Stack(
          children: [
            // Motif discret : deux cercles en filigrane
            Positioned(
              right: -40,
              top: -60,
              child: _Cercle(180, on.withValues(alpha: 0.06)),
            ),
            Positioned(
              right: 40,
              bottom: -90,
              child: _Cercle(160, on.withValues(alpha: 0.04)),
            ),
            Padding(
              padding: const EdgeInsets.all(Gap.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total à récupérer',
                          style: context.text.labelLarge?.copyWith(
                            color: on.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: on.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.sm),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: d.totalARecuperer),
                    duration: Motion.slow,
                    curve: Motion.curve,
                    builder:
                        (context, value, _) => FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            fcfa(value),
                            style: context.text.headlineLarge?.copyWith(
                              color: on,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                  ),
                  const SizedBox(height: Gap.xs),
                  Text(
                    '$count dette(s) en cours',
                    style: context.text.bodyMedium?.copyWith(
                      color: on.withValues(alpha: 0.8),
                    ),
                  ),
                  if (somme > 0) ...[
                    const SizedBox(height: Gap.xl),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.pill),
                      child: SizedBox(
                        height: 8,
                        child: Row(
                          children: [
                            for (final (i, p) in parts.indexed)
                              if (p.$2.total > 0)
                                Expanded(
                                  flex: (p.$2.total / somme * 1000)
                                      .round()
                                      .clamp(1, 1000),
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      left: i == 0 ? 0 : 2,
                                    ),
                                    color: p.$3,
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Gap.md),
                    Wrap(
                      spacing: Gap.lg,
                      runSpacing: Gap.xs,
                      children: [
                        for (final p in parts)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: p.$3,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${p.$1 == StatutDette.aAujourdhui ? "Aujourd'hui" : p.$1.label} · ${p.$2.count}',
                                style: context.text.labelMedium?.copyWith(
                                  color: on.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
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

class _Cercle extends StatelessWidget {
  const _Cercle(this.size, this.color);
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Ligne d'un statut : nombre de dettes et montant, ouvre la liste filtrée.
class _StatutRow extends StatelessWidget {
  const _StatutRow(this.statut, this.compteur);
  final StatutDette statut;
  final CompteurStatut compteur;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final color = statut.couleur(scheme);
    return InkWell(
      onTap: () => context.go('/dettes?statut=${statut.value}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.lg,
          vertical: Gap.md,
        ),
        child: Row(
          children: [
            IconBadge(
              statut.icone,
              color: color,
              background: statut.fond(scheme),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statut.label,
                    style: context.text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${compteur.count} dette(s)',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            MontantText(
              compteur.total,
              style: context.text.bodyLarge,
              color: compteur.count > 0 ? color : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: Gap.xs),
            Icon(Icons.chevron_right_rounded, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}

/// Dettes échues d'un même client, cumulées : une ligne et une relance par client.
class _ClientARelancer {
  _ClientARelancer(DetteARelancer d)
    : clientId = d.clientId,
      clientNom = d.clientNom,
      montant = d.montantRestant,
      echeance = d.dateEcheance,
      statut = d.statut,
      dettes = 1;

  final int clientId;
  final String clientNom;
  double montant;
  DateTime? echeance;
  StatutDette statut;
  int dettes;

  void ajouter(DetteARelancer d) {
    montant += d.montantRestant;
    dettes++;
    if (d.dateEcheance != null &&
        (echeance == null || d.dateEcheance!.isBefore(echeance!))) {
      echeance = d.dateEcheance;
    }
    if (d.statut == StatutDette.enRetard) statut = StatutDette.enRetard;
  }
}

List<_ClientARelancer> _parClient(List<DetteARelancer> dettes) {
  final parClient = <int, _ClientARelancer>{};
  for (final d in dettes) {
    parClient.update(
      d.clientId,
      (c) => c..ajouter(d),
      ifAbsent: () => _ClientARelancer(d),
    );
  }
  return parClient.values.toList();
}

class _ARelancerTile extends StatelessWidget {
  const _ARelancerTile(this.client);
  final _ClientARelancer client;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/clients/${client.clientId}'),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.sm, Gap.md),
      child: Row(
        children: [
          InitialsAvatar(client.clientNom),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.clientNom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Gap.xxs),
                Text(
                  'Échéance : ${dateCourte(client.echeance)}',
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
                client.montant,
                color: client.statut.couleur(context.scheme),
              ),
              const SizedBox(height: Gap.xs),
              StatutBadge(client.statut),
            ],
          ),
          const SizedBox(width: Gap.xs),
          IconButton.filledTonal(
            tooltip: 'Relancer ${client.clientNom} sur WhatsApp',
            icon: const Icon(Icons.campaign_rounded),
            onPressed:
                () => relancerClient(
                  context,
                  clientId: client.clientId,
                  clientNom: client.clientNom,
                ),
          ),
        ],
      ),
    ),
  );
}

/// Forfait gratuit, essai ou échéance proche : invitation à choisir un forfait.
class _AbonnementBanner extends StatelessWidget {
  const _AbonnementBanner(this.status);
  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final expire = status.state == EtatAbonnement.expiring;
    if (!expire && !status.estOffert) return const SizedBox.shrink();
    final colors = context.colors;
    final jours = status.daysLeft ?? 0;
    final fg = expire ? colors.warning : colors.accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.md),
      child: AppCard(
        color: expire ? colors.warningContainer : colors.accentContainer,
        borderColor: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.sm, Gap.md),
        onTap: () => context.push('/compte/abonnement'),
        child: Row(
          children: [
            IconBadge(
              expire
                  ? Icons.warning_amber_rounded
                  : Icons.card_giftcard_rounded,
              color: fg,
              background: fg.withValues(alpha: 0.14),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expire
                        ? 'Votre abonnement se termine bientôt'
                        : 'Forfait ${status.plan} offert',
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: Gap.xxs),
                  Text(
                    'Encore $jours jour${jours > 1 ? 's' : ''} (jusqu\'au ${dateLongue(status.endsAt)}).',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: fg),
          ],
        ),
      ),
    );
  }
}
