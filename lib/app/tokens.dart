import 'package:flutter/material.dart';

/// Système de design de Cahier Bi : espacements, rayons, durées et couleurs sémantiques.
/// Toute valeur visuelle des écrans vient d'ici ou du thème (`theme.dart`).

/// Espacements (grille de 4 px).
abstract final class Gap {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Marge latérale des écrans.
  static const double page = 16;

  /// Espace laissé sous les listes pour ne pas être masqué par le bouton flottant.
  static const double fab = 104;
}

/// Rayons de bordure.
abstract final class Radii {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}

/// Durées d'animation.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 600);
  static const Curve curve = Curves.easeOutCubic;
}

/// Largeurs maximales du contenu (grand écran, PWA).
abstract final class Widths {
  static const double form = 640;
  static const double auth = 440;
  static const double content = 960;
}

/// Couleurs de la marque.
abstract final class Brand {
  /// Vert sarcelle de Cahier Bi (couleur du manifeste PWA).
  static const Color teal = Color(0xFF0F766E);
  static const Color tealDeep = Color(0xFF0B4F4A);
  static const Color tealLight = Color(0xFF5EC4B6);

  /// Accent safran, utilisé avec parcimonie (offres, échéance du jour).
  static const Color saffron = Color(0xFFF59E0B);
}

/// Couleurs sémantiques (succès, alerte, danger, neutre), adaptées au mode clair ou sombre.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.neutral,
    required this.neutralContainer,
    required this.accent,
    required this.accentContainer,
    required this.hero,
    required this.onHero,
  });

  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color danger;
  final Color dangerContainer;
  final Color neutral;
  final Color neutralContainer;
  final Color accent;
  final Color accentContainer;

  /// Fond de la carte principale (total à récupérer).
  final Color hero;
  final Color onHero;

  static const light = AppColors(
    success: Color(0xFF15803D),
    successContainer: Color(0xFFDCF5E4),
    warning: Color(0xFFC2410C),
    warningContainer: Color(0xFFFFEDD5),
    danger: Color(0xFFDC2626),
    dangerContainer: Color(0xFFFEE4E2),
    neutral: Color(0xFF475569),
    neutralContainer: Color(0xFFE9EEF2),
    accent: Color(0xFFB45309),
    accentContainer: Color(0xFFFEF3C7),
    hero: Brand.tealDeep,
    onHero: Colors.white,
  );

  static const dark = AppColors(
    success: Color(0xFF4ADE80),
    successContainer: Color(0xFF12321F),
    warning: Color(0xFFFB923C),
    warningContainer: Color(0xFF3A2312),
    danger: Color(0xFFF87171),
    dangerContainer: Color(0xFF3B1818),
    neutral: Color(0xFFA5B4C3),
    neutralContainer: Color(0xFF1F2A33),
    accent: Color(0xFFFBBF24),
    accentContainer: Color(0xFF3A2D10),
    hero: Color(0xFF134E48),
    onHero: Colors.white,
  );

  static AppColors of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  @override
  AppColors copyWith({
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? danger,
    Color? dangerContainer,
    Color? neutral,
    Color? neutralContainer,
    Color? accent,
    Color? accentContainer,
    Color? hero,
    Color? onHero,
  }) => AppColors(
    success: success ?? this.success,
    successContainer: successContainer ?? this.successContainer,
    warning: warning ?? this.warning,
    warningContainer: warningContainer ?? this.warningContainer,
    danger: danger ?? this.danger,
    dangerContainer: dangerContainer ?? this.dangerContainer,
    neutral: neutral ?? this.neutral,
    neutralContainer: neutralContainer ?? this.neutralContainer,
    accent: accent ?? this.accent,
    accentContainer: accentContainer ?? this.accentContainer,
    hero: hero ?? this.hero,
    onHero: onHero ?? this.onHero,
  );

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      success: l(success, other.success),
      successContainer: l(successContainer, other.successContainer),
      warning: l(warning, other.warning),
      warningContainer: l(warningContainer, other.warningContainer),
      danger: l(danger, other.danger),
      dangerContainer: l(dangerContainer, other.dangerContainer),
      neutral: l(neutral, other.neutral),
      neutralContainer: l(neutralContainer, other.neutralContainer),
      accent: l(accent, other.accent),
      accentContainer: l(accentContainer, other.accentContainer),
      hero: l(hero, other.hero),
      onHero: l(onHero, other.onHero),
    );
  }
}

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ??
      AppColors.of(Theme.of(this).brightness);
}
