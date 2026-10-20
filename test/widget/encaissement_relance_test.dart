import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_cahier_bi/app/providers.dart';
import 'package:mobile_cahier_bi/app/theme.dart';
import 'package:mobile_cahier_bi/core/api/api_client.dart';
import 'package:mobile_cahier_bi/core/api/api_exception.dart';
import 'package:mobile_cahier_bi/features/clients/data/client_repository.dart';
import 'package:mobile_cahier_bi/features/clients/domain/client.dart';
import 'package:mobile_cahier_bi/features/dettes/domain/dette.dart';
import 'package:mobile_cahier_bi/features/paiements/encaisser_client.dart';
import 'package:mobile_cahier_bi/features/rappels/relance.dart';

import '../helpers/fakes.dart';

/// Client Modou Diop : deux achats à crédit (3 000 et 1 700), dette totale 4 700.
class FakeClients extends ClientRepository {
  FakeClients({this.rappelError})
    : super(
        ApiClient(baseUrl: 'http://test.invalid', tokens: MemoryTokenStore()),
      );

  final ApiException? rappelError;
  final paiements = <PaiementPayload>[];
  int rappels = 0;

  @override
  Future<Client> get(int id) async => Client.fromJson({
    'id': id,
    'boutique_id': 1,
    'nom': 'Modou Diop',
    'telephone': '775554433',
    'total_du': 4700,
  });

  @override
  Future<void> payer(int id, PaiementPayload paiement) async =>
      paiements.add(paiement);

  @override
  Future<({String message, String telephone, double totalDu})> apercuRappel(
    int id,
  ) async => (
    message:
        'Bonjour Modou Diop, j\'espère que vous allez bien. Petit rappel amical : il reste 4 700 FCFA à régler chez Diop Médina. Merci beaucoup !',
    telephone: '775554433',
    totalDu: 4700.0,
  );

  @override
  Future<void> envoyerRappel(int id) async {
    if (rappelError != null) throw rappelError!;
    rappels++;
  }
}

Widget harness(
  FakeClients clients,
  void Function(BuildContext, WidgetRef) onTap,
) => ProviderScope(
  overrides: [clientRepositoryProvider.overrideWithValue(clients)],
  child: MaterialApp(
    theme: buildTheme(Brightness.light),
    home: Scaffold(
      body: Consumer(
        builder:
            (context, ref, _) => Center(
              child: TextButton(
                onPressed: () => onTap(context, ref),
                child: const Text('Ouvrir'),
              ),
            ),
      ),
    ),
  ),
);

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  testWidgets('versement global : 4 000 sur une dette totale de 4 700', (
    tester,
  ) async {
    final clients = FakeClients();
    await tester.pumpWidget(
      harness(
        clients,
        (context, ref) =>
            encaisserClient(context, ref, clientId: 1, clientNom: 'Modou Diop'),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Dette totale : 4 700 FCFA'), findsOneWidget);
    // Pas de détail par achat
    expect(find.text('Répartition'), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, '4000');
    await tester.pumpAndSettle();
    expect(find.text('Reste à payer'), findsOneWidget);
    expect(find.text('700 FCFA'), findsOneWidget);

    await tester.ensureVisible(find.text('Encaisser 4 000 FCFA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Encaisser 4 000 FCFA'));
    await tester.pumpAndSettle();

    // Un seul paiement enregistré, du montant donné par le client
    expect(clients.paiements, hasLength(1));
    expect(clients.paiements.single.montant, 4000);
    expect(
      find.text('Versement de 4 000 FCFA enregistré. Reste 700 FCFA.'),
      findsOneWidget,
    );
  });

  testWidgets('relance : message poli envoyé sur WhatsApp par le serveur', (
    tester,
  ) async {
    final clients = FakeClients();
    await tester.pumpWidget(
      harness(
        clients,
        (context, _) =>
            relancerClient(context, clientId: 1, clientNom: 'Modou Diop'),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Petit rappel amical'), findsOneWidget);
    // Ni choix du canal (SMS) ni choix du ton
    expect(find.text('SMS'), findsNothing);
    expect(find.text('Ferme'), findsNothing);

    await tester.tap(find.text('Envoyer sur WhatsApp'));
    await tester.pumpAndSettle();
    expect(clients.rappels, 1);
    expect(
      find.text('Rappel envoyé à Modou Diop sur WhatsApp.'),
      findsOneWidget,
    );
  });

  testWidgets('relance refusée par le serveur : message affiché', (
    tester,
  ) async {
    final clients = FakeClients(
      rappelError: const ApiException(
        'Le 77 555 44 33 n\'a pas de compte WhatsApp.',
        code: 'NO_WHATSAPP_ACCOUNT',
        status: 422,
      ),
    );
    await tester.pumpWidget(
      harness(
        clients,
        (context, _) =>
            relancerClient(context, clientId: 1, clientNom: 'Modou Diop'),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Envoyer sur WhatsApp'));
    await tester.pumpAndSettle();

    expect(
      find.text('Le 77 555 44 33 n\'a pas de compte WhatsApp.'),
      findsOneWidget,
    );
    expect(clients.rappels, 0);
  });
}
