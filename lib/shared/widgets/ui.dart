import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Composants d'interface communs à tous les écrans.

/// Logo de Cahier Bi : un cahier dans un carré arrondi.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.25),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.menu_book_rounded,
        color: scheme.onPrimary,
        size: size * 0.55,
      ),
    );
    if (!showName) return Semantics(label: 'Cahier Bi', child: mark);
    return Semantics(
      label: 'Cahier Bi',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            mark,
            SizedBox(width: size * 0.25),
            Text(
              'Cahier Bi',
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                fontSize: size * 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte de contenu : surface claire, bordure fine, action au toucher optionnelle.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Gap.lg),
    this.onTap,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Material(
      color: color ?? scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.lgAll,
        side: BorderSide(color: borderColor ?? scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Titre de section, avec une action facultative à droite.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.action,
    this.padding = const EdgeInsets.only(top: Gap.xxl, bottom: Gap.md),
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: Gap.xxs),
                Text(subtitle!, style: context.text.bodySmall),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    ),
  );
}

/// Pastille d'icône teintée.
class IconBadge extends StatelessWidget {
  const IconBadge(
    this.icon, {
    super.key,
    this.color,
    this.background,
    this.size = 40,
  });

  final IconData icon;
  final Color? color;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.scheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: c, size: size * 0.52),
    );
  }
}

/// Teintes douces des avatars, choisies d'après le nom (toujours la même pour un client).
const _avatarTints = [
  Color(0xFF0F766E),
  Color(0xFF2563EB),
  Color(0xFF7C3AED),
  Color(0xFFDB2777),
  Color(0xFFEA580C),
  Color(0xFF0891B2),
  Color(0xFF65A30D),
  Color(0xFF9333EA),
];

/// Initiales (« Awa Sarr » → « AS ») dans un cercle teinté.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {super.key, this.size = 44});

  final String name;
  final double size;

  static String initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tint =
        _avatarTints[name.trim().toLowerCase().hashCode.abs() %
            _avatarTints.length];
    final dark = context.theme.brightness == Brightness.dark;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: tint.withValues(alpha: dark ? 0.28 : 0.13),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initials(name),
          style: TextStyle(
            color: dark ? Color.lerp(tint, Colors.white, 0.55) : tint,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.36,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

/// Ligne « libellé … valeur » d'un récapitulatif.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final Widget value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Gap.sm),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: context.scheme.onSurfaceVariant),
          const SizedBox(width: Gap.md),
        ],
        Text(
          label,
          style: context.text.bodyMedium?.copyWith(
            color: context.scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: Gap.md),
        // La valeur prend la place restante, alignée à droite
        Expanded(child: Align(alignment: Alignment.centerRight, child: value)),
      ],
    ),
  );
}

/// Contenu centré et limité en largeur (tablette, PWA sur ordinateur).
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = Widths.form,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    // Hauteur de l'enfant : ne s'étire pas dans une barre du bas
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Barre d'action fixée en bas de l'écran, au-dessus du clavier et de la zone système.
/// À placer dans `Scaffold.bottomNavigationBar`.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: ContentWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.page,
                Gap.md,
                Gap.page,
                Gap.md,
              ),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Groupe de champs d'un formulaire, avec titre et icône.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.description,
  });

  final String title;
  final IconData? icon;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Gap.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Gap.xs, bottom: Gap.md),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: context.scheme.primary),
                const SizedBox(width: Gap.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  style: context.text.titleSmall?.copyWith(
                    color: context.scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(
              left: Gap.xs,
              bottom: Gap.md,
              right: Gap.xs,
            ),
            child: Text(description!, style: context.text.bodySmall),
          ),
        ...children,
      ],
    ),
  );
}

/// Espace vertical standard entre deux champs.
const fieldGap = SizedBox(height: Gap.lg);

/// En-tête d'une feuille modale : icône, titre et sous-titre.
class SheetHeader extends StatelessWidget {
  const SheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Gap.xl),
    child: Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: Gap.md)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: Gap.xxs),
                Text(
                  subtitle!,
                  style: context.text.bodyMedium?.copyWith(
                    color: context.scheme.onSurfaceVariant,
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

/// Encadré d'information (conseil, précision) teinté.
class InfoNote extends StatelessWidget {
  const InfoNote(
    this.message, {
    super.key,
    this.icon = Icons.info_outline_rounded,
    this.color,
    this.background,
  });

  final String message;
  final IconData icon;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final c = color ?? scheme.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: background ?? scheme.secondaryContainer,
        borderRadius: Radii.mdAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: c),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Text(
              message,
              style: context.text.bodyMedium?.copyWith(color: c),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau d'erreur en tête de formulaire.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Gap.lg),
    child: Semantics(
      liveRegion: true,
      child: InfoNote(
        message,
        icon: Icons.error_outline_rounded,
        color: context.scheme.onErrorContainer,
        background: context.scheme.errorContainer,
      ),
    ),
  );
}

/// Indicateur de chargement dans un bouton.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 22,
    height: 22,
    child: CircularProgressIndicator(
      strokeWidth: 2.5,
      color: color ?? context.scheme.primary,
    ),
  );
}

/// Bouton d'action rond avec libellé (Appeler, Relancer…).
class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final c = color ?? scheme.primary;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onPressed,
          borderRadius: Radii.mdAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Gap.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: enabled ? 1 : 0.4,
                  child: IconBadge(icon, color: c, size: 52),
                ),
                const SizedBox(height: Gap.sm),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelMedium?.copyWith(
                    color: enabled ? scheme.onSurface : scheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bloc gris animé affiché pendant un chargement.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = Radii.xs,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.45, end: 1.0).animate(_controller),
    child: Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: context.scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    ),
  );
}

/// Squelette d'une liste (avatar, deux lignes, montant).
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Chargement',
    child: Column(
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Gap.page,
              vertical: Gap.md,
            ),
            child: Row(
              children: [
                const Skeleton(width: 44, height: 44, radius: 22),
                const SizedBox(width: Gap.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(width: 120.0 + (i % 3) * 30),
                      const SizedBox(height: Gap.sm),
                      const Skeleton(width: 90, height: 10),
                    ],
                  ),
                ),
                const Skeleton(width: 70),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Petite pastille de texte colorée (« À jour », « 2 en retard »…).
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, required this.color, this.background});

  final String label;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 2),
    decoration: BoxDecoration(
      color: background ?? color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(Radii.pill),
    ),
    child: Text(label, style: context.text.labelSmall?.copyWith(color: color)),
  );
}
