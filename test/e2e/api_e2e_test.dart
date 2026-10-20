// Parcours complet contre une API Laravel locale (WAHA non configuré : codes OTP écrits dans le journal).
//
//   flutter test test/e2e --dart-define=API_URL=http://127.0.0.1:8000/api \
//     --dart-define=LARAVEL_LOG=/chemin/backend/storage/logs/laravel.log
//
// Ignoré sans API_URL.
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_cahier_bi/core/api/api_client.dart';
import 'package:mobile_cahier_bi/core/api/api_exception.dart';
import 'package:mobile_cahier_bi/core/domain/enums.dart';
import 'package:mobile_cahier_bi/features/auth/data/auth_repository.dart';
import 'package:mobile_cahier_bi/features/auth/domain/auth_step.dart';
import 'package:mobile_cahier_bi/features/boutiques/data/boutique_repository.dart';
import 'package:mobile_cahier_bi/features/clients/data/client_repository.dart';
import 'package:mobile_cahier_bi/features/clients/domain/client.dart';
import 'package:mobile_cahier_bi/features/dashboard/data/dashboard_repository.dart';
import 'package:mobile_cahier_bi/features/dettes/data/dette_repository.dart';
import 'package:mobile_cahier_bi/features/dettes/domain/dette.dart';
import 'package:mobile_cahier_bi/features/entreprise/data/entreprise_repository.dart';
import 'package:mobile_cahier_bi/features/gerants/data/gerant_repository.dart';
import 'package:mobile_cahier_bi/features/gerants/domain/gerant.dart';

import '../helpers/fakes.dart';

const apiUrl = String.fromEnvironment('API_URL');
const logPath = String.fromEnvironment('LARAVEL_LOG');

/// Dernier code OTP écrit dans le journal Laravel pour cet utilisateur.
String lastOtp() {
  final matches = RegExp(
    r'"code":"(\d{6})"',
  ).allMatches(File(logPath).readAsStringSync());
  return matches.last.group(1)!;
}

String randomPhone() => '77${(1000000 + Random().nextInt(8999999))}';

