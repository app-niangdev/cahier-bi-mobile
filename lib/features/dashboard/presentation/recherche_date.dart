import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/utils/format.dart';
import '../../../shared/widgets/montant.dart';
import '../../../shared/widgets/ui.dart';
import '../../boutiques/presentation/boutique_context.dart';
import '../domain/dashboard.dart';

/// Raccourcis de la recherche par date.
enum Raccourci {
  aujourdhui("Aujourd'hui"),
  hier('Hier'),
  septJours('7 derniers jours'),
  ceMois('Ce mois'),
  jour('Jour choisi'),
  personnalise('Période choisie');

  const Raccourci(this.label);
  final String label;

  DateTimeRange get periode {
    final today = DateUtils.dateOnly(DateTime.now());
    return switch (this) {
      Raccourci.aujourdhui => DateTimeRange(start: today, end: today),
      Raccourci.hier => DateTimeRange(
        start: today.subtract(const Duration(days: 1)),
        end: today.subtract(const Duration(days: 1)),
      ),
      Raccourci.septJours => DateTimeRange(
        start: today.subtract(const Duration(days: 6)),
        end: today,
      ),
      Raccourci.ceMois => DateTimeRange(
        start: DateTime(today.year, today.month),
        end: today,
      ),
      Raccourci.jour ||
      Raccourci.personnalise => DateTimeRange(start: today, end: today),
    };
  }
}

/// Période recherchée sur l'accueil (null : aucune recherche).
typedef PeriodeChoisie = ({Raccourci raccourci, DateTimeRange periode});

final periodeAccueilProvider =
    NotifierProvider<PeriodeAccueil, PeriodeChoisie?>(PeriodeAccueil.new);

class PeriodeAccueil extends Notifier<PeriodeChoisie?> {
  @override
  PeriodeChoisie? build() => null;

  void choisir(Raccourci raccourci, [DateTimeRange? periode]) =>
      state = (raccourci: raccourci, periode: periode ?? raccourci.periode);

  void effacer() => state = null;
}

/// Activité de la période choisie, pour la boutique affichée.
final activiteProvider = FutureProvider.autoDispose<PeriodeActivite?>((
  ref,
) async {
  final choix = ref.watch(periodeAccueilProvider);
  if (choix == null) return null;
  ref.watch(dataVersionProvider);
  final dashboard = await ref
      .read(dashboardRepositoryProvider)
      .load(
        boutiqueId: ref.watch(boutiqueFiltreProvider),
        du: choix.periode.start,
        au: choix.periode.end,
      );
  return dashboard.periode;
});

/// « 15 octobre 2026 » ou « Du 1 oct. 2026 au 15 oct. 2026 ».
String libellePeriode(DateTimeRange p) =>
    DateUtils.isSameDay(p.start, p.end)
        ? dateLongue(p.start)
        : 'Du ${dateCourte(p.start)} au ${dateCourte(p.end)}';

/// Section de l'accueil : choisir un jour ou une période et voir les encaissements
/// et les dettes notées sur cette période.
class RechercheParDate extends ConsumerWidget {
  const RechercheParDate({super.key});

  Future<void> _choisirJour(
    BuildContext context,
    WidgetRef ref,
    PeriodeChoisie? choix,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final jour = await showDatePicker(
      context: context,
      firstDate: DateTime(today.year - 5),
      lastDate: today,
      initialDate: choix?.periode.start ?? today,
      helpText: 'Choisir un jour',
      confirmText: 'Valider',
    );
    if (jour != null) {
      ref
          .read(periodeAccueilProvider.notifier)
          .choisir(Raccourci.jour, DateTimeRange(start: jour, end: jour));
    }
  }

