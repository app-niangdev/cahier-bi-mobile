import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // URLs sans « # » sur le Web (le serveur renvoie toutes les routes vers index.html)
  usePathUrlStrategy();
  await initializeDateFormatting('fr_FR');
  runApp(
    ProviderScope(
      // Pas de nouvel essai automatique : les erreurs de l'API sont affichées avec « Réessayer »
      retry: (retryCount, error) => null,
      child: const CahierBiApp(),
    ),
  );
}
