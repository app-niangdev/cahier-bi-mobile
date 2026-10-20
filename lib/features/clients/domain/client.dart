import '../../../core/domain/enums.dart';
import '../../../core/utils/format.dart';
import '../../dettes/domain/dette.dart';

/// Client d'une boutique, avec sa situation.
class Client {
  const Client({
    required this.id,
    required this.boutiqueId,
    required this.nom,
    this.telephone,
    this.whatsapp,
    this.adresse,
    this.note,
    this.totalDu = 0,
    this.dettesEnRetard = 0,
    this.dettes = const [],
  });

  factory Client.fromJson(Map<String, dynamic> json) => Client(
    id: (json['id'] as num).toInt(),
    boutiqueId: toIntOrNull(json['boutique_id']) ?? 0,
    nom: json['nom'] as String? ?? '',
    telephone: json['telephone'] as String?,
    whatsapp: json['whatsapp'] as String?,
    adresse: json['adresse'] as String?,
    note: json['note'] as String?,
    totalDu: toDouble(json['total_du']),
    dettesEnRetard: toIntOrNull(json['dettes_en_retard']) ?? 0,
    dettes:
        (json['dettes'] as List? ?? const [])
            .map((e) => Dette.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
  );

  final int id;
  final int boutiqueId;
  final String nom;
  final String? telephone;
  final String? whatsapp;
  final String? adresse;
  final String? note;
  final double totalDu;
  final int dettesEnRetard;

  /// Fiche client seulement (`GET /manager/clients/{id}`).
  final List<Dette> dettes;

  /// Numéro à utiliser pour WhatsApp.
  String? get numeroWhatsapp => whatsapp ?? telephone;
}

class ClientPayload {
  const ClientPayload({
    required this.nom,
    this.telephone,
    this.whatsapp,
    this.adresse,
    this.note,
    this.boutiqueId,
  });

  final String nom;
  final String? telephone;
  final String? whatsapp;
  final String? adresse;
  final String? note;

  /// Création par le propriétaire seulement.
  final int? boutiqueId;

  Map<String, dynamic> toJson() => {
    if (boutiqueId != null) 'boutique_id': boutiqueId,
    'nom': nom.trim(),
    'telephone': _phone(telephone),
    'whatsapp': _phone(whatsapp),
    'adresse': _text(adresse),
    'note': _text(note),
  };

  static String? _phone(String? value) =>
      value == null || value.trim().isEmpty
          ? null
          : nationalNumber(value) ?? value;
  static String? _text(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
}

/// Ligne de l'historique des versements d'un client (un versement peut couvrir plusieurs dettes).
class Versement {
  const Versement({
    required this.versement,
    required this.montant,
    required this.methode,
    required this.repartition,
    this.datePaiement,
    this.reference,
    this.note,
    this.enregistrePar,
  });

  factory Versement.fromJson(Map<String, dynamic> json) => Versement(
    versement: json['versement'] as String,
    montant: toDouble(json['montant']),
    methode: MethodePaiement.fromJson(json['methode']),
    datePaiement: parseDate(json['date_paiement']),
    reference: json['reference'] as String?,
    note: json['note'] as String?,
    enregistrePar: json['enregistre_par'] as String?,
    repartition:
        (json['repartition'] as List? ?? const [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .map(
              (e) => (
                reference: e['reference'] as String? ?? '',
                montant: toDouble(e['montant']),
              ),
            )
            .toList(),
  );

  final String versement;
  final double montant;
  final MethodePaiement methode;
  final DateTime? datePaiement;
  final String? reference;
  final String? note;
  final String? enregistrePar;
  final List<({String reference, double montant})> repartition;
}
