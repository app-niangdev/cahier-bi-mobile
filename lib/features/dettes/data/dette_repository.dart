import '../../../core/api/api_client.dart';
import '../../../core/domain/enums.dart';
import '../../../core/utils/format.dart';
import '../domain/dette.dart';

/// `/api/manager/dettes`, versements et annulations.
class DetteRepository {
  DetteRepository(this._api);
  final ApiClient _api;

  Future<Paged<Dette>> list({
    int page = 1,
    int? boutiqueId,
    int? clientId,
    StatutDette? statut,
    bool ouvertes = false,
  }) => _api.page(
    '/manager/dettes',
    Dette.fromJson,
    query: {
      'page': page,
      'per_page': 20,
      'boutique_id': boutiqueId,
      'client_id': clientId,
      'statut': statut?.value,
      'ouvertes': ouvertes ? true : null,
    },
  );

  Future<Dette> get(int id) async => Dette.fromJson(
    (await _api.get('/manager/dettes/$id') as Map).cast<String, dynamic>(),
  );

  Future<Dette> create({
    required int clientId,
    required double montant,
    DateTime? dateCreation,
    DateTime? dateEcheance,
    String? note,
  }) async => Dette.fromJson(
    (await _api.post('/manager/dettes', {
              'client_id': clientId,
              'montant': montant,
              if (dateCreation != null) 'date_creation': isoDate(dateCreation),
              'date_echeance':
                  dateEcheance == null ? null : isoDate(dateEcheance),
              'note': note == null || note.trim().isEmpty ? null : note.trim(),
            })
            as Map)
        .cast<String, dynamic>(),
  );

  /// Le montant n'est modifiable que par le propriétaire (`montant` null : inchangé).
  Future<Dette> update(
    int id, {
    double? montant,
    DateTime? dateEcheance,
    String? note,
  }) async => Dette.fromJson(
    (await _api.put('/manager/dettes/$id', {
              if (montant != null) 'montant': montant,
              'date_echeance':
                  dateEcheance == null ? null : isoDate(dateEcheance),
              'note': note == null || note.trim().isEmpty ? null : note.trim(),
            })
            as Map)
        .cast<String, dynamic>(),
  );

  /// Versement imputé sur cette dette seulement.
  Future<void> payer(int id, PaiementPayload paiement) =>
      _api.post('/manager/dettes/$id/paiements', paiement.toJson());

  /// Propriétaire seulement.
  Future<void> annuler(int id) => _api.post('/manager/dettes/$id/annuler');

  /// Annule un versement entier (toutes ses lignes). Propriétaire seulement.
  Future<void> annulerVersement(String versement) =>
      _api.delete('/manager/versements/$versement');
}
