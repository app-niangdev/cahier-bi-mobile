import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/boutique.dart';

/// Boutiques de l'utilisateur connecté.
final boutiquesProvider = FutureProvider<List<Boutique>>((ref) async {
  final userId = ref.watch(profilProvider.select((p) => p?.id));
  if (userId == null) return const [];
  ref.watch(dataVersionProvider);
  return ref.read(boutiqueRepositoryProvider).list();
});

const _prefKey = 'boutique_selectionnee';

/// Boutique choisie par le propriétaire (null = toutes), mémorisée sur l'appareil.
final boutiqueSelectionProvider = NotifierProvider<BoutiqueSelection, int?>(
  BoutiqueSelection.new,
);

class BoutiqueSelection extends Notifier<int?> {
  @override
  int? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_prefKey);
      if (saved != null && ref.mounted) state = saved;
    } catch (_) {
      // Préférences indisponibles : « Toutes »
    }
  }

  Future<void> select(int? boutiqueId) async {
    state = boutiqueId;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (boutiqueId == null) {
        await prefs.remove(_prefKey);
      } else {
        await prefs.setInt(_prefKey, boutiqueId);
      }
    } catch (_) {
      // Choix gardé pour cette session seulement
    }
  }
}

/// Boutique de travail : celle du gérant ; pour le propriétaire, celle qu'il a choisie,
/// ou sa seule boutique. null = toutes les boutiques du propriétaire.
final boutiqueCouranteProvider = Provider<Boutique?>((ref) {
  final profil = ref.watch(profilProvider);
  final boutiques = ref.watch(boutiquesProvider).value ?? const <Boutique>[];
  if (profil == null || boutiques.isEmpty) return null;
  if (boutiques.length == 1) return boutiques.first;
  if (profil.isGerant) {
    return boutiques.where((b) => b.id == profil.boutique?.id).firstOrNull ??
        boutiques.first;
  }
  final selection = ref.watch(boutiqueSelectionProvider);
  return boutiques.where((b) => b.id == selection).firstOrNull;
});

/// Filtre `boutique_id` des écrans (null = toutes).
final boutiqueFiltreProvider = Provider<int?>(
  (ref) => ref.watch(boutiqueCouranteProvider)?.id,
);
