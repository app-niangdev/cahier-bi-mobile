import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/config.dart';
import '../core/storage/token_store.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/boutiques/data/boutique_repository.dart';
import '../features/clients/data/client_repository.dart';
import '../features/dashboard/data/dashboard_repository.dart';
import '../features/dettes/data/dette_repository.dart';
import '../features/entreprise/data/entreprise_repository.dart';
import '../features/gerants/data/gerant_repository.dart';

/// Point unique de branchement : client HTTP et repositories.
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(baseUrl: apiUrl, tokens: ref.watch(tokenStoreProvider)),
);

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);
final boutiqueRepositoryProvider = Provider(
  (ref) => BoutiqueRepository(ref.watch(apiClientProvider)),
);
final dashboardRepositoryProvider = Provider(
  (ref) => DashboardRepository(ref.watch(apiClientProvider)),
);
final clientRepositoryProvider = Provider(
  (ref) => ClientRepository(ref.watch(apiClientProvider)),
);
final detteRepositoryProvider = Provider(
  (ref) => DetteRepository(ref.watch(apiClientProvider)),
);
final gerantRepositoryProvider = Provider(
  (ref) => GerantRepository(ref.watch(apiClientProvider)),
);
final entrepriseRepositoryProvider = Provider(
  (ref) => EntrepriseRepository(ref.watch(apiClientProvider)),
);

/// Incrémenté après chaque modification : les écrans qui le surveillent se rechargent.
final dataVersionProvider = NotifierProvider<DataVersion, int>(DataVersion.new);

class DataVersion extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}
