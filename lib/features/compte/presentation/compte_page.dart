import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/config.dart';
import '../../../core/utils/format.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/ui.dart';
import '../../auth/presentation/session_controller.dart';

/// Compte : profil, entreprise et abonnement (propriétaire), déconnexion.
class ComptePage extends ConsumerWidget {
  const ComptePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(profilProvider);
    if (profil == null) return const Scaffold(body: LoadingState());
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rattachement =
        profil.isGerant
            ? profil.boutique?.nom
            : (profil.isProprietaire ? profil.tenantName : null);

    return Scaffold(
      appBar: AppBar(title: const Text('Compte')),
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
                AppCard(
                  padding: const EdgeInsets.all(Gap.xl),
                  child: Row(
                    children: [
                      InitialsAvatar(profil.nomAffiche, size: 64),
                      const SizedBox(width: Gap.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profil.nomAffiche,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: Gap.xxs),
                            Text(
                              formatTelephone(profil.phone),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: Gap.sm),
                            Wrap(
                              spacing: Gap.sm,
                              runSpacing: Gap.xs,
                              children: [
                                _Etiquette(
                                  profil.role.label,
                                  Icons.verified_user_outlined,
                                ),
                                if (rattachement != null)
                                  _Etiquette(
                                    rattachement,
                                    Icons.storefront_outlined,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionHeader('Mon compte'),
                _Groupe(
                  children: [
                    _Reglage(
                      icon: Icons.person_outline_rounded,
                      title: 'Mes informations',
                      subtitle: 'Téléphone secondaire, adresse',
                      onTap: () => context.push('/compte/profil'),
                    ),
                    _Reglage(
                      icon: Icons.lock_outline_rounded,
                      title: 'Changer mon mot de passe',
                      onTap: () => context.push('/compte/mot-de-passe'),
                    ),
                  ],
                ),
                if (profil.isProprietaire) ...[
                  const SectionHeader('Mon commerce'),
                  _Groupe(
                    children: [
                      _Reglage(
                        icon: Icons.business_outlined,
                        title: 'Mon entreprise',
                        subtitle: 'Nom, contacts, informations légales',
                        onTap: () => context.push('/compte/entreprise'),
                      ),
                      _Reglage(
                        icon: Icons.workspace_premium_outlined,
                        color: context.colors.accent,
                        title: 'Abonnement',
                        subtitle:
                            profil.subscription?.plan == null
                                ? null
                                : 'Forfait ${profil.subscription!.plan}',
                        onTap: () => context.push('/compte/abonnement'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: Gap.xxl),
                _Groupe(
                  children: [
                    _Reglage(
                      icon: Icons.logout_rounded,
                      color: scheme.error,
                      title: 'Se déconnecter',
                      danger: true,
                      onTap: () => deconnecter(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.xxl),
                Center(
                  child: Opacity(
                    opacity: 0.7,
                    child: Column(
                      children: [
                        const BrandMark(size: 24),
                        const SizedBox(height: Gap.xs),
                        Text(
                          'Version $appVersion',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Etiquette extends StatelessWidget {
  const _Etiquette(this.label, this.icon);
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 3),
    decoration: BoxDecoration(
      color: context.scheme.primaryContainer,
      borderRadius: BorderRadius.circular(Radii.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.scheme.onPrimaryContainer),
        const SizedBox(width: Gap.xs),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelMedium?.copyWith(
              color: context.scheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Groupe de réglages dans une carte, séparés par un trait fin.
class _Groupe extends StatelessWidget {
  const _Groupe({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0) const Divider(indent: 68),
          child,
        ],
      ],
    ),
  );
}

class _Reglage extends StatelessWidget {
  const _Reglage({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.color,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;
  final bool danger;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: IconBadge(icon, color: color, size: 36),
    title: Text(
      title,
      style: danger ? TextStyle(color: context.scheme.error) : null,
    ),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing:
        danger
            ? null
            : Icon(Icons.chevron_right_rounded, color: context.scheme.outline),
  );
}

/// Déconnexion après confirmation.
Future<void> deconnecter(BuildContext context, WidgetRef ref) async {
  final ok = await confirmer(
    context,
    titre: 'Se déconnecter ?',
    message: 'Vous devrez saisir à nouveau votre numéro et votre mot de passe.',
    confirmer: 'Se déconnecter',
  );
  if (ok) await ref.read(sessionProvider.notifier).logout();
}
