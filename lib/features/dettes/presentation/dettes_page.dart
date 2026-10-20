import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../core/domain/enums.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/paged_list.dart';
import '../../boutiques/presentation/boutique_context.dart';
import '../../boutiques/presentation/boutique_switcher.dart';
import '../domain/dette.dart';
import 'dette_tile.dart';

/// Filtre de la liste : dettes en cours, un statut précis, ou toutes.
enum _Filtre {
  enCours,
  enRetard,
  aAujourdhui,
  enAttente,
  payee,
  annulee,
  toutes,
}

extension on _Filtre {
  String get label => switch (this) {
    _Filtre.enCours => 'En cours',
    _Filtre.enRetard => StatutDette.enRetard.label,
    _Filtre.aAujourdhui => "Aujourd'hui",
    _Filtre.enAttente => StatutDette.enAttente.label,
    _Filtre.payee => 'Payées',
    _Filtre.annulee => 'Annulées',
    _Filtre.toutes => 'Toutes',
  };

  StatutDette? get statut => switch (this) {
    _Filtre.enRetard => StatutDette.enRetard,
    _Filtre.aAujourdhui => StatutDette.aAujourdhui,
    _Filtre.enAttente => StatutDette.enAttente,
    _Filtre.payee => StatutDette.payee,
    _Filtre.annulee => StatutDette.annulee,
    _ => null,
  };
}

_Filtre _filtreFromStatut(String? value) => switch (value) {
  'en_retard' => _Filtre.enRetard,
  'a_aujourdhui' => _Filtre.aAujourdhui,
  'en_attente' => _Filtre.enAttente,
  'payee' => _Filtre.payee,
  'annulee' => _Filtre.annulee,
  _ => _Filtre.enCours,
};

class DettesPage extends ConsumerStatefulWidget {
  const DettesPage({super.key, this.statut});

  /// `?statut=en_retard` (depuis l'accueil)
  final String? statut;

  @override
  ConsumerState<DettesPage> createState() => _DettesPageState();
}

class _DettesPageState extends ConsumerState<DettesPage> {
  late _Filtre _filtre = _filtreFromStatut(widget.statut);

  @override
  void didUpdateWidget(covariant DettesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.statut != oldWidget.statut && widget.statut != null) {
      _filtre = _filtreFromStatut(widget.statut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final boutiqueId = ref.watch(boutiqueFiltreProvider);
    final version = ref.watch(dataVersionProvider);
    final repo = ref.watch(detteRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const BoutiqueSwitcher(titre: 'Dettes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dettes/nouvelle'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle dette'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                Gap.page,
                Gap.xs,
                Gap.page,
                Gap.sm,
              ),
              itemCount: _Filtre.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: Gap.sm),
              itemBuilder: (context, i) {
                final f = _Filtre.values[i];
                final statut = f.statut;
                return ChoiceChip(
                  avatar:
                      statut == null
                          ? null
                          : Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statut.couleur(context.scheme),
                              shape: BoxShape.circle,
                            ),
                          ),
                  label: Text(f.label),
                  selected: _filtre == f,
                  onSelected: (_) => setState(() => _filtre = f),
                );
              },
            ),
          ),
          Expanded(
            child: PagedList<Dette>(
              resetKey: (boutiqueId, _filtre, version),
              fetch:
                  (page) => repo.list(
                    page: page,
                    boutiqueId: boutiqueId,
                    statut: _filtre.statut,
                    ouvertes: _filtre == _Filtre.enCours,
                  ),
              padding: const EdgeInsets.only(bottom: Gap.fab),
              divider: const Divider(indent: 72, endIndent: Gap.page),
              empty: const EmptyState(
                icon: Icons.receipt_long_rounded,
                titre: 'Aucune dette',
                message: 'Aucune dette ne correspond à ce filtre.',
              ),
              itemBuilder: (context, dette) => DetteTile(dette: dette),
            ),
          ),
        ],
      ),
    );
  }
}
