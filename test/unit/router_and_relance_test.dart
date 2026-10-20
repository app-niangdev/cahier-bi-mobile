import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_cahier_bi/app/router.dart';
import 'package:mobile_cahier_bi/core/api/api_exception.dart';
import 'package:mobile_cahier_bi/core/domain/enums.dart';
import 'package:mobile_cahier_bi/features/auth/domain/profil.dart';
import 'package:mobile_cahier_bi/features/auth/presentation/session_controller.dart';

SessionState connecte(Role role) => SessionState(
  SessionStatus.authenticated,
  profil: Profil(
    id: 1,
    firstName: 'A',
    lastName: 'B',
    fullName: 'A B',
    role: role,
  ),
);

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  group('redirections', () {
    test('hors session : seules les pages publiques', () {
      const s = SessionState(SessionStatus.unauthenticated);
      expect(redirectFor(s, '/accueil'), '/connexion');
      expect(redirectFor(s, '/inscription'), isNull);
      expect(redirectFor(s, '/mot-de-passe-oublie'), isNull);
    });

    test('démarrage puis accueil une fois connecté', () {
      expect(
        redirectFor(const SessionState(SessionStatus.unknown), '/clients'),
        '/demarrage',
      );
      expect(
        redirectFor(connecte(Role.proprietaire), '/connexion'),
        '/accueil',
      );
      expect(redirectFor(connecte(Role.proprietaire), '/clients/3'), isNull);
    });

    test('le gérant ne peut pas ouvrir les pages du propriétaire', () {
      final gerant = connecte(Role.gerant);
      expect(redirectFor(gerant, '/gerants'), '/accueil');
      expect(redirectFor(gerant, '/compte/entreprise'), '/accueil');
      expect(redirectFor(gerant, '/compte/abonnement'), '/accueil');
      expect(redirectFor(gerant, '/compte/profil'), isNull);
      expect(redirectFor(connecte(Role.proprietaire), '/gerants'), isNull);
    });

    test('abonnement expiré : page dédiée', () {
      const s = SessionState(
        SessionStatus.blocked,
        error: ApiException('Expiré', code: 'SUBSCRIPTION_EXPIRED'),
      );
      expect(redirectFor(s, '/accueil'), '/bloque');
      expect(redirectFor(s, '/bloque'), isNull);
    });
  });
}
