import '../../../core/domain/enums.dart';
import '../../../core/utils/format.dart';

/// Places de gérants d'une boutique selon l'abonnement (GerantService::places). max null = illimité.
class GerantsPlaces {
  const GerantsPlaces({required this.max, required this.utilises});

  factory GerantsPlaces.fromJson(Map<String, dynamic> json) => GerantsPlaces(
    max: toIntOrNull(json['max']),
    utilises: toIntOrNull(json['utilises']) ?? 0,
  );

  final int? max;
  final int utilises;

  bool get illimite => max == null;
  bool get complet => max != null && utilises >= max!;
  String get libelle => illimite ? '$utilises / illimité' : '$utilises / $max';
}

/// Boutique visible dans l'application (`GET /manager/boutiques`).
class Boutique {
  const Boutique({
    required this.id,
    required this.nom,
    required this.statut,
    this.telephone,
    this.whatsapp,
    this.adresse,
    this.quartier,
    this.ville,
    this.logoUrl,
    this.totalARecuperer = 0,
    this.gerantsPlaces,
  });

  factory Boutique.fromJson(Map<String, dynamic> json) {
    final places = json['gerants_places'];
    return Boutique(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String? ?? '',
      statut: StatutBoutique.fromJson(json['statut']),
      telephone: json['telephone'] as String?,
      whatsapp: json['whatsapp'] as String?,
      adresse: json['adresse'] as String?,
      quartier: json['quartier'] as String?,
      ville: json['ville'] as String?,
      logoUrl: json['logo_url'] as String?,
      totalARecuperer: toDouble(json['total_a_recuperer']),
      gerantsPlaces:
          places is Map
              ? GerantsPlaces.fromJson(places.cast<String, dynamic>())
              : null,
    );
  }

  final int id;
  final String nom;
  final StatutBoutique statut;
  final String? telephone;
  final String? whatsapp;
  final String? adresse;
  final String? quartier;
  final String? ville;
  final String? logoUrl;
  final double totalARecuperer;

  /// Propriétaire seulement.
  final GerantsPlaces? gerantsPlaces;

  String get lieu => [
    quartier,
    ville,
  ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
}
