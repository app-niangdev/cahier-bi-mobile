import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/ui.dart';
import '../../auth/presentation/session_controller.dart';
import 'boutique_context.dart';

/// Titre de l'en-tête : la boutique de travail. Le propriétaire qui en a plusieurs
/// choisit l'une d'elles ou « Toutes mes boutiques » ; le gérant est fixé sur la sienne.
class BoutiqueSwitcher extends ConsumerWidget {
  const BoutiqueSwitcher({super.key, required this.titre});

  final String titre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profil = ref.watch(profilProvider);
    final boutiques = ref.watch(boutiquesProvider).value ?? const [];
    final courante = ref.watch(boutiqueCouranteProvider);
    final peutChoisir = profil?.isProprietaire == true && boutiques.length > 1;
    final sousTitre =
        courante?.nom ??
        (boutiques.isEmpty
            ? (profil?.boutique?.nom ?? '')
            : 'Toutes mes boutiques');

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          titre,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (sousTitre.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storefront_rounded,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  sousTitre,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              if (peutChoisir)
                Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
      ],
    );

    if (!peutChoisir) return content;

    return Semantics(
      button: true,
      label: 'Changer de boutique',
      child: InkWell(
        borderRadius: Radii.smAll,
        onTap: () async {
          final choix = await showModalBottomSheet<int>(
            context: context,
            showDragHandle: true,
            builder: (context) {
              Widget option({
                required int value,
                required IconData icon,
                required String title,
                String? subtitle,
                required bool selected,
              }) {
                final scheme = context.scheme;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Gap.md,
                    vertical: 2,
                  ),
                  child: ListTile(
                    shape: const RoundedRectangleBorder(
                      borderRadius: Radii.mdAll,
                    ),
                    selected: selected,
                    selectedTileColor: scheme.primaryContainer,
                    selectedColor: scheme.onPrimaryContainer,
                    leading: IconBadge(icon, size: 36),
                    title: Text(title),
                    subtitle: subtitle == null ? null : Text(subtitle),
                    trailing:
                        selected
                            ? const Icon(Icons.check_circle_rounded)
                            : null,
                    onTap: () => Navigator.pop(context, value),
                  ),
                );
              }

              return SafeArea(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: Gap.lg),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: Gap.xxl),
                      child: SheetHeader(
                        title: 'Boutique affichée',
                        subtitle:
                            'Les chiffres et listes ne montrent que cette boutique.',
                      ),
                    ),
                    option(
                      value: -1,
                      icon: Icons.store_mall_directory_rounded,
                      title: 'Toutes mes boutiques',
                      selected: courante == null,
                    ),
                    for (final b in boutiques)
                      option(
                        value: b.id,
                        icon: Icons.storefront_rounded,
                        title: b.nom,
                        subtitle: b.lieu.isEmpty ? null : b.lieu,
                        selected: courante?.id == b.id,
                      ),
                  ],
                ),
              );
            },
          );
          if (choix != null) {
            await ref
                .read(boutiqueSelectionProvider.notifier)
                .select(choix == -1 ? null : choix);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      ),
    );
  }
}
