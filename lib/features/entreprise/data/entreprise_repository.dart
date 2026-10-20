import '../../../core/api/api_client.dart';
import '../domain/entreprise.dart';

/// `/api/manager/company`, `/api/manager/subscription` et routes publiques.
class EntrepriseRepository {
  EntrepriseRepository(this._api);
  final ApiClient _api;

  Future<Entreprise> get() async => Entreprise.fromJson(
    (await _api.get('/manager/company') as Map).cast<String, dynamic>(),
  );

  Future<Entreprise> update(Map<String, dynamic> data) async =>
      Entreprise.fromJson(
        (await _api.post('/manager/company', data) as Map)
            .cast<String, dynamic>(),
      );

  Future<AbonnementEntreprise> abonnement() async =>
      AbonnementEntreprise.fromJson(
        (await _api.get('/manager/subscription') as Map)
            .cast<String, dynamic>(),
      );

  Future<Offres> offres() async => Offres.fromJson(
    (await _api.get('/subscription-offers') as Map).cast<String, dynamic>(),
  );

  Future<VersionInfo> version() async => VersionInfo.fromJson(
    (await _api.get('/app-version') as Map).cast<String, dynamic>(),
  );
}
