import '../../../core/api/api_client.dart';
import '../domain/boutique.dart';

class BoutiqueRepository {
  BoutiqueRepository(this._api);
  final ApiClient _api;

  /// Toutes celles du propriétaire, celle du gérant.
  Future<List<Boutique>> list() async =>
      (await _api.get('/manager/boutiques') as List)
          .map((e) => Boutique.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
}