  Future<void> _choisirDates(
    BuildContext context,
    WidgetRef ref,
    PeriodeChoisie? choix,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final periode = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 5),
      lastDate: today,
      initialDateRange: choix?.periode,
      helpText: 'Choisir une date ou une période',
      saveText: 'Valider',
      fieldStartLabelText: 'Du',
      fieldEndLabelText: 'Au',
    );
    if (periode != null) {
      ref
          .read(periodeAccueilProvider.notifier)
          .choisir(Raccourci.personnalise, periode);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choix = ref.watch(periodeAccueilProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Recherche par date',
          subtitle: 'Encaissements et dettes notées sur une période',
          action:
              choix == null
                  ? null
                  : IconButton(
                    tooltip: 'Effacer la recherche',
                    icon: const Icon(Icons.close_rounded),
                    onPressed:
                        () =>
                            ref.read(periodeAccueilProvider.notifier).effacer(),
                  ),
          padding: const EdgeInsets.only(top: Gap.xxl, bottom: Gap.md),
        ),
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            for (final r in [
              Raccourci.aujourdhui,
              Raccourci.hier,
              Raccourci.septJours,
              Raccourci.ceMois,
            ])
              ChoiceChip(
                label: Text(r.label),
                selected: choix?.raccourci == r,
                onSelected:
                    (_) => ref.read(periodeAccueilProvider.notifier).choisir(r),
              ),
            _ChoixCalendrier(
              icon: Icons.today_rounded,
              label: 'Un jour…',
              selected: choix?.raccourci == Raccourci.jour,
              onSelected: () => _choisirJour(context, ref, choix),
            ),
            _ChoixCalendrier(
              icon: Icons.date_range_rounded,
              label: 'Une période…',
              selected: choix?.raccourci == Raccourci.personnalise,
              onSelected: () => _choisirDates(context, ref, choix),
            ),
          ],
        ),
        AnimatedSize(
          duration: Motion.medium,
          curve: Motion.curve,
          alignment: Alignment.topCenter,
          child:
              choix == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                    padding: const EdgeInsets.only(top: Gap.md),
                    child: _Resultat(
                      choix: choix,
                      onModifier:
                          () =>
                              choix.raccourci == Raccourci.jour
                                  ? _choisirJour(context, ref, choix)
                                  : _choisirDates(context, ref, choix),
                    ),
                  ),
        ),
      ],
    );
  }
}

/// Puce qui ouvre un calendrier.
class _ChoixCalendrier extends StatelessWidget {
  const _ChoixCalendrier({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    avatar: Icon(
      icon,
      size: 18,
      color:
          selected ? context.scheme.onPrimaryContainer : context.scheme.primary,
    ),
    label: Text(label),
    selected: selected,
    onSelected: (_) => onSelected(),
  );
}

class _Resultat extends ConsumerWidget {
  const _Resultat({required this.choix, required this.onModifier});

  final PeriodeChoisie choix;
  final VoidCallback onModifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activite = ref.watch(activiteProvider);
    final colors = context.colors;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Période recherchée : toucher pour la modifier
          InkWell(
            onTap: onModifier,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.lg,
                Gap.md,
                Gap.md,
                Gap.md,
              ),
              child: Row(
                children: [
                  const IconBadge(Icons.event_note_rounded, size: 36),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          choix.raccourci.label,
                          style: context.text.bodySmall,
                        ),
                        Text(
                          libellePeriode(choix.periode),
                          style: context.text.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.edit_calendar_rounded,
                    size: 20,
                    color: context.scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: switch (activite) {
              AsyncError(:final error) => Row(
                children: [
                  Icon(Icons.cloud_off_rounded, color: context.scheme.error),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Text(
                      errorMessage(error),
                      style: context.text.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(activiteProvider),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
              AsyncData(:final value?) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Chiffre(
                      icon: Icons.south_west_rounded,
                      color: colors.success,
                      label: 'Encaissé',
                      montant: value.encaisse,
                      detail: '${value.versementsCount} versement(s)',
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: _Chiffre(
                      icon: Icons.receipt_long_rounded,
                      color: colors.warning,
                      label: 'Dettes notées',
                      montant: value.dettesMontant,
                      detail: '${value.dettesCount} dette(s)',
                    ),
                  ),
                ],
              ),
              AsyncData() => Text(
                'Aucune donnée pour cette période.',
                style: context.text.bodyMedium,
              ),
              _ => const Row(
                children: [
                  Expanded(child: _ChiffreSkeleton()),
                  SizedBox(width: Gap.md),
                  Expanded(child: _ChiffreSkeleton()),
                ],
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _Chiffre extends StatelessWidget {
  const _Chiffre({
    required this.icon,
    required this.color,
    required this.label,
    required this.montant,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String label;
  final double montant;
  final String detail;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: Gap.xs),
          Text(label, style: context.text.bodySmall),
        ],
      ),
      const SizedBox(height: Gap.xs),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: MontantText(montant, style: context.text.titleMedium),
      ),
      Text(detail, style: context.text.labelSmall?.copyWith(color: color)),
    ],
  );
}

class _ChiffreSkeleton extends StatelessWidget {
  const _ChiffreSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Skeleton(width: 70, height: 10),
      SizedBox(height: Gap.sm),
      Skeleton(width: 110, height: 18),
      SizedBox(height: Gap.sm),
      Skeleton(width: 60, height: 10),
    ],
  );
}
