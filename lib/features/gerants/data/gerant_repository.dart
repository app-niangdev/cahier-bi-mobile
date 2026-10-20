import 'dart:math';

import '../../../core/api/api_client.dart';
import '../domain/gerant.dart';

/// `/api/manager/gerants` (propriétaire seulement).
class GerantRepository {
  GerantRepository(this._api);
  final ApiClient _api;

  Future<List<Gerant>> list({int? boutiqueId}) async =>
      (await _api.get('/manager/gerants', query: {'boutique_id': boutiqueId})
              as List)
          .map((e) => Gerant.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

  /// Renvoie le gérant et le mot de passe provisoire à lui communiquer.
  Future<(Gerant, String)> create(int boutiqueId, GerantPayload payload) async {
    final password = motDePasseProvisoire();
    final json = await _api.post('/manager/gerants', {
      ...payload.toJson(),
      'boutique_id': boutiqueId,
      'password': password,
    });
    return (Gerant.fromJson((json as Map).cast<String, dynamic>()), password);
  }

  Future<Gerant> update(int id, GerantPayload payload) async => Gerant.fromJson(
    (await _api.put('/manager/gerants/$id', payload.toJson()) as Map)
        .cast<String, dynamic>(),
  );

  Future<Gerant> transfer(int id, int boutiqueId) async => Gerant.fromJson(
    (await _api.put('/manager/gerants/$id/transfer', {
              'boutique_id': boutiqueId,
            })
            as Map)
        .cast<String, dynamic>(),
  );

  Future<Gerant> toggleStatus(int id) async => Gerant.fromJson(
    (await _api.put('/manager/gerants/$id/toggle-status') as Map)
        .cast<String, dynamic>(),
  );

  /// Nouveau mot de passe provisoire : le gérant refait le parcours de première connexion.
  Future<String> resetAccess(int id) async {
    final password = motDePasseProvisoire();
    await _api.post('/manager/gerants/$id/reset-access', {
      'password': password,
    });
    return password;
  }

  Future<void> delete(int id) => _api.delete('/manager/gerants/$id');
}

/// 8 caractères minimum côté Laravel : « CB-482913 ».
String motDePasseProvisoire([Random? random]) {
  final r = random ?? Random.secure();
  return 'CB-${(100000 + r.nextInt(900000))}';
}
