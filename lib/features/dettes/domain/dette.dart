import '../../../core/domain/enums.dart';
import '../../../core/utils/format.dart';

/// Client résumé (dans une dette).
class ClientRef {
  const ClientRef({required this.id, required this.nom, this.telephone});

  factory ClientRef.fromJson(Map<String, dynamic> json) => ClientRef(
    id: (json['id'] as num).toInt(),
    nom: json['nom'] as String? ?? '',
    telephone: json['telephone'] as String?,
  );

  final int id;
  final String nom;
  final String? telephone;
}

/// Paiement imputé sur une dette (détail d'une dette).
class PaiementLigne {
  const PaiementLigne({
    required this.id,
    required this.versement,
    required this.montant,
    required this.methode,
    this.datePaiement,
    this.reference,
    this.enregistrePar,
  });

  factory PaiementLigne.fromJson(Map<String, dynamic> json) => PaiementLigne(
    id: (json['id'] as num).toInt(),
    versement: json['versement'] as String? ?? '',
    montant: toDouble(json['montant']),
    methode: MethodePaiement.fromJson(json['methode']),
    datePaiement: parseDate(json['date_paiement']),
    reference: json['reference'] as String?,
    enregistrePar: json['enregistre_par'] as String?,
  );

  final int id;

  /// Identifiant (uuid) du versement : un versement global a plusieurs lignes.
  final String versement;
  final double montant;
  final MethodePaiement methode;
  final DateTime? datePaiement;
  final String? reference;
  final String? enregistrePar;
}

/// Achat à crédit d'un client (ScopesBoutiques::presentDette).
class Dette {
  const Dette({
    required this.id,
    required this.reference,
    required this.clientId,
    required this.boutiqueId,
    required this.montant,
    required this.montantPaye,
    required this.montantRestant,
    required this.statut,
    this.dateCreation,
    this.dateEcheance,
    this.note,
    this.client,
    this.paiements = const [],
  });

  factory Dette.fromJson(Map<String, dynamic> json) {
    final client = json['client'];
    return Dette(
      id: (json['id'] as num).toInt(),
      reference: json['reference'] as String? ?? '',
      clientId: toIntOrNull(json['client_id']) ?? 0,
      boutiqueId: toIntOrNull(json['boutique_id']) ?? 0,
      montant: toDouble(json['montant']),
      montantPaye: toDouble(json['montant_paye']),
      montantRestant: toDouble(json['montant_restant']),
      statut: StatutDette.fromJson(json['statut']),
      dateCreation: parseDate(json['date_creation']),
      dateEcheance: parseDate(json['date_echeance']),
      note: json['note'] as String?,
      client:
          client is Map
              ? ClientRef.fromJson(client.cast<String, dynamic>())
              : null,
      paiements:
          (json['paiements'] as List? ?? const [])
              .map(
                (e) =>
                    PaiementLigne.fromJson((e as Map).cast<String, dynamic>()),
              )
              .toList(),
    );
  }

  final int id;
  final String reference;
  final int clientId;
  final int boutiqueId;
  final double montant;
  final double montantPaye;
  final double montantRestant;
  final StatutDette statut;
  final DateTime? dateCreation;
  final DateTime? dateEcheance;
  final String? note;
  final ClientRef? client;
  final List<PaiementLigne> paiements;
}

/// Saisie d'un versement (sur une dette ou global).
class PaiementPayload {
  const PaiementPayload({
    required this.montant,
    required this.methode,
    this.datePaiement,
    this.reference,
    this.note,
  });

  final double montant;
  final MethodePaiement methode;
  final DateTime? datePaiement;
  final String? reference;
  final String? note;

  Map<String, dynamic> toJson() => {
    'montant': montant,
    'methode': methode.value,
    if (datePaiement != null) 'date_paiement': isoDate(datePaiement!),
    if (reference != null && reference!.isNotEmpty) 'reference': reference,
    if (note != null && note!.isNotEmpty) 'note': note,
  };
}
