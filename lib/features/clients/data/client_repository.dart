import '../../../core/api/api_client.dart';
import '../../../core/utils/format.dart';
import '../../dettes/domain/dette.dart';
import '../domain/client.dart';

/// `/api/manager/clients`
class ClientRepository {
  ClientRepository(this._api);
  final ApiClient _api;

  Future<Paged<Client>> list({
    int page = 1,
    int? boutiqueId,
    String? search,
    bool debiteurs = false,
  }) => _api.page(
    '/manager/clients',
    Client.fromJson,
    query: {
      'page': page,
      'per_page': 20,
      'boutique_id': boutiqueId,
      'search': search?.trim(),
      'debiteurs': debiteurs ? true : null,
    },
  );

  /// Fiche : le client et ses dettes (non soldées d'abord).
  Future<Client> get(int id) async => Client.fromJson(
    (await _api.get('/manager/clients/$id') as Map).cast<String, dynamic>(),
  );

  Future<Client> create(ClientPayload payload) async => Client.fromJson(
    (await _api.post('/manager/clients', payload.toJson()) as Map)
        .cast<String, dynamic>(),
  );

  Future<Client> update(int id, ClientPayload payload) async {
    final body = payload.toJson()..remove('boutique_id');
    return Client.fromJson(
      (await _api.put('/manager/clients/$id', body) as Map)
          .cast<String, dynamic>(),
    );
  }

  Future<void> delete(int id) => _api.delete('/manager/clients/$id');

  /// Versement global, réparti de la dette la plus ancienne à la plus récente.
  Future<void> payer(int id, PaiementPayload paiement) =>
      _api.post('/manager/clients/$id/paiements', paiement.toJson());

  Future<List<Versement>> versements(int id) async =>
      (await _api.get('/manager/clients/$id/versements') as List)
          .map((e) => Versement.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

  /// Message poli qui sera envoyé sur WhatsApp et numéro joint.
  Future<({String message, String telephone, double totalDu})> apercuRappel(
    int id,
  ) async {
    final json =
        (await _api.get('/manager/clients/$id/rappel') as Map)
            .cast<String, dynamic>();
    return (
      message: json['message'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
      totalDu: toDouble(json['total_du']),
    );
  }

  /// Envoie le rappel sur WhatsApp (WAHA, côté serveur).
  Future<void> envoyerRappel(int id) =>
      _api.post('/manager/clients/$id/rappel');
}
