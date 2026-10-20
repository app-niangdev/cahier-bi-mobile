import 'package:flutter/material.dart';

import '../core/domain/enums.dart';
import 'tokens.dart';

export 'tokens.dart';

/// Thème Material 3 de Cahier Bi : surfaces douces, contrastes nets, grandes cibles tactiles.
ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors = AppColors.of(brightness);

  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.teal,
    brightness: brightness,
  ).copyWith(
    primary: dark ? Brand.tealLight : Brand.teal,
    onPrimary: dark ? const Color(0xFF00201D) : Colors.white,
    primaryContainer: dark ? const Color(0xFF0F3B37) : const Color(0xFFD5F0EB),
    onPrimaryContainer: dark ? const Color(0xFFB4ECE3) : Brand.tealDeep,
    secondaryContainer:
        dark ? const Color(0xFF1C2B29) : const Color(0xFFE3EEEB),
    onSecondaryContainer:
        dark ? const Color(0xFFCFE3DF) : const Color(0xFF17332F),
    tertiary: colors.accent,
    tertiaryContainer: colors.accentContainer,
    error: colors.danger,
    errorContainer: colors.dangerContainer,
    onErrorContainer: dark ? const Color(0xFFFFDAD6) : const Color(0xFF7A1212),
    // Fond légèrement teinté, cartes blanches : la hiérarchie vient des surfaces
    surface: dark ? const Color(0xFF0C1413) : const Color(0xFFF4F7F6),
    onSurface: dark ? const Color(0xFFE4ECEA) : const Color(0xFF0F1E1C),
    onSurfaceVariant: dark ? const Color(0xFF9DAEAA) : const Color(0xFF586A66),
    surfaceContainerLowest: dark ? const Color(0xFF111B1A) : Colors.white,
    surfaceContainerLow:
        dark ? const Color(0xFF142120) : const Color(0xFFFAFCFB),
    surfaceContainer: dark ? const Color(0xFF182625) : const Color(0xFFEEF3F1),
    surfaceContainerHigh:
        dark ? const Color(0xFF1D2D2B) : const Color(0xFFE8EEEC),
    surfaceContainerHighest:
        dark ? const Color(0xFF233432) : const Color(0xFFE1E9E7),
    outline: dark ? const Color(0xFF5F716D) : const Color(0xFF8A9B97),
    outlineVariant: dark ? const Color(0xFF263835) : const Color(0xFFDDE5E3),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
  );
  // Tailles explicites : les styles servent aussi aux thèmes de composants,
  // qui ne reçoivent pas la géométrie ajoutée par Theme.of
  final t = Typography.englishLike2021.merge(base.textTheme);
  final textTheme = t.copyWith(
    displaySmall: t.displaySmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -1,
    ),
    headlineLarge: t.headlineLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
    ),
    headlineMedium: t.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
    ),
    headlineSmall: t.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    ),
    titleLarge: t.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    bodyLarge: t.bodyLarge?.copyWith(height: 1.45),
    bodyMedium: t.bodyMedium?.copyWith(height: 1.45),
    bodySmall: t.bodySmall?.copyWith(
      height: 1.4,
      color: scheme.onSurfaceVariant,
    ),
    labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    labelMedium: t.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    labelSmall: t.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    ),
  );

  final inputBorder = OutlineInputBorder(
    borderRadius: Radii.mdAll,
    borderSide: BorderSide(color: scheme.outlineVariant),
  );
  const buttonShape = RoundedRectangleBorder(borderRadius: Radii.mdAll);

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    visualDensity: VisualDensity.standard,
    splashFactory: InkSparkle.splashFactory,
    extensions: [colors],
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      titleSpacing: Gap.page,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.lgAll,
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: scheme.primary, width: 1.8),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: scheme.error, width: 1.8),
      ),
      prefixIconColor: scheme.onSurfaceVariant,
      suffixIconColor: scheme.onSurfaceVariant,
      hintStyle: TextStyle(color: scheme.outline),
      helperMaxLines: 3,
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 54),
        shape: buttonShape,
        textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 50),
        shape: buttonShape,
        side: BorderSide(color: scheme.outlineVariant),
        textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        padding: const EdgeInsets.symmetric(horizontal: 18),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 44),
        shape: buttonShape,
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      focusElevation: 3,
      hoverElevation: 3,
      highlightElevation: 4,
      shape: const RoundedRectangleBorder(borderRadius: Radii.lgAll),
      extendedTextStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: scheme.outlineVariant),
      backgroundColor: scheme.surfaceContainerLowest,
      selectedColor: scheme.primaryContainer,
      labelStyle: textTheme.labelLarge?.copyWith(color: scheme.onSurface),
      secondaryLabelStyle: textTheme.labelLarge?.copyWith(
        color: scheme.onPrimaryContainer,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      showCheckmark: false,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        minimumSize: const Size(0, 46),
        selectedBackgroundColor: scheme.primaryContainer,
        selectedForegroundColor: scheme.onPrimaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        textStyle: textTheme.labelLarge,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      elevation: 0,
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: const StadiumBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color:
              states.contains(WidgetState.selected)
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => textTheme.labelMedium?.copyWith(
          color:
              states.contains(WidgetState.selected)
                  ? scheme.onSurface
                  : scheme.onSurfaceVariant,
          fontWeight:
              states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: const StadiumBorder(),
      selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
      unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: scheme.onSurface,
      unselectedLabelColor: scheme.onSurfaceVariant,
      labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: textTheme.titleSmall,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      indicator: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: Radii.smAll,
        border: Border.all(color: scheme.outlineVariant),
      ),
      splashBorderRadius: Radii.smAll,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    ),
    listTileTheme: ListTileThemeData(
      minVerticalPadding: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: Gap.lg),
      iconColor: scheme.onSurfaceVariant,
      titleTextStyle: textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      subtitleTextStyle: textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: scheme.outlineVariant,
      dragHandleSize: const Size(40, 4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
      constraints: const BoxConstraints(maxWidth: Widths.form),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: Radii.xlAll),
      titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.mdAll,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      textStyle: textTheme.bodyLarge,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 2,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: scheme.onInverseSurface,
      ),
      shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
      circularTrackColor: Colors.transparent,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: Radii.xlAll),
    ),
  );
}

