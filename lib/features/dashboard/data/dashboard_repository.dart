import '../../../core/api/api_client.dart';
import '../../../core/utils/format.dart';
import '../domain/dashboard.dart';

class DashboardRepository {
  DashboardRepository(this._api);
  final ApiClient _api;

  /// `boutiqueId` null : toutes les boutiques du propriétaire.
  /// Avec [du] (et [au], facultatif) : activité sur la période (`Dashboard.periode`).
  Future<Dashboard> load({int? boutiqueId, DateTime? du, DateTime? au}) async =>
      Dashboard.fromJson(
        (await _api.get(
                  '/manager/dashboard',
                  query: {
                    'boutique_id': boutiqueId,
                    'du': du == null ? null : isoDate(du),
                    'au': au == null ? null : isoDate(au),
                  },
                )
                as Map)
            .cast<String, dynamic>(),
      );
}
