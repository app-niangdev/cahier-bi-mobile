import '../../../core/domain/enums.dart';
import '../../../core/domain/subscription_status.dart';
import '../../../core/utils/format.dart';

class CompteurStatut {
  const CompteurStatut({required this.count, required this.total});

  factory CompteurStatut.fromJson(Object? json) {
    final map = json is Map ? json : const {};
    return CompteurStatut(
      count: toIntOrNull(map['count']) ?? 0,
      total: toDouble(map['total']),
    );
  }

  final int count;
  final double total;
}

/// Dette échue à relancer.
class DetteARelancer {
  const DetteARelancer({
    required this.id,
    required this.reference,
    required this.clientId,
    required this.clientNom,
    required this.montantRestant,
    required this.statut,
    this.clientTelephone,
    this.dateEcheance,
  });

  factory DetteARelancer.fromJson(Map<String, dynamic> json) {
    final client = (json['client'] as Map?) ?? const {};
    return DetteARelancer(
      id: (json['id'] as num).toInt(),
      reference: json['reference'] as String? ?? '',
      clientId: toIntOrNull(client['id']) ?? 0,
      clientNom: client['nom'] as String? ?? '',
      clientTelephone: client['telephone'] as String?,
      montantRestant: toDouble(json['montant_restant']),
      dateEcheance: parseDate(json['date_echeance']),
      statut: StatutDette.fromJson(json['statut']),
    );
  }

  final int id;
  final String reference;
  final int clientId;
  final String clientNom;
  final String? clientTelephone;
  final double montantRestant;
  final DateTime? dateEcheance;
  final StatutDette statut;
}

/// Activité entre deux dates incluses (`GET /manager/dashboard?du=&au=`).
class PeriodeActivite {
  const PeriodeActivite({
    required this.du,
    required this.au,
    required this.encaisse,
    required this.versementsCount,
    required this.dettesCount,
    required this.dettesMontant,
  });

  factory PeriodeActivite.fromJson(Map<String, dynamic> json) =>
      PeriodeActivite(
        du: parseDate(json['du'])!,
        au: parseDate(json['au'])!,
        encaisse: toDouble(json['encaisse']),
        versementsCount: toIntOrNull(json['versements_count']) ?? 0,
        dettesCount: toIntOrNull(json['dettes_count']) ?? 0,
        dettesMontant: toDouble(json['dettes_montant']),
      );

  final DateTime du;
  final DateTime au;

  /// Total encaissé et nombre de versements reçus.
  final double encaisse;
  final int versementsCount;

  /// Dettes notées sur la période (hors annulées).
  final int dettesCount;
  final double dettesMontant;
}

/// `GET /manager/dashboard`
class Dashboard {
  const Dashboard({
    required this.subscription,
    required this.totalARecuperer,
    required this.enAttente,
    required this.aAujourdhui,
    required this.enRetard,
    required this.encaisseAujourdhui,
    required this.encaisseMois,
    required this.clientsCount,
    required this.clientsDebiteursCount,
    required this.aRelancer,
    this.periode,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    final dettes = (json['dettes'] as Map?) ?? const {};
    return Dashboard(
      subscription: SubscriptionStatus.fromJson(
        (json['subscription'] as Map).cast<String, dynamic>(),
      ),
      totalARecuperer: toDouble(json['total_a_recuperer']),
      enAttente: CompteurStatut.fromJson(dettes['en_attente']),
      aAujourdhui: CompteurStatut.fromJson(dettes['a_aujourdhui']),
      enRetard: CompteurStatut.fromJson(dettes['en_retard']),
      encaisseAujourdhui: toDouble(json['encaisse_aujourdhui']),
      encaisseMois: toDouble(json['encaisse_mois']),
      clientsCount: toIntOrNull(json['clients_count']) ?? 0,
      clientsDebiteursCount: toIntOrNull(json['clients_debiteurs_count']) ?? 0,
      aRelancer:
          (json['a_relancer'] as List? ?? const [])
              .map(
                (e) =>
                    DetteARelancer.fromJson((e as Map).cast<String, dynamic>()),
              )
              .toList(),
      periode:
          json['periode'] is Map
              ? PeriodeActivite.fromJson(
                (json['periode'] as Map).cast<String, dynamic>(),
              )
              : null,
    );
  }

  final SubscriptionStatus subscription;
  final double totalARecuperer;
  final CompteurStatut enAttente;
  final CompteurStatut aAujourdhui;
  final CompteurStatut enRetard;
  final double encaisseAujourdhui;
  final double encaisseMois;
  final int clientsCount;
  final int clientsDebiteursCount;
  final List<DetteARelancer> aRelancer;

  /// Présent seulement quand une période est demandée.
  final PeriodeActivite? periode;
}
