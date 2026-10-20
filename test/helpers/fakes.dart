import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_cahier_bi/app/app.dart';
import 'package:mobile_cahier_bi/app/providers.dart';
import 'package:mobile_cahier_bi/core/api/api_client.dart';
import 'package:mobile_cahier_bi/core/api/api_exception.dart';
import 'package:mobile_cahier_bi/core/storage/token_store.dart';
import 'package:mobile_cahier_bi/features/auth/data/auth_repository.dart';
import 'package:mobile_cahier_bi/features/auth/domain/auth_step.dart';
import 'package:mobile_cahier_bi/features/auth/domain/profil.dart';
import 'package:mobile_cahier_bi/features/boutiques/data/boutique_repository.dart';
import 'package:mobile_cahier_bi/features/boutiques/domain/boutique.dart';
import 'package:mobile_cahier_bi/core/utils/format.dart';
import 'package:mobile_cahier_bi/features/dashboard/data/dashboard_repository.dart';
import 'package:mobile_cahier_bi/features/dashboard/domain/dashboard.dart';
import 'package:mobile_cahier_bi/features/entreprise/data/entreprise_repository.dart';
import 'package:mobile_cahier_bi/features/entreprise/domain/entreprise.dart';

/// Jetons en mémoire (pas de stockage sécurisé dans les tests).
class MemoryTokenStore extends TokenStore {
  String? _a;
  String? _r;

  @override
  String? get accessToken => _a;
  @override
  String? get refreshToken => _r;
  @override
  Future<void> load() async {}
  @override
  Future<void> save(String access, String refresh) async {
    _a = access;
    _r = refresh;
  }

  @override
  Future<void> clear() async => _a = _r = null;
}

final _api = ApiClient(
  baseUrl: 'http://test.invalid/api',
  tokens: MemoryTokenStore(),
);

Map<String, dynamic> profilJson({required String role, int? boutiqueId}) => {
  'id': 7,
  'first_name': 'Awa',
  'last_name': 'Sarr',
  'full_name': 'Awa Sarr',
  'role': role,
  'phone': '772223344',
  'tenant_id': 1,
  'tenant': {'name': 'Alimentation Diop'},
  if (boutiqueId != null) 'boutique': {'id': boutiqueId, 'nom': 'Diop Médina'},
  'subscription': {
    'state': 'active',
    'plan': 'Gratuit',
    'ends_at': '2026-11-14',
    'days_left': 30,
  },
};

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({this.role = 'PROPRIETAIRE', this.loginError})
    : super(_api);

  final String role;
  final ApiException? loginError;
  final logins = <String>[];

  @override
  Future<AuthStep> login(String phone, String password) async {
    logins.add(phone);
    if (loginError != null) throw loginError!;
    return AuthStep.fromJson({
      'step': 'authenticated',
      'access_token': 'access',
      'refresh_token': 'refresh',
      'user': profilJson(role: role, boutiqueId: role == 'GERANT' ? 1 : null),
    });
  }

  @override
  Future<Profil> me() async => Profil.fromJson(
    profilJson(role: role, boutiqueId: role == 'GERANT' ? 1 : null),
  );

  @override
  Future<void> logout() async {}

  /// Seul le 77 222 33 44 a un compte (comme le serveur, qui vérifie avant d'envoyer le code).
  final forgotRequests = <String>[];

  @override
  Future<OtpChallenge> forgotPassword(String phone) async {
    forgotRequests.add(phone);
    if (nationalNumber(phone) != '772223344') {
      throw ApiException(
        'Aucun compte n\'est associé au ${formatTelephone(phone).replaceFirst('+221 ', '')}. Vérifiez le numéro ou créez votre compte.',
        code: 'PHONE_NOT_FOUND',
        status: 404,
      );
    }
    return OtpChallenge.fromJson({
      'challenge_token': 'tok',
      'purpose': 'password_reset',
      'phone_masked': '77 *** ** 44',
    });
  }
}

class FakeBoutiqueRepository extends BoutiqueRepository {
  FakeBoutiqueRepository() : super(_api);

  @override
  Future<List<Boutique>> list() async => [
    Boutique.fromJson({
      'id': 1,
      'nom': 'Diop Médina',
      'statut': 'actif',
      'quartier': 'Médina',
      'ville': 'Dakar',
    }),
  ];
}

class FakeDashboardRepository extends DashboardRepository {
  FakeDashboardRepository() : super(_api);

  /// Périodes demandées (recherche par date).
  final periodes = <(DateTime, DateTime?)>[];

  @override
  Future<Dashboard> load({int? boutiqueId, DateTime? du, DateTime? au}) async {
    if (du != null) periodes.add((du, au));
    return Dashboard.fromJson({
      'subscription': {
        'state': 'active',
        'plan': 'Gratuit',
        'days_left': 30,
        'ends_at': '2026-11-14',
      },
      'total_a_recuperer': 42000,
      'dettes': {
        'en_attente': {'count': 2, 'total': 12000},
        'a_aujourdhui': {'count': 0, 'total': 0},
        'en_retard': {'count': 1, 'total': 30000},
      },
      'encaisse_aujourdhui': 5000,
      'encaisse_mois': 15000,
      'clients_count': 8,
      'clients_debiteurs_count': 3,
      'a_relancer': [],
      if (du != null)
        'periode': {
          'du': isoDate(du),
          'au': isoDate(au ?? du),
          'encaisse': 17500,
          'versements_count': 3,
          'dettes_count': 4,
          'dettes_montant': 23000,
        },
    });
  }
}

class FakeEntrepriseRepository extends EntrepriseRepository {
  FakeEntrepriseRepository() : super(_api);

  @override
  Future<VersionInfo> version() async =>
      const VersionInfo(latest: '1.0.0', min: '1.0.0');

  @override
  Future<Offres> offres() async => Offres.fromJson({
    'plans': [
      {
        'id': 1,
        'name': 'Boutique',
        'duration_months': 1,
        'price': 3000,
        'max_gerants_par_boutique': 3,
      },
    ],
    'contact': {
      'name': 'Administrateur',
      'whatsapp': '770000000',
      'payment_methods': 'Wave, Orange Money',
    },
  });
}

/// Application complète avec les dépôts factices.
Widget testApp({
  required FakeAuthRepository auth,
  MemoryTokenStore? tokens,
  FakeDashboardRepository? dashboard,
}) => ProviderScope(
  retry: (_, __) => null,
  overrides: [
    tokenStoreProvider.overrideWithValue(tokens ?? MemoryTokenStore()),
    authRepositoryProvider.overrideWithValue(auth),
    boutiqueRepositoryProvider.overrideWithValue(FakeBoutiqueRepository()),
    dashboardRepositoryProvider.overrideWithValue(
      dashboard ?? FakeDashboardRepository(),
    ),
    entrepriseRepositoryProvider.overrideWithValue(FakeEntrepriseRepository()),
  ],
  child: const CahierBiApp(),
);
