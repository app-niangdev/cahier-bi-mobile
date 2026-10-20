import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_cahier_bi/core/domain/enums.dart';
import 'package:mobile_cahier_bi/features/auth/domain/auth_step.dart';
import 'package:mobile_cahier_bi/features/boutiques/domain/boutique.dart';
import 'package:mobile_cahier_bi/core/utils/format.dart';
import 'package:mobile_cahier_bi/features/dashboard/domain/dashboard.dart';
import 'package:mobile_cahier_bi/features/dashboard/presentation/recherche_date.dart';
import 'package:mobile_cahier_bi/features/dettes/domain/dette.dart';
import 'package:mobile_cahier_bi/features/entreprise/domain/entreprise.dart';
import 'package:mobile_cahier_bi/features/gerants/data/gerant_repository.dart';

void main() {
  test('étapes de connexion', () {
    final auth = AuthStep.fromJson({
      'step': 'authenticated',
      'access_token': 'a',
      'refresh_token': 'r',
      'user': {
        'id': 3,
        'first_name': 'Awa',
        'last_name': 'Sarr',
        'full_name': 'Awa Sarr',
        'role': 'GERANT',
        'phone': '772223344',
        'tenant_id': 1,
        'tenant': {'name': 'Boutique Diop'},
        'boutique': {
          'id': 5,
          'nom': 'Diop Médina',
          'ville': 'Dakar',
          'quartier': 'Médina',
        },
        'subscription': {
          'state': 'active',
          'plan': 'Gratuit',
          'ends_at': '2026-11-14',
          'days_left': 30,
        },
      },
    });
    expect(auth, isA<Authenticated>());
    final profil = (auth as Authenticated).profil;
    expect(profil.isGerant, isTrue);
    expect(profil.boutique?.id, 5);
    expect(profil.nomAffiche, 'Awa Sarr');
    expect(profil.subscription?.estOffert, isTrue);

    final otp = AuthStep.fromJson({
      'step': 'otp_required',
      'purpose': 'first_login',
      'challenge_token': 'x' * 64,
      'phone_masked': '77 *** ** 44',
    });
    expect((otp as OtpRequired).challenge.purpose, OtpPurpose.firstLogin);

    final password = AuthStep.fromJson({
      'step': 'set_password',
      'purpose': 'password_reset',
      'reset_token': 'y' * 64,
    });
    expect((password as SetPasswordRequired).purpose, OtpPurpose.passwordReset);
  });

  test('dette avec ses paiements (montants décimaux ou entiers)', () {
    final d = Dette.fromJson({
      'id': 9,
      'reference': 'DET-0009',
      'client_id': 2,
      'boutique_id': 1,
      'montant': 15000.0,
      'montant_paye': 5000,
      'montant_restant': '10000.00',
      'date_creation': '2026-10-01',
      'date_echeance': null,
      'statut': 'en_retard',
      'client': {'id': 2, 'nom': 'Fatou Ndiaye', 'telephone': '771112233'},
      'paiements': [
        {
          'id': 1,
          'versement': 'uuid',
          'montant': 5000,
          'date_paiement': '2026-10-05',
          'methode': 'wave',
          'reference': null,
        },
      ],
    });
    expect(d.montantRestant, 10000);
    expect(d.statut, StatutDette.enRetard);
    expect(d.statut.estOuverte, isTrue);
    expect(d.client?.nom, 'Fatou Ndiaye');
    expect(d.paiements.single.methode, MethodePaiement.wave);
  });

  test('tableau de bord', () {
    final d = Dashboard.fromJson({
      'subscription': {'state': 'expiring', 'plan': 'Boutique', 'days_left': 3},
      'total_a_recuperer': 42000,
      'dettes': {
        'en_attente': {'count': 2, 'total': 12000},
        'a_aujourdhui': {'count': 0, 'total': 0},
        'en_retard': {'count': 1, 'total': 30000},
      },
      'encaisse_aujourdhui': 0,
      'encaisse_mois': 15000.5,
      'clients_count': 8,
      'clients_debiteurs_count': 3,
      'a_relancer': [
        {
          'id': 4,
          'reference': 'DET-4',
          'client': {'id': 2, 'nom': 'Fatou', 'telephone': null},
          'montant_restant': 30000,
          'date_echeance': '2026-10-01',
          'statut': 'en_retard',
        },
      ],
    });
    expect(d.subscription.state, EtatAbonnement.expiring);
    expect(d.enRetard.total, 30000);
    expect(d.aRelancer.single.clientNom, 'Fatou');
  });

  test('quota de gérants', () {
    expect(const GerantsPlaces(max: 1, utilises: 1).complet, isTrue);
    expect(const GerantsPlaces(max: 3, utilises: 2).libelle, '2 / 3');
    expect(const GerantsPlaces(max: null, utilises: 7).complet, isFalse);
    expect(const GerantsPlaces(max: null, utilises: 7).libelle, '7 / illimité');
  });

  test('versions de l\'application', () {
    expect(compareVersions('1.0.0', '1.0.1'), isNegative);
    expect(compareVersions('1.2.0', '1.10.0'), isNegative);
    expect(compareVersions('2.0', '1.9.9'), isPositive);
    expect(compareVersions('1.0.0', '1.0.0'), 0);
  });

  test('mot de passe provisoire : 8 caractères minimum', () {
    expect(motDePasseProvisoire(), matches(RegExp(r'^CB-\d{6}$')));
  });

  test('activité sur une période', () {
    final d = Dashboard.fromJson({
      'subscription': {'state': 'active'},
      'periode': {
        'du': '2026-10-01',
        'au': '2026-10-15',
        'encaisse': '12500.00',
        'versements_count': 4,
        'dettes_count': 2,
        'dettes_montant': 30000,
      },
    });
    expect(d.periode!.du, DateTime(2026, 10, 1));
    expect(d.periode!.au, DateTime(2026, 10, 15));
    expect(d.periode!.encaisse, 12500);
    expect(d.periode!.versementsCount, 4);
    expect(d.periode!.dettesMontant, 30000);
    expect(
      Dashboard.fromJson({
        'subscription': {'state': 'active'},
      }).periode,
      isNull,
    );
  });

  test('raccourcis de la recherche par date', () async {
    await initializeDateFormatting('fr_FR');
    final today = DateUtils.dateOnly(DateTime.now());
    expect(Raccourci.aujourdhui.periode.start, today);
    expect(Raccourci.hier.periode.end, today.subtract(const Duration(days: 1)));
    expect(Raccourci.septJours.periode.duration.inDays, 6);
    expect(Raccourci.ceMois.periode.start, DateTime(today.year, today.month));
    expect(Raccourci.ceMois.periode.end, today);
    expect(
      libellePeriode(DateTimeRange(start: today, end: today)),
      dateLongue(today),
    );
    expect(
      libellePeriode(
        DateTimeRange(
          start: DateTime(2026, 10, 1),
          end: DateTime(2026, 10, 15),
        ),
      ),
      'Du 1 oct. 2026 au 15 oct. 2026',
    );
  });
}