/// Couleurs dédiées aux statuts de dette.
extension StatutDetteCouleur on StatutDette {
  Color couleur(ColorScheme scheme) {
    final c = AppColors.of(scheme.brightness);
    return switch (this) {
      StatutDette.enRetard => c.danger,
      StatutDette.aAujourdhui => c.warning,
      StatutDette.enAttente => c.neutral,
      StatutDette.payee => c.success,
      StatutDette.annulee => scheme.outline,
    };
  }

  Color fond(ColorScheme scheme) {
    final c = AppColors.of(scheme.brightness);
    return switch (this) {
      StatutDette.enRetard => c.dangerContainer,
      StatutDette.aAujourdhui => c.warningContainer,
      StatutDette.enAttente => c.neutralContainer,
      StatutDette.payee => c.successContainer,
      StatutDette.annulee => scheme.surfaceContainerHigh,
    };
  }

  /// Libellé court pour les pastilles.
  String get labelCourt =>
      this == StatutDette.aAujourdhui ? "Aujourd'hui" : label;

  IconData get icone => switch (this) {
    StatutDette.enRetard => Icons.error_outline_rounded,
    StatutDette.aAujourdhui => Icons.today_rounded,
    StatutDette.enAttente => Icons.schedule_rounded,
    StatutDette.payee => Icons.check_circle_outline_rounded,
    StatutDette.annulee => Icons.block_rounded,
  };
}

/// Icône de chaque moyen de paiement.
extension MethodePaiementIcone on MethodePaiement {
  IconData get icone => switch (this) {
    MethodePaiement.especes => Icons.payments_outlined,
    MethodePaiement.wave ||
    MethodePaiement.orangeMoney ||
    MethodePaiement.freeMoney => Icons.phone_android_rounded,
    MethodePaiement.autre => Icons.more_horiz_rounded,
  };
}
