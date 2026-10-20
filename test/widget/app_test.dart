import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_cahier_bi/core/api/api_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';

Future<void> seConnecter(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Numéro WhatsApp'),
    '77 222 33 44',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Mot de passe'),
    'Secret2026',
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('numéro invalide : la connexion n\'est pas envoyée', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(testApp(auth: auth));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Numéro WhatsApp'),
      '12',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mot de passe'),
      'x',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Numéro sénégalais invalide'), findsOneWidget);
    expect(auth.logins, isEmpty);
  });

  testWidgets(
    'le propriétaire arrive sur l\'accueil et voit l\'onglet Gérants',
    (tester) async {
      await tester.pumpWidget(testApp(auth: FakeAuthRepository()));
      await tester.pumpAndSettle();
      await seConnecter(tester);

      expect(find.text('Total à récupérer'), findsOneWidget);
      expect(find.text('42 000 FCFA'), findsOneWidget);
      expect(find.text('Gérants'), findsOneWidget);
      // Forfait gratuit offert à l'inscription
      expect(find.text('Forfait Gratuit offert'), findsOneWidget);
    },
  );

  testWidgets(
    'le gérant ne voit ni l\'onglet Gérants ni le bandeau d\'abonnement',
    (tester) async {
      await tester.pumpWidget(
        testApp(auth: FakeAuthRepository(role: 'GERANT')),
      );
      await tester.pumpAndSettle();
      await seConnecter(tester);

      expect(find.text('Total à récupérer'), findsOneWidget);
      expect(find.text('Gérants'), findsNothing);
      expect(find.text('Forfait Gratuit offert'), findsNothing);
      // Fixé sur sa boutique
      expect(find.text('Diop Médina'), findsWidgets);
    },
  );

  testWidgets(
    'abonnement expiré à la connexion : page dédiée avec les offres',
    (tester) async {
      final auth = FakeAuthRepository(
        loginError: const ApiException(
          'Votre abonnement a expiré le 01/10/2026.',
          code: 'SUBSCRIPTION_EXPIRED',
          status: 403,
        ),
      );
      await tester.pumpWidget(testApp(auth: auth));
      await tester.pumpAndSettle();
      await seConnecter(tester);

      expect(find.text('Abonnement expiré'), findsOneWidget);
      expect(
        find.text('Votre abonnement a expiré le 01/10/2026.'),
        findsOneWidget,
      );
      expect(find.text('Boutique'), findsOneWidget);

      await tester.tap(find.text('Retour à la connexion'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Se connecter'), findsOneWidget);
    },
  );

  testWidgets('déconnexion après confirmation', (tester) async {
    await tester.pumpWidget(testApp(auth: FakeAuthRepository()));
    await tester.pumpAndSettle();
    await seConnecter(tester);

    await tester.tap(find.text('Compte'));
    await tester.pumpAndSettle();
    // En bas de la page Compte : défiler jusqu'au bouton
    await tester.ensureVisible(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    expect(find.text('Se déconnecter ?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Se déconnecter'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Se connecter'), findsOneWidget);
  });

  testWidgets('recherche par date sur l\'accueil', (tester) async {
    final dashboard = FakeDashboardRepository();
    await tester.pumpWidget(
      testApp(auth: FakeAuthRepository(), dashboard: dashboard),
    );
    await tester.pumpAndSettle();
    await seConnecter(tester);

    // Section sous les indicateurs : défiler jusqu'à elle
    await tester.scrollUntilVisible(
      find.text('7 derniers jours'),
      200,
      scrollable:
          find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Recherche par date'), findsOneWidget);
    // Aucune recherche tant qu'aucune date n'est choisie
    expect(dashboard.periodes, isEmpty);

    await tester.tap(find.text('7 derniers jours'));
    await tester.pumpAndSettle();

    final today = DateTime.now();
    final (du, au) = dashboard.periodes.single;
    expect(au, DateTime(today.year, today.month, today.day));
    expect(au!.difference(du).inDays, 6);
    expect(find.text('17 500 FCFA'), findsOneWidget);
    expect(find.text('3 versement(s)'), findsOneWidget);
    expect(find.text('23 000 FCFA'), findsOneWidget);
    expect(find.text('4 dette(s)'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Effacer la recherche'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Effacer la recherche'));
    await tester.pumpAndSettle();
    expect(find.text('17 500 FCFA'), findsNothing);
  });

  testWidgets('mot de passe oublié : le numéro doit correspondre à un compte', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(testApp(auth: auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mot de passe oublié ?'));
    await tester.pumpAndSettle();

    // Numéro sans compte : aucun code, message clair et inscription proposée
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Numéro WhatsApp du compte'),
      '78 000 00 00',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Recevoir le code'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Aucun compte n\'est associé'), findsOneWidget);
    expect(find.text('Créer mon compte'), findsOneWidget);
    expect(find.text('Code de vérification'), findsNothing);

    // Numéro inscrit : étape du code
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Numéro WhatsApp du compte'),
      '77 222 33 44',
    );
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Recevoir le code'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Recevoir le code'));
    await tester.pumpAndSettle();
    expect(auth.forgotRequests, hasLength(2));
    expect(find.text('Code de vérification'), findsOneWidget);
    expect(find.textContaining('Compte trouvé'), findsOneWidget);
  });
}