void main() {
  final skip = apiUrl.isEmpty ? 'API_URL non défini' : null;

  test(
    'propriétaire inscrit : entreprise, boutique, forfait Gratuit, dettes, paiements et gérant',
    () async {
      final ownerTokens = MemoryTokenStore();
      final owner = ApiClient(baseUrl: apiUrl, tokens: ownerTokens);
      final auth = AuthRepository(owner);
      final phone = randomPhone();

      // 1. Inscription puis code WhatsApp : session ouverte
      final challenge = await auth.register(
        RegisterPayload(
          firstName: 'Moussa',
          lastName: 'Diop',
          companyName: 'Alimentation Diop $phone',
          quartier: 'Médina',
          ville: 'Dakar',
          phone: phone,
          password: 'Secret2026',
        ),
      );
      expect(challenge.purpose, OtpPurpose.signup);
      final step =
          await auth.verifyOtp(challenge.challengeToken, lastOtp())
              as Authenticated;
      await ownerTokens.save(step.accessToken, step.refreshToken);
      expect(step.profil.isProprietaire, isTrue);
      expect(step.profil.subscription?.plan, 'Gratuit');
      expect(step.profil.subscription?.state, EtatAbonnement.active);

      // 2. Une boutique, au nom du commerce
      final boutiques = await BoutiqueRepository(owner).list();
      expect(boutiques, hasLength(1));
      expect(boutiques.single.nom, 'Alimentation Diop $phone');
      expect(boutiques.single.lieu, 'Médina, Dakar');
      expect(boutiques.single.gerantsPlaces?.max, 1);

      // 3. Client, deux dettes, paiement sur une dette puis versement global
      final clients = ClientRepository(owner);
      final dettes = DetteRepository(owner);
      final client = await clients.create(
        ClientPayload(
          nom: 'Fatou Ndiaye',
          telephone: '76 111 22 33',
          boutiqueId: boutiques.single.id,
        ),
      );
      final d1 = await dettes.create(
        clientId: client.id,
        montant: 10000,
        dateCreation: DateTime.now().subtract(const Duration(days: 3)),
      );
      await dettes.create(clientId: client.id, montant: 5000);
      await dettes.payer(
        d1.id,
        const PaiementPayload(
          montant: 4000,
          methode: MethodePaiement.wave,
          reference: 'W-1',
        ),
      );
      await clients.payer(
        client.id,
        const PaiementPayload(montant: 8000, methode: MethodePaiement.especes),
      );

      final fiche = await clients.get(client.id);
      expect(fiche.totalDu, 3000);
      expect((await dettes.get(d1.id)).statut, StatutDette.payee);
      final versements = await clients.versements(client.id);
      expect(versements, hasLength(2));
      expect(versements.first.repartition, hasLength(2));

      // Annulation du versement global (propriétaire)
      await dettes.annulerVersement(versements.first.versement);
      expect((await clients.get(client.id)).totalDu, 11000);

      final dashboard = await DashboardRepository(owner).load();
      expect(dashboard.totalARecuperer, 11000);
      expect(dashboard.clientsCount, 1);

      // 4. Entreprise et abonnement
      final entreprise = EntrepriseRepository(owner);
      expect((await entreprise.abonnement()).maxGerantsParBoutique, 1);
      final updated = await entreprise.update({
        'name': 'Alimentation Diop $phone',
        'trade': 'Alimentation',
      });
      expect(updated.trade, 'Alimentation');

      // 5. Gérant : créé par le propriétaire, quota de 1 atteint ensuite
      final gerants = GerantRepository(owner);
      final gerantPhone = randomPhone();
      final (gerant, password) = await gerants.create(
        boutiques.single.id,
        GerantPayload(
          firstName: 'Awa',
          lastName: 'Sarr',
          phoneOne: gerantPhone,
        ),
      );
      expect(gerant.mustChangePassword, isTrue);
      await expectLater(
        gerants.create(
          boutiques.single.id,
          GerantPayload(
            firstName: 'Ibra',
            lastName: 'Fall',
            phoneOne: randomPhone(),
          ),
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'GERANTS_LIMIT_REACHED',
          ),
        ),
      );

      // 6. Première connexion du gérant : code WhatsApp puis son mot de passe
      final gerantTokens = MemoryTokenStore();
      final gerantApi = ApiClient(baseUrl: apiUrl, tokens: gerantTokens);
      final gerantAuth = AuthRepository(gerantApi);
      final otp = await gerantAuth.login(gerantPhone, password) as OtpRequired;
      expect(otp.challenge.purpose, OtpPurpose.firstLogin);
      final reset =
          await gerantAuth.verifyOtp(otp.challenge.challengeToken, lastOtp())
              as SetPasswordRequired;
      final session =
          await gerantAuth.setPassword(reset.resetToken, 'MonCode2026')
              as Authenticated;
      await gerantTokens.save(session.accessToken, session.refreshToken);
      expect(session.profil.isGerant, isTrue);
      expect(session.profil.boutique?.id, boutiques.single.id);

      // Ensuite : connexion directe, dans sa boutique, sans accès aux pages du propriétaire
      expect(
        await gerantAuth.login(gerantPhone, 'MonCode2026'),
        isA<Authenticated>(),
      );
      final sesBoutiques = await BoutiqueRepository(gerantApi).list();
      expect(sesBoutiques.map((b) => b.id), [boutiques.single.id]);
      expect(
        (await ClientRepository(gerantApi).list()).items.single.nom,
        'Fatou Ndiaye',
      );
      await expectLater(
        GerantRepository(gerantApi).list(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)),
      );
      await expectLater(
        DetteRepository(gerantApi).annuler(d1.id),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)),
      );
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
